{
 *****************************************************************************
  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************

 Author: Boban Spasic

 Unit description:
 Extract voice data from various files
}
unit untExtract;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, untUtils, untDX7Voice, untDX7Bank, untDX7IISupplement, untDX7IISupplBank, untDX7IIPerformance, untDX7IIPerformanceBank, untTX802Performance, untTX802PerformanceBank;

procedure ExtractDispatch(aName: string; aVerbose: boolean);
procedure ExtractSoundDiver(aName: string; aVerbose: boolean);

implementation

procedure ExtractDispatch(aName: string; aVerbose: boolean);
begin
  if LowerCase(ExtractFileExt(aName)) = '.lib' then
  begin
    WriteLn('Trying to extract data from Sound Diver 3 library');
    ExtractSoundDiver(aName, aVerbose);
  end;
end;

procedure ExtractSoundDiver(aName: string; aVerbose: boolean);
const
  aIFFForm: array [0..3] of byte = ($4D, $52, $4F, $46);
  aIFFLent: array [0..3] of byte = ($54, $4E, $45, $4C);
  aIFFVMEM: array [0..2] of byte = ($03, $81, $19);
  aIFFPMEM: array [0..1] of byte = ($03, $1F);
  aIFFTX802: array [0..1] of byte = ($03, $40);
  //aIFFEditBuff: array [0..1] of byte = ($06, $01);
  aIFFInternal: array [0..1] of byte = ($06, $04);
var
  ms: TMemoryStream;
  msO: TMemoryStream;
  msAll: TMemoryStream;
  dxVMEM: TDX7_VMEM_Params;
  dxAMEM: TDX7II_AMEM_Params;
  dxTX802P: TTX802_PMEM_Params;
  dxPCED: TDX7II_PCED_Params;
  dxv: TDX7VoiceContainer;
  dxvb: TDX7BankContainer;
  dxs: TDX7IISupplementContainer;
  dxsb: TDX7IISupplBankContainer;
  dxt: TTX802PerformanceContainer;
  dxtb: TTX802PerfBankContainer;
  dxp: TDX7IIPerformanceContainer;
  dxpb: TDX7IIPerfBankContainer;

  i, j, v, p, vr, pr: integer; //vr, pr - voice/performance repetitions if more than one bank in file
  iNameLen: byte;
  arName: array of byte;
  sName: string;
  chunkSize: integer;
  chunkDataID: array of byte;
  chunkTargetID: array [0..1] of byte;
