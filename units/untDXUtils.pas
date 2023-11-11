{
 *****************************************************************************
  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************

 Author: Boban Spasic

 Unit description:
 This unit implements the detection/recognition of DX-Series SysEx Messages.
 Sequencer and some other (for me less important) headers are not implemented.
 Not all the MSB/LSB Data could be found in Yamaha's documentation. I've got some
 of them by inspecting various SysEx dumps.
}

unit untDXUtils;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, StrUtils, SysUtils, untUtils, untParConst;

type
  TDXSysExHeader = record
    f0: byte;
    id: byte;  // $43 or d67 = Yamaha
    sc: byte;  // s = sub-status, c = channel  0sssnnnn
    {
    s=0 - voice/suppl./perf. dump
    s=1 - direct single parameter change
    s=2 - dump request
    }
    f: byte;
    {
    f=0 - single_voice DX7
    f=1 - single_function TX7
    f=2 - bulk_function TX7
    f=3 - single_voice DX11/TX81z/V50/DX21
    f=4 - bulk_voice DX11/TX81z/V50/DX21
    f=5 - single_supplement DX7II
    f=6 - bulk_supplement DX7II
    f=7 -
    f=8 -
    f=9 - bulk_voice DX7
    f=7E - see TDXSysExUniversalDump
    }
    msb: byte; // MSB packet size
    lsb: byte; // LSB packet size
    {
    MSB/LSB=155 - single_voice DX7        expanded VCED
    MSB/LSB=93 - single_voice V50/DX21    expanded VCED
    MSB/LSB=49 - single_supplement DX7II  expanded ACED
    MSB/LSB=1120 - bulk_supplement DX7II  packed AMEM
    MSB/LSB=4096 - bulk_voice DX7         packed VMEM
    MSB/LSB=4096 - bulk_voice V50/DX21    packed VMEM
    }
    ud: array[0..9] of byte; //LM__xxxxxx
    chk: byte;
    f7: byte;
  end;

  TDXSysExUniversalDump = record
    f0: byte;
    id: byte;  // $43 / #67 = Yamaha
    sc: byte;  // s = 0, c = channel  0sssnnnn
    f: byte;   // f=7E
    classification: array[0..3] of char; // LM _ _
    data_format: array [0..5] of char;
    // classification and data_format can repeat more than once in the dump
    { underscores are spaces
    DX7II
    LM__8973PE    61 byte   DX7II Performance Edit Buffer                     1x
    LM__8973PM  1642 byte   DX7II Packed 32 Performance                       1x
    LM__8973S_   112 byte   DX7II System Set-up                               1x
    LM__MCRYE_   266 byte   Micro Tuning Edit Buffer                          1x
    LM__MCRYMx   266 byte   Micro Tuning with Memory #x=(0,1)                 2x
    LM__MCRYC_   266 byte   Micro Tuning Cartridge                           64x
    LM__FKSYE_   502 byte   Fractional Scaling Edit Buffer                    1x
    LM__FKSYC_   502 byte   Fractional Scaling in Cartridge with Memory #    32x
    LM__8952PM   171 byte   TX802 Performance
    V50/DX11/TX81z
    LM__8976AE    33 byte   ACED    TX81Z
    LM__8023AE    20 byte   ACED2   DX11
    LM__8073AE    30 byte   ACED3   V50
    LM__8976PE   120 byte   PCED    DX11
    LM__8073PE    43 byte   PCED2   V50
    LM__8976PM  2442 byte   PMEM    DX11
    LM__8073PM   810 byte   PMEM2   V50
    LM__8976Sx    xx byte   System
    LM__MCRTE0    34 byte   Micro Tuning Edit Buffer OCT
    LM__MCRTE1   274 byte   Micro Tuning Edit Buffer FULL
    LM__8023S0    26 byte   System
    LM__8073S0    42 byte   System
    LM__8952PM   171 byte   TX802 Performance
    }
  end;

type
  MEMS6 = (VMEM, AMEM, PMEM, LMPMEM);
  CEDS6 = (VCED, ACED, PCED);

type
  MemSet = set of MEMS6;
  CedSet = set of CEDS6;

const
  abSysExID: array[0..1] of byte = ($F0, $43);
  abSysEx6Type: array [0..6] of byte = ($00, $01, $02, $05, $06, $09, $7E);
  abSysEx4Type: array [0..2] of byte = ($03, $04, $7E);

function ContainsDX_SixOP_Data(dmp: TMemoryStream; var StartPos: integer;
  const Report: TStrings): boolean;
function ContainsDX_SixOP_MemSet(dmp: TMemoryStream): MemSet;
function FindDX_SixOP_MEM(mm: MEMS6; dmp: TMemoryStream;
  var SearchStartPos, FoundPos: integer): boolean;

function Printable(c: char): char;
function VCEDHexToStream(aHex: string; var aStream: TMemoryStream): boolean;
function StreamToVCEDHex(var aStream: TMemoryStream): string;

function RepairDX7SysEx(aFileName: string; var aFeedback: string): boolean;

implementation

operator in (const AByte: byte; const AArray: array of byte): boolean; inline;
var
  Item: byte;
begin
  for Item in AArray do
    if Item = AByte then
      Exit(True);

  Result := False;
end;

function ContainsDX_SixOP_Data(dmp: TMemoryStream; var StartPos: integer;
  const Report: TStrings): boolean;
var
  rHeader: TDXSysExHeader;
  iDumpStart: integer; // position of $F0
  iDataSize: integer;  // calculated from msb and lsb bytes
  iDumpEnd: integer;   // position of $F7
  iCalcChk: integer;
  iRep: integer;
  i: integer;
begin
  iDumpStart := -1;
  iDataSize := -1;
  iDumpEnd := -1;
  Result := False;
  iRep := StartPos;
  while iRep < dmp.Size do
  begin
    iDumpStart := PosBytes(abSysExID, dmp, iRep);
    if iDumpStart > -1 then
    begin
      if (iDumpStart + 8) <= dmp.Size then
      begin
        dmp.Position := iDumpStart;
        rHeader.f0 := dmp.ReadByte;
        rHeader.id := dmp.ReadByte;
        rHeader.sc := dmp.ReadByte;
        rHeader.f := dmp.ReadByte;
        rHeader.msb := dmp.ReadByte;
        rHeader.lsb := dmp.ReadByte;
        if rHeader.f in abSysEx6Type then
        begin
          StartPos := dmp.Position;
          if rHeader.f = $00 then
            Report.Add('DX7/DX9 Voice - VCED at position ' +
              IntToStr(StartPos));
          if rHeader.f = $01 then
            Report.Add('TX7/TX816 Performance - PCED at position ' +
              IntToStr(StartPos));
          if rHeader.f = $02 then
            Report.Add('TX7/TX816 Performance Bank - PMEM at position ' +
              IntToStr(StartPos));
          if rHeader.f = $05 then
            Report.Add('DX7II Voice Supplement - ACED at position ' +
              IntToStr(StartPos));
          if rHeader.f = $06 then
            Report.Add('DX7II Voice Bank Supplement - AMEM at position ' +
              IntToStr(StartPos));
          if rHeader.f = $09 then
            Report.Add('DX7/DX9 Voice Bank - VMEM at position ' +
              IntToStr(StartPos));
          if rHeader.f = $7E then
          begin
            if (dmp.Position + 10) <= dmp.Size then
            begin
              for i := 0 to 9 do
                rHeader.ud[i] := dmp.ReadByte;
              for i := Low(abLM6Type) to High(abLM6Type) do
                if SameArrays(rHeader.ud, abLM6Type[i]) then
                begin
                  case i of
                    0: Report.Add('DX7II PCED at position ' + IntToStr(StartPos));
                    1: Report.Add('DX7II PMEM at position ' + IntToStr(StartPos));
                    2: Report.Add('DX7II SYS at position ' + IntToStr(StartPos));
                    3: Report.Add('DX7II MTEB at position ' + IntToStr(StartPos));
                    4: Report.Add('DX7II MTEM1 at position ' + IntToStr(StartPos));
                    5: Report.Add('DX7II MTEM2 at position ' + IntToStr(StartPos));
                    6: Report.Add('DX7II MTEC at position ' + IntToStr(StartPos));
                    7: Report.Add('DX7II FSEB at position ' + IntToStr(StartPos));
                    8: Report.Add('DX7II FSEM at position ' + IntToStr(StartPos));
                    9: Report.Add('TX802 PMEM at position ' + IntToStr(StartPos));
                  end;
                end;
            end;
          end;
        end
        else
        begin
          Report.Add('Unknown Yamaha DX dump type: ' + IntToStr(rHeader.f));
        end;
        iDataSize := (rHeader.msb shl 7) + rHeader.lsb;
        Report.Add('Calculated data size: ' + IntToStr(iDataSize));
        if (iDumpStart + iDataSize + 8) <= dmp.Size then
        begin
          iDumpEnd := PosBytes($F7, dmp, iDumpStart + 1);
          if iDumpEnd = -1 then iDumpEnd := dmp.Size;
          Report.Add('Real data size: ' + IntToStr(iDumpEnd - iDumpStart - 7));
          if iDumpEnd = (iDumpStart + iDataSize + 7) then
          begin
            dmp.Position := iDumpEnd - 1;
            rHeader.chk := dmp.ReadByte;
            iCalcChk := 0;
            dmp.Position := iDumpStart + 6;
            for i := 1 to iDataSize do
              iCalcChk := iCalcChk + dmp.ReadByte;
            iCalcChk := ((not (iCalcChk and 255)) and 127) + 1;
            if (rHeader.chk = iCalcChk) or (rHeader.chk = 0) then
            begin
              Report.Add('Checksum match');
              Result := True;
            end
            else
            begin
              Report.Add('Checksum mismatch');
              Result := False;
            end;
          end
          else
          begin
            Report.Add('Data size mismatch');
          end;
          iRep := iDumpEnd + 1;
        end
        else
        begin
          Report.Add('File too short');
          Exit;
        end;
      end
      else
      begin
        Report.Add('File too short');
        Exit;
      end;
    end
    else
    begin
      Report.Add('DX header not found');
      Exit;
    end;
  end;