begin
  ms := TMemoryStream.Create;
  ms.LoadFromFile(aName);
  msAll := TMemoryStream.Create;

  if (PosBytes(aIFFForm, ms, 0) <> -1) and (PosBytes(aIFFLent, ms, 0) <> -1) then
  begin
    dxv := TDX7VoiceContainer.Create;
    dxvb := TDX7BankContainer.Create;
    dxvb.InitBank;
    dxs := TDX7IISupplementContainer.Create;
    dxsb := TDX7IISupplBankContainer.Create;
    dxt := TTX802PerformanceContainer.Create;
    dxtb := TTX802PerfBankContainer.Create;
    dxp := TDX7IIPerformanceContainer.Create;
    dxpb := TDX7IIPerfBankContainer.Create;

    i := 0;
    v := 1;
    p := 1;
    vr := 1;
    pr := 1;
    while i < ms.Size do
    begin
      i := PosBytes(aIFFLent, ms, i);
      if aVerbose then
        WriteLn('LENT at position: ' + IntToStr(i));
      if i = -1 then Break;
      ms.Position := i + 4;
      chunkSize := ms.ReadByte;
      if aVerbose then
        WriteLn('Chunk size: ' + IntToStr(chunkSize));
      ms.Position := i + 21;
      iNameLen := ms.ReadByte;
      if aVerbose then
        WriteLn('Name length: ' + IntToStr(iNameLen));
      SetLength(arName, iNameLen);
      sName := '';
      for j := 0 to (iNameLen - 1) do
      begin
        arName[j] := ms.ReadByte;
        sName := sName + char(arName[j]);
      end;
      SetLength(chunkDataID, 3);
      for j := 0 to 2 do
        chunkDataID[j] := ms.ReadByte;
      if SameArrays(chunkDataID, aIFFVMEM) then
      begin
        WriteLn('DX7II Voice ' + IntToStr(v) + ': ' + sName);
        //ToDo - do some length check before stream reading
        for j := 0 to 117 do
          dxVMEM.params[j] := ms.ReadByte and 127;
        for j := low(arName) to high(arName) do
          dxVMEM.params[118 + j] := arName[j];
        for j := (high(arName) + 1) to 9 do
          dxVMEM.params[118 + j] := $20;
        for j := 0 to 34 do
          dxAMEM.params[j] := ms.ReadByte and 127;
        chunkTargetID[0] := ms.ReadByte;
        chunkTargetID[1] := ms.ReadByte;
        if SameArrays(chunkTargetID, aIFFInternal) then
        begin
          dxv.Set_VMEM_Params(dxVMEM);
          dxs.Set_AMEM_Params(dxAMEM);
          dxvb.SetVoice(v, dxv);
          dxsb.SetSupplement(v, dxs);
          Inc(v);
        end;
        if v = 33 then
        begin
          msO := TMemoryStream.Create;
          dxsb.AppendSysExSupplBankToStream(1, msO);
          dxvb.AppendSysExBankToStream(1, msO);
          WriteLn('Writting: ' + aName + '.AV' + IntToStr(vr) + '.syx');
          msO.SaveToFile(aName + '.AV' + IntToStr(vr) + '.syx');
          msO.Position := 0;
          msAll.CopyFrom(msO, msO.Size);
          msO.Free;
          v := 1;
          Inc(vr);
        end;
      end;

      SetLength(chunkDataID, 2); //3rd byte from ChunkDataID varies
      if SameArrays(chunkDataID, aIFFPMEM) then
      begin
        WriteLn('DX7II Performance ' + IntToStr(p) + ': ' + sName);
        ms.Position := ms.Position - 1;
        for j := 0 to 30 do
          dxPCED.params[j] := ms.ReadByte;
        for j := low(arName) to high(arName) do
          dxPCED.params[31 + j] := arName[j];
        for j := (high(arName) + 1) to 19 do
          dxPCED.params[31 + j] := $20;
        chunkTargetID[0] := ms.ReadByte;
        chunkTargetID[1] := ms.ReadByte;
        if SameArrays(chunkTargetID, aIFFInternal) then
        begin
          dxp.Set_PCED_Params(dxPCED);
          dxpb.SetPerformance(p, dxp);
          Inc(p);
        end;
        if p = 33 then
        begin
          msO := TMemoryStream.Create;
          dxpb.AppendSysExPerformanceBankToStream(1, msO);
          WriteLn('Writting: ' + aName + '.P' + IntToStr(pr) + '.syx');
          msO.SaveToFile(aName + '.P' + IntToStr(pr) + '.syx');
          msO.Position := 0;
          msAll.CopyFrom(msO, msO.Size);
          msO.Free;
          Inc(pr);
        end;
      end;

      SetLength(chunkDataID, 2); //TX802 chunk ID is just two bytes long
      if SameArrays(chunkDataID, aIFFTX802) then
      begin
        WriteLn('TX802 Performance ' + IntToStr(p) + ': ' + sName);
        ms.Position := ms.Position - 1;
        for j := 0 to 63 do
          dxTX802P.params[j] := ms.ReadByte;
        for j := low(arName) to high(arName) do
          dxTX802P.params[64 + j] := arName[j];
        for j := (high(arName) + 1) to 19 do
          dxTX802P.params[64 + j] := $20;
        chunkTargetID[0] := ms.ReadByte;
        chunkTargetID[1] := ms.ReadByte;
        if SameArrays(chunkTargetID, aIFFInternal) then
        begin
          dxt.Set_PMEM_Params(dxTX802P);
          dxtb.SetPerformance(p, dxt);
          Inc(p);
        end;
        if p = 65 then
        begin
          msO := TMemoryStream.Create;
          dxtb.AppendSysExPerformanceBankToStream(1, msO);
          WriteLn('Writting: ' + aName + '.P' + IntToStr(pr) + '.syx');
          msO.SaveToFile(aName + '.P' + IntToStr(pr) + '.syx');
          msO.Position := 0;
          msAll.CopyFrom(msO, msO.Size);
          msO.Free;
          Inc(pr);
        end;
      end;

      i := i + chunkSize - 1;
      //clear arName
      for j := low(arName) to high(arName) do
        arName[j] := $20;
    end;

    dxv.Free;
    dxvb.Free;
    dxs.Free;
    dxsb.Free;
    dxt.Free;
    dxtb.Free;
    dxp.Free;
    dxpb.Free;
  end;

  WriteLn('All size: ' + IntToStr(msAll.Size));
  if msAll.Size > 0 then
  begin
    WriteLn('Writting: ' + aName + '.ALL.syx');
    msAll.SaveToFile(aName + '.ALL.sys');
  end;

  ms.Free;
  msAll.Free;
end;

end.