end;

function ContainsDX_SixOP_MemSet(dmp: TMemoryStream): MemSet;
var
  rHeader: TDXSysExHeader;
  iDumpStart: integer; // position of $F0
  iDataSize: integer;  // calculated from msb and lsb bytes
  iDumpEnd: integer;   // position of $F7
  iRep: integer;
  i: integer;
begin
  iDumpStart := -1;
  iDataSize := -1;
  iDumpEnd := -1;
  iRep := 0;
  Result := [];
  while iRep < dmp.Size do
  begin
    iDumpStart := PosBytes(abSysExID, dmp, iRep);
    if iDumpStart > -1 then
    begin
      if (iDumpStart + 8) <= dmp.Size then
      begin
        dmp.Position := iDumpStart;
        rHeader.f0 := dmp.ReadByte;
        rHeader.id := dmp.ReadByte;
        rHeader.sc := dmp.ReadByte;
        rHeader.f := dmp.ReadByte;
        if rHeader.f in abSysEx6Type then
        begin
          rHeader.msb := dmp.ReadByte;
          rHeader.lsb := dmp.ReadByte;
          if rHeader.f = $02 then
            Result := Result + [PMEM];
          if rHeader.f = $06 then
            Result := Result + [AMEM];
          if rHeader.f = $09 then
            Result := Result + [VMEM];
          if rHeader.f = $7E then
          begin
            if (dmp.Position + 10) <= dmp.Size then
            begin
              for i := 0 to 9 do
                rHeader.ud[i] := dmp.ReadByte;
            end;
            if SameArrays(rHeader.ud, abLM6Type[1]) then
              Result := Result + [LMPMEM];
          end;
        end;
        iDataSize := (rHeader.msb shl 7) + rHeader.lsb;
        if (iDumpStart + iDataSize + 8) <= dmp.Size then
        begin
          iDumpEnd := PosBytes($F7, dmp, iDumpStart + 1);
          if iDumpEnd = -1 then iDumpEnd := dmp.Size;
          iRep := iDumpEnd + 1;
        end
        else
          inc(iRep);
          //exit;
      end;
    end;
  end;
end;

function FindDX_SixOP_MEM(mm: MEMS6; dmp: TMemoryStream;
  var SearchStartPos, FoundPos: integer): boolean;
var
  rHeader: TDXSysExHeader;
  i:integer;
begin
  if SearchStartPos <= dmp.Size then
  begin
    dmp.Position := SearchStartPos;
    SearchStartPos := -1;
    while (SearchStartPos = -1) and (dmp.Position < dmp.Size - 6) do
    begin
      rHeader.f0 := dmp.ReadByte;
      if rHeader.f0 = $F0 then                                   // $F0 - SysEx
      begin
        SearchStartPos := dmp.Position - 1;
        rHeader.id := dmp.ReadByte;
        rHeader.sc := dmp.ReadByte;
        rHeader.f := dmp.ReadByte;
        rHeader.msb := dmp.ReadByte;
        rHeader.lsb := dmp.ReadByte;
        if not (rHeader.id = $43) then SearchStartPos := -1;         // $43 - Yamaha
        case mm of
          VMEM:
          begin
            if not (rHeader.f = $09) then SearchStartPos := -1;
            // $09 - 32 Voice dump
            if not ((rHeader.msb = $20) or (rHeader.msb = $10)) then
              SearchStartPos := -1;
            // byte count MS; $10 is a dirty fix for some corrupted files from DX5
            if not (rHeader.lsb = $00) then SearchStartPos := -1;    // byte count LS
          end;
          PMEM:
          begin
            if not (rHeader.f = $02) then SearchStartPos := -1;
            // $02 - 64 Function dump
            if not (rHeader.msb = $20) then SearchStartPos := -1;    // byte count MS
            if not (rHeader.lsb = $00) then SearchStartPos := -1;    // byte count LS
          end;
          AMEM:
          begin
            if not (rHeader.f = $06) then SearchStartPos := -1;
            // $06 - 32 Supplement dump
            if not (rHeader.msb = $08) then SearchStartPos := -1;    // byte count MS
            if not (rHeader.lsb = $60) then SearchStartPos := -1;    // byte count LS
          end;
          LMPMEM:
          begin
            if not (rHeader.f = $7E) then SearchStartPos := -1;
            if (dmp.Position + 10) <= dmp.Size then
            begin
              for i := 0 to 9 do
                rHeader.ud[i] := dmp.ReadByte;
            end;
            if not SameArrays(rHeader.ud, abLM6Type[1]) then
              SearchStartPos := -1;
            // $06 - 32 Supplement dump
            if not (rHeader.msb = $0C) then SearchStartPos := -1;    // byte count MS
            if not (rHeader.lsb = $6A) then SearchStartPos := -1;    // byte count LS
          end;
        end;
      end;
    end;
    if SearchStartPos <> -1 then
      case mm of
        VMEM:
          if (dmp.Size - SearchStartPos) < 4104 then
            SearchStartPos := -1;  //file too short
        PMEM:
          if (dmp.Size - SearchStartPos) < 4104 then
            SearchStartPos := -1;  //file too short
        AMEM:
          if (dmp.Size - SearchStartPos) < 1128 then
            SearchStartPos := -1;  //file too short
      end;

    if SearchStartPos <> -1 then
    begin
      Result := True;
      if mm = LMPMEM then
      FoundPos := SearchStartPos + 16 else
      FoundPos := SearchStartPos + 6;
    end
    else
    begin
      Result := False;
      FoundPos := -1;
    end;
  end
  else
  begin
    SearchStartPos := -1;
    Result := False;
  end;
end;

function Printable(c: char): char;
begin
  if (Ord(c) > 31) and (Ord(c) < 127) then Result := c
  else
    Result := #32;
end;

function VCEDHexToStream(aHex: string; var aStream: TMemoryStream): boolean;
var
  s: string;
  partS: string;
  buffer: array [0..156] of byte;
  i: integer;
begin
  try
    s := ReplaceStr(aHex, ' ', '');
    aStream.Clear;
    for i := 0 to 155 do
    begin
      partS := '$' + Copy(s, i * 2 + 1, 2);
      buffer[i] := byte(Hex2Dec(partS));
      aStream.WriteByte(buffer[i]);
    end;
    Result := True;
  except
    on e: Exception do Result := False;
  end;
end;

function StreamToVCEDHex(var aStream: TMemoryStream): string;
var
  i: integer;
begin
  Result := '';
  aStream.Position := 0;
  for i := 0 to aStream.Size - 1 do
  begin
    Result := Result + IntToHex(aStream.ReadByte, 2) + ' ';
  end;
  Result := ReplaceStr(Result, '$', '');
  Result := Trim(Result);
end;

function RepairDX7SysEx(aFileName: string; var aFeedback: string): boolean;
var
  msToRepair: TMemoryStream;
  msRepaired: TMemoryStream;
  sNameRepaired: string;
  sNameRepaired2: string;
  sDirRepaired: string;
  checksum: integer;
  bChk: byte;
  i, j: integer;
begin
  Result := False;
  msToRepair := TMemoryStream.Create;
  msRepaired := TMemoryStream.Create;
  msToRepair.LoadFromFile(aFileName);
  sNameRepaired := ExtractFileName(aFileName);
  sNameRepaired := ExtractFileNameWithoutExt(sNameRepaired);
  sDirRepaired := IncludeTrailingPathDelimiter(ExtractFileDir(aFileName));
  sNameRepaired2 := sDirRepaired + sNameRepaired;
  sNameRepaired := sDirRepaired + sNameRepaired + '_DX7_repaired.syx';
  aFeedback := 'File size = ' + IntToStr(msToRepair.Size);

  //reparation
  //header-less file
  if msToRepair.Size = 4096 then
  begin
    try
      //write DX7 VMEM header
      msRepaired.WriteByte($F0);
      msRepaired.WriteByte($43);
      msRepaired.WriteByte($00);
      msRepaired.WriteByte($09);
      msRepaired.WriteByte($20);
      msRepaired.WriteByte($00);

      //copy data
      msRepaired.CopyFrom(msToRepair, 4096);

      //get checksum
      checksum := 0;
      i := 0;
      msToRepair.Position := 0;
      for i := 0 to msToRepair.Size - 1 do
        checksum := checksum + msToRepair.ReadByte;
      bChk := byte(((not (checksum and 255)) and 127) + 1);

      msRepaired.WriteByte(bChk);
      msRepaired.WriteByte($F7);
      Result := True;
    except
      on E: Exception do Result := False;
    end;
    if Result then msRepaired.SaveToFile(sNameRepaired);
  end;

  //file with missing checksum byte
  if msToRepair.Size = 4103 then
  begin
    try
      //copy data
      msRepaired.CopyFrom(msToRepair, 4102);

      //get checksum
      checksum := 0;
      i := 0;
      msToRepair.Position := 0;
      for i := 0 to msToRepair.Size - 1 do
        checksum := checksum + msToRepair.ReadByte;
      bChk := byte(((not (checksum and 255)) and 127) + 1);

      msRepaired.WriteByte(bChk);
      msRepaired.WriteByte($F7);
      Result := True;
    except
      on E: Exception do Result := False;
    end;
    if Result then msRepaired.SaveToFile(sNameRepaired);
  end;

  //32 VCEDs without header
  if msToRepair.Size = 4960 then
  begin
    msToRepair.Position := 0;
    for j := 1 to 32 do
    begin
      try
        msRepaired.Clear;
        msRepaired.Size := 0;
        //write DX7 VCED header
        msRepaired.WriteByte($F0);
        msRepaired.WriteByte($43);
        msRepaired.WriteByte($00);
        msRepaired.WriteByte($00);
        msRepaired.WriteByte($01);
        msRepaired.WriteByte($1B);

        //copy data
        msRepaired.CopyFrom(msToRepair, 155);

        //get checksum
        checksum := 0;
        msRepaired.Position := 6;
        while msRepaired.Position < (msRepaired.Size) do
          checksum := checksum + msRepaired.ReadByte;
        bChk := byte(((not (checksum and 255)) and 127) + 1);

        msRepaired.WriteByte(bChk);
        msRepaired.WriteByte($F7);
        Result := True;
      except
        on E: Exception do Result := False;
      end;
      if Result then msRepaired.SaveToFile(sNameRepaired2 + 'DX7_R' +
          IntToHex(j, 2) + '.syx');

    end;
  end;

  //Bad size MSB in header
  if msToRepair.Size = 4104 then
  begin
    try
      msToRepair.Position := 0;
      msRepaired.Clear;
      msRepaired.Size := 0;
      msRepaired.CopyFrom(msToRepair, 4);
      msRepaired.WriteByte($20);
      msToRepair.Position := 5;
      msRepaired.CopyFrom(msToRepair, 4099);
      Result := True;
    except
      on E: Exception do Result := False;
    end;
    if Result then msRepaired.SaveToFile(sNameRepaired);
  end;

  msToRepair.Free;
  msRepaired.Free;
end;

end.
