{
 *****************************************************************************
  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************

 Author: Boban Spasic

 Unit description:
 Conversion from TX7, DX5 and DX7II to MiniDexed INI format
}
unit untConverter;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, untDX7Bank, untDX7Voice, untDX7IISupplBank,
  untDX7IISupplement, untTX7FunctBank, untTX7Function, untMDXPerformance,
  untMDXSupplement, untDX7IIPerformance, untDX7IIPerformanceBank,
  untDXUtils, untParConst, untUtils, untTX802Performance, untTX802PerformanceBank, IniFiles, untConvFunct;

procedure ConvertTX7toMDX(var ms: TMemoryStream; APath: string; ANumber: integer; AVerbose: boolean);                                // VMEM + PMEM 1-32
procedure ConvertDX7IItoMDX(var ms: TMemoryStream; AName, APath: string; ANumber: integer; AVerbose: boolean; ASettings: string);           // VMEM + AMEM 1-32
procedure ConvertMultiDX7IItoMDX(var ms: TMemoryStream; AName, APath: string; ANumber: integer; AVerbose: boolean; ASettings: string);      // multiple VMEM + AMEM 1-32
procedure ConvertDX5toMDX(var ms: TMemoryStream; APath: string; ANumber: integer; AVerbose: boolean);                                // 4xVMEM, PMEM
procedure ConvertTX802ToMDX(var ms: TMemoryStream; APath: string; ANumber: integer; AVerbose: boolean; ASettings: string);           // 4xVMEM, 4xAMEM, 2xPMEM
procedure ConvertBigDX7IItoMDX(var ms: TMemoryStream; APath: string; ANumber: integer; AVerbose: boolean; ASettings: string);        // 2xVMEM, 2xAMEM, 1xPMEM
procedure Convert2BigDX7IItoMDX(var msA1, msB1: TMemoryStream; APath: string; ANumber: integer; AVerbose: boolean; ASettings: string); // 4xVMEM, 4xAMEM, 2xPMEM
function GetSettingsFromFile(ASettings: string; var aAMS_table: TAMS; var aPEGR_table: TPEGR): boolean;

implementation

{$R TX802.res}

procedure ConvertTX7toMDX(var ms: TMemoryStream; APath: string; ANumber: integer; AVerbose: boolean);
var
  DX: TDX7BankContainer;
  TX7: TTX7FunctBankContainer;
  MDX: TMDXPerformanceContainer;

  DX7_VCED: TDX7VoiceContainer;
  TX7_PCED: TTX7FunctionContainer;
  MDX_TG: TMDXSupplementContainer;

  msSearchPosition: integer;
  msFoundPosition: integer;

  i, j: integer;
  sName: string;
begin
  msSearchPosition := 0;
  msFoundPosition := 0;

  DX := TDX7BankContainer.Create;
  TX7 := TTX7FunctBankContainer.Create;
  MDX := TMDXPerformanceContainer.Create;
  if FindDX_SixOP_MEM(VMEM, ms, msSearchPosition, msFoundPosition) then
  begin
    DX.LoadBankFromStream(ms, msFoundPosition);
    WriteLn('VMEM loaded from ' + IntToStr(msFoundPosition));
    if AVerbose then
      for i := 1 to 32 do
        WriteLn(DX.GetVoiceName(i));
  end;
  msSearchPosition := 0;
  if FindDX_SixOP_MEM(PMEM, ms, msSearchPosition, msFoundPosition) then
  begin
    TX7.LoadFunctBankFromStream(ms, msFoundPosition);
    WriteLn('PMEM loaded from ' + IntToStr(msFoundPosition));
    if AVerbose then
      for i := 1 to 32 do
        WriteLn(TX7.GetFunctionName(i));
  end;

  for i := 0 to 3 do
  begin
    MDX.InitPerformance;
    MDX.AllMIDIChToZero;
    MDX.FMDX_Params.General.Name := TX7.GetFunctionName(i);
    MDX.FMDX_Params.General.Category := 'Converted';
    MDX.FMDX_Params.General.Origin := 'Conversion from TX7 Performances';

    sName := Format('%.6d', [i + ANumber]) + '_' +
      Trim(ExtractFileNameWithoutExt(ExtractFileName(APath)));
    sName := copy(sName, 1, 19) + '_' + IntToStr(i);

    for j := 1 to 8 do
    begin
      DX7_VCED := TDX7VoiceContainer.Create;
      TX7_PCED := TTX7FunctionContainer.Create;
      MDX_TG := TMDXSupplementContainer.Create;

      DX.GetVoice(i * 8 + j, DX7_VCED);
      TX7.GetFunction(i * 8 + j, TX7_PCED);
      MDX.LoadVoiceToTG(j, DX7_VCED.Get_VCED_Params);
      MDX_TG.Set_PCEDx_Params(LoadTX7PCEDtoPCEDx(TX7_PCED));
      MDX.LoadPCEDxToTG(j, MDX_TG.Get_PCEDx_Params);
      MDX.FMDX_Params.TG[j].MIDIChannel := j;
      MDX.SavePerformanceToFile(IncludeTrailingPathDelimiter(APath) +
        sName + '.ini', False);

      DX7_VCED.Free;
      TX7_PCED.Free;
      MDX_TG.Free;
    end;
  end;

  DX.Free;
  TX7.Free;
  MDX.Free;
end;

procedure ConvertDX7IItoMDX(var ms: TMemoryStream; AName, APath: string; ANumber: integer; AVerbose: boolean; ASettings: string);
var
  DX7: TDX7BankContainer;
  DX7II: TDX7IISupplBankContainer;
  MDX: TMDXPerformanceContainer;

  DX7_VCED: TDX7VoiceContainer;
  DX7II_ACED: TDX7IISupplementContainer;
  MDX_TG: TMDXSupplementContainer;

  msSearchPosition: integer;
  msFoundPosition: integer;

  i, j: integer;
  sName: string;

  perg, ams1, ams2, ams3, ams4, ams5, ams6: byte;
  AMS_table: TAMS;
  PEGR_table: TPEGR;
begin
  msSearchPosition := 0;
  msFoundPosition := 0;

  DX7 := TDX7BankContainer.Create;
  DX7II := TDX7IISupplBankContainer.Create;
  MDX := TMDXPerformanceContainer.Create;
  if FindDX_SixOP_MEM(VMEM, ms, msSearchPosition, msFoundPosition) then
  begin
    DX7.LoadBankFromStream(ms, msFoundPosition);
    WriteLn('VMEM loaded from ' + IntToStr(msFoundPosition));
    if AVerbose then
      for i := 1 to 32 do
        WriteLn(DX7.GetVoiceName(i));
  end;
  msSearchPosition := 0;
  if FindDX_SixOP_MEM(AMEM, ms, msSearchPosition, msFoundPosition) then
  begin
    DX7II.LoadSupplBankFromStream(ms, msFoundPosition);
    WriteLn('AMEM loaded from ' + IntToStr(msFoundPosition));
  end;

  for i := 0 to 3 do
  begin
    MDX.InitPerformance;
    MDX.AllMIDIChToZero;
    MDX.FMDX_Params.General.Name :=
      'Voices ' + IntToStr(i * 8) + ' to ' + IntToStr((i + 1) * 8 - 1);
    MDX.FMDX_Params.General.Category := 'Converted';
    MDX.FMDX_Params.General.Origin := 'Conversion from DX7II Voices';

    sName := Format('%.6d', [i + ANumber + 1]) + '_' +
      Trim(ExtractFileNameWithoutExt(ExtractFileName(AName)));
    sName := copy(sName, 1, 19) + '_' + IntToStr(i);

    for j := 1 to 8 do
    begin
      DX7_VCED := TDX7VoiceContainer.Create;
      DX7II_ACED := TDX7IISupplementContainer.Create;
      MDX_TG := TMDXSupplementContainer.Create;

      DX7.GetVoice(i * 8 + j, DX7_VCED);
      DX7II.GetSupplement(i * 8 + j, DX7II_ACED);
      perg := DX7II_ACED.Get_ACED_Params.Pitch_EG_Range;
      ams1 := DX7II_ACED.Get_ACED_Params.OP1_AM_Sensitivity;
      ams2 := DX7II_ACED.Get_ACED_Params.OP2_AM_Sensitivity;
      ams3 := DX7II_ACED.Get_ACED_Params.OP3_AM_Sensitivity;
      ams4 := DX7II_ACED.Get_ACED_Params.OP4_AM_Sensitivity;
      ams5 := DX7II_ACED.Get_ACED_Params.OP5_AM_Sensitivity;
      ams6 := DX7II_ACED.Get_ACED_Params.OP6_AM_Sensitivity;
      if GetSettingsFromFile(ASettings, AMS_table, PEGR_table) = True then
        DX7_VCED.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6, AMS_table, PEGR_table)
      else
        DX7_VCED.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6);
      MDX.LoadVoiceToTG(j, DX7_VCED.Get_VCED_Params);
      MDX_TG.Set_PCEDx_Params(LoadDX7IIACEDtoPCEDx(DX7II_ACED));
      MDX.LoadPCEDxToTG(j, MDX_TG.Get_PCEDx_Params);
      MDX.FMDX_Params.TG[j].MIDIChannel := j;
      MDX.SavePerformanceToFile(IncludeTrailingPathDelimiter(APath) +
        sName + '.ini', False);

      DX7_VCED.Free;
      DX7II_ACED.Free;
      MDX_TG.Free;
    end;
  end;

  DX7.Free;
  DX7II.Free;
  MDX.Free;
end;

procedure ConvertMultiDX7IItoMDX(var ms: TMemoryStream; AName, APath: string; ANumber: integer; AVerbose: boolean; ASettings: string);
var
  DX7: TDX7BankContainer;
  DX7II: TDX7IISupplBankContainer;
  MDX: TMDXPerformanceContainer;

  DX7_VCED: TDX7VoiceContainer;
  DX7II_ACED: TDX7IISupplementContainer;
  MDX_TG: TMDXSupplementContainer;

  msSearchPositionV: integer;
  msFoundPositionV: integer;
  msSearchPositionA: integer;
  msFoundPositionA: integer;

  i, j: integer;
  sName: string;
  bank_counter: integer;

  perg, ams1, ams2, ams3, ams4, ams5, ams6: byte;
  AMS_table: TAMS;
  PEGR_table: TPEGR;
begin
  msSearchPositionV := 0;
  msFoundPositionV := 0;
  msSearchPositionA := 0;
  msFoundPositionA := 0;
  bank_counter := 0;

  while FindDX_SixOP_MEM(VMEM, ms, msSearchPositionV, msFoundPositionV) do
  begin

    DX7 := TDX7BankContainer.Create;
    DX7II := TDX7IISupplBankContainer.Create;
    MDX := TMDXPerformanceContainer.Create;
    if FindDX_SixOP_MEM(VMEM, ms, msSearchPositionV, msFoundPositionV) then
    begin
      DX7.LoadBankFromStream(ms, msFoundPositionV);
      WriteLn('VMEM loaded from ' + IntToStr(msFoundPositionV));
      if AVerbose then
        for i := 1 to 32 do
          WriteLn(DX7.GetVoiceName(i));
    end;
    msSearchPositionV := msFoundPositionV;

    if FindDX_SixOP_MEM(AMEM, ms, msSearchPositionA, msFoundPositionA) then
    begin
      DX7II.LoadSupplBankFromStream(ms, msFoundPositionA);
      WriteLn('AMEM loaded from ' + IntToStr(msFoundPositionA));
    end;
    msSearchPositionA := msFoundPositionA;

    for i := 0 to 3 do
    begin
      MDX.InitPerformance;
      MDX.AllMIDIChToZero;
      MDX.FMDX_Params.General.Name :=
        'Voices ' + IntToStr(i * 8) + ' to ' + IntToStr((i + 1) * 8 - 1);
      MDX.FMDX_Params.General.Category := 'Converted';
      MDX.FMDX_Params.General.Origin := 'Conversion from DX7II Voices';

      sName := Format('%.6d', [i + ANumber + bank_counter + 1]) + '_' +
        Trim(ExtractFileNameWithoutExt(ExtractFileName(AName)));
      sName := copy(sName, 1, 19) + '_' + IntToStr(i + bank_counter);

      for j := 1 to 8 do
      begin
        DX7_VCED := TDX7VoiceContainer.Create;
        DX7II_ACED := TDX7IISupplementContainer.Create;
        MDX_TG := TMDXSupplementContainer.Create;

        DX7.GetVoice(i * 8 + j, DX7_VCED);
        DX7II.GetSupplement(i * 8 + j, DX7II_ACED);
        perg := DX7II_ACED.Get_ACED_Params.Pitch_EG_Range;
        ams1 := DX7II_ACED.Get_ACED_Params.OP1_AM_Sensitivity;
        ams2 := DX7II_ACED.Get_ACED_Params.OP2_AM_Sensitivity;
        ams3 := DX7II_ACED.Get_ACED_Params.OP3_AM_Sensitivity;
        ams4 := DX7II_ACED.Get_ACED_Params.OP4_AM_Sensitivity;
        ams5 := DX7II_ACED.Get_ACED_Params.OP5_AM_Sensitivity;
        ams6 := DX7II_ACED.Get_ACED_Params.OP6_AM_Sensitivity;
        if GetSettingsFromFile(ASettings, AMS_table, PEGR_table) = True then
          DX7_VCED.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6, AMS_table, PEGR_table)
        else
          DX7_VCED.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6);
        MDX.LoadVoiceToTG(j, DX7_VCED.Get_VCED_Params);
        MDX_TG.Set_PCEDx_Params(LoadDX7IIACEDtoPCEDx(DX7II_ACED));
        MDX.LoadPCEDxToTG(j, MDX_TG.Get_PCEDx_Params);
        MDX.FMDX_Params.TG[j].MIDIChannel := j;
        MDX.SavePerformanceToFile(IncludeTrailingPathDelimiter(APath) +
          sName + '.ini', False);

        DX7_VCED.Free;
        DX7II_ACED.Free;
        MDX_TG.Free;
      end;
    end;
    Inc(bank_counter, 4);

    DX7.Free;
    DX7II.Free;
    MDX.Free;
  end;
end;

procedure ConvertDX5toMDX(var ms: TMemoryStream; APath: string; ANumber: integer; AVerbose: boolean);
var
  DXA1: TDX7BankContainer;
  DXB1: TDX7BankContainer;
  DXA2: TDX7BankContainer;
  DXB2: TDX7BankContainer;

  TX7: TTX7FunctBankContainer;
  MDX: TMDXPerformanceContainer;

  DX7_VCED: TDX7VoiceContainer;
  TX7_PCED: TTX7FunctionContainer;
  MDX_TG1: TMDXSupplementContainer;
  MDX_TG2: TMDXSupplementContainer;

  msSearchPosition: integer;
  msFoundPosition: integer;

  i: integer;
  sName: string;
begin
  msFoundPosition := 0;

  DXA1 := TDX7BankContainer.Create;
  DXB1 := TDX7BankContainer.Create;
  DXA2 := TDX7BankContainer.Create;
  DXB2 := TDX7BankContainer.Create;
  TX7 := TTX7FunctBankContainer.Create;
  MDX := TMDXPerformanceContainer.Create;

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(VMEM, ms, msSearchPosition, msFoundPosition) then
  begin
    DXA1.LoadBankFromStream(ms, msFoundPosition);
    WriteLn('VMEM loaded from ' + IntToStr(msFoundPosition));
    if AVerbose then
      for i := 1 to 32 do
        WriteLn(DXA1.GetVoiceName(i));
  end;

  msSearchPosition := msFoundPosition;
  if FindDX_SixOP_MEM(VMEM, ms, msSearchPosition, msFoundPosition) then
  begin
    DXB1.LoadBankFromStream(ms, msFoundPosition);
    WriteLn('VMEM loaded from ' + IntToStr(msFoundPosition));
    if AVerbose then
      for i := 1 to 32 do
        WriteLn(DXB1.GetVoiceName(i));
  end;

  msSearchPosition := msFoundPosition;
  if FindDX_SixOP_MEM(VMEM, ms, msSearchPosition, msFoundPosition) then
  begin
    DXA2.LoadBankFromStream(ms, msFoundPosition);
    WriteLn('VMEM loaded from ' + IntToStr(msFoundPosition));
    if AVerbose then
      for i := 1 to 32 do
        WriteLn(DXA2.GetVoiceName(i));
  end;

  msSearchPosition := msFoundPosition;
  if FindDX_SixOP_MEM(VMEM, ms, msSearchPosition, msFoundPosition) then
  begin
    DXB2.LoadBankFromStream(ms, msFoundPosition);
    WriteLn('VMEM loaded from ' + IntToStr(msFoundPosition));
    if AVerbose then
      for i := 1 to 32 do
        WriteLn(DXB2.GetVoiceName(i));
  end;

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(PMEM, ms, msSearchPosition, msFoundPosition) then
  begin
    TX7.LoadFunctBankFromStream(ms, msFoundPosition);
    WriteLn('PMEM loaded from ' + IntToStr(msFoundPosition));
    if AVerbose then
      for i := 1 to 64 do
        WriteLn(TX7.GetFunctionName(i));
  end;

  WriteLn('Writting A1,B1');
  //Banks A1 and B1, performances 1 to 32
  for i := 1 to 32 do
  begin
    MDX.InitPerformance;
    MDX.AllMIDIChToZero;
    MDX.FMDX_Params.General.Name := TX7.GetFunctionName(i);
    MDX.FMDX_Params.General.Category := 'Converted';
    MDX.FMDX_Params.General.Origin := 'Conversion from DX1/DX5 Performances';
    DX7_VCED := TDX7VoiceContainer.Create;
    TX7_PCED := TTX7FunctionContainer.Create;
    MDX_TG1 := TMDXSupplementContainer.Create;
    MDX_TG2 := TMDXSupplementContainer.Create;

    TX7.GetFunction(i, TX7_PCED);
    sName := Format('%.6d', [i + ANumber]) + '_' + Trim(GetValidFileName(TX7.GetFunctionName(i)));
    sName := copy(sName, 1, 21);

    DXA1.GetVoice(i, DX7_VCED);
    MDX.LoadVoiceToTG(1, DX7_VCED.Get_VCED_Params);
    MDX_TG1.Set_PCEDx_Params(LoadTX7PCEDtoPCEDx(TX7_PCED));
    MDX.LoadPCEDxToTG(1, MDX_TG1.Get_PCEDx_Params);
    MDX.FMDX_Params.TG[1].MIDIChannel := 1;

    if TX7_PCED.Get_PCED_Params.G_KeyAssignMode <> 0 then
    begin
      DXB1.GetVoice(i, DX7_VCED);
      MDX.LoadVoiceToTG(2, DX7_VCED.Get_VCED_Params);
      MDX_TG2.Set_PCEDx_Params(LoadDX5PCEDtoPCEDx(TX7_PCED));
      MDX.LoadPCEDxToTG(2, MDX_TG2.Get_PCEDx_Params);
      MDX.FMDX_Params.TG[2].MIDIChannel := 1;
    end;

    WriteLn('Writting ' + sName + '.ini');
    MDX.SavePerformanceToFile(IncludeTrailingPathDelimiter(APath) +
      sName + '.ini', False);

    DX7_VCED.Free;
    TX7_PCED.Free;
    MDX_TG1.Free;
    MDX_TG2.Free;
  end;
  //Banks A2 and B2, performances 33 to 64
  WriteLn('Writting A2,B2');
  for i := 1 to 32 do
  begin
    MDX.InitPerformance;
    MDX.AllMIDIChToZero;
    MDX.FMDX_Params.General.Name := TX7.GetFunctionName(i + 32);
    MDX.FMDX_Params.General.Category := 'Converted';
    MDX.FMDX_Params.General.Origin := 'Conversion from DX1/DX5 Performances';
    DX7_VCED := TDX7VoiceContainer.Create;
    TX7_PCED := TTX7FunctionContainer.Create;
    MDX_TG1 := TMDXSupplementContainer.Create;
    MDX_TG2 := TMDXSupplementContainer.Create;

    TX7.GetFunction(i + 32, TX7_PCED);
    sName := Format('%.6d', [i + ANumber + 32]) + '_' +
      Trim(GetValidFileName(TX7.GetFunctionName(i + 32)));
    sName := copy(sName, 1, 21);

    DXA2.GetVoice(i, DX7_VCED);
    MDX.LoadVoiceToTG(1, DX7_VCED.Get_VCED_Params);
    MDX_TG1.Set_PCEDx_Params(LoadTX7PCEDtoPCEDx(TX7_PCED));
    MDX.LoadPCEDxToTG(1, MDX_TG1.Get_PCEDx_Params);
    MDX.FMDX_Params.TG[1].MIDIChannel := 1;

    if TX7_PCED.Get_PCED_Params.G_KeyAssignMode <> 0 then
    begin
      DXB2.GetVoice(i, DX7_VCED);
      MDX.LoadVoiceToTG(2, DX7_VCED.Get_VCED_Params);
      MDX_TG2.Set_PCEDx_Params(LoadDX5PCEDtoPCEDx(TX7_PCED));
      MDX.LoadPCEDxToTG(2, MDX_TG2.Get_PCEDx_Params);
      MDX.FMDX_Params.TG[2].MIDIChannel := 1;
    end;

    WriteLn('Writting ' + sName + '.ini');
    MDX.SavePerformanceToFile(IncludeTrailingPathDelimiter(APath) +
      sName + '.ini', False);

    DX7_VCED.Free;
    TX7_PCED.Free;
    MDX_TG1.Free;
    MDX_TG2.Free;
  end;

  DXA1.Free;
  DXB1.Free;
  DXA2.Free;
  DXB2.Free;
  TX7.Free;
  MDX.Free;
end;

procedure ConvertTX802ToMDX(var ms: TMemoryStream; APath: string; ANumber: integer; AVerbose: boolean; ASettings: string);
var
  rsROM: TResourceStream;
  msROM: TMemoryStream;
  //Containers for ROM voices
  DXA1: TDX7BankContainer;
  DXA2: TDX7BankContainer;
  DXB1: TDX7BankContainer;
  DXB2: TDX7BankContainer;
  DXA1s: TDX7IISupplBankContainer;
  DXA2s: TDX7IISupplBankContainer;
  DXB1s: TDX7IISupplBankContainer;
  DXB2s: TDX7IISupplBankContainer;
  //Containers for Internal voices
  DXI1: TDX7BankContainer;
  DXI2: TDX7BankContainer;
  DXI1s: TDX7IISupplBankContainer;
  DXI2s: TDX7IISupplBankContainer;
  //Performance containers
  TX802: TTX802PerfBankContainer;
  MDX: TMDXPerformanceContainer;
  //Div. temp. buffers
  DX7_VCED: TDX7VoiceContainer;
  DX7II_ACED: TDX7IISupplementContainer;
  TX802_PCED: TTX802PerformanceContainer;
  MDX_TG: TMDXSupplementContainer;
  Params: TTX802_PCED_Params;
  iVoice: array [1..8] of integer;
  //search in streams
  msSearchPosition: integer;
  msFoundPositionV: integer;
  msFoundPositionA: integer;
  //diverses
  i, j, t: integer;
  sName: string;
  //for conversion DX7II to DX7
  perg, ams1, ams2, ams3, ams4, ams5, ams6: byte;
  AMS_table: TAMS;
  PEGR_table: TPEGR;

begin
  msFoundPositionV := 0;
  msFoundPositionA := 0;

  //ROM 128 voices
  DXA1 := TDX7BankContainer.Create;
  DXA2 := TDX7BankContainer.Create;
  DXB1 := TDX7BankContainer.Create;
  DXB2 := TDX7BankContainer.Create;
  DXA1s := TDX7IISupplBankContainer.Create;
  DXA2s := TDX7IISupplBankContainer.Create;
  DXB1s := TDX7IISupplBankContainer.Create;
  DXB2s := TDX7IISupplBankContainer.Create;
  //input files/data/stream  64 voices
  DXI1 := TDX7BankContainer.Create;
  DXI2 := TDX7BankContainer.Create;
  DXI1s := TDX7IISupplBankContainer.Create;
  DXI2s := TDX7IISupplBankContainer.Create;
  //input performance
  TX802 := TTX802PerfBankContainer.Create;

  rsROM := TResourceStream.Create(HINSTANCE, 'TX802ROM', PChar(10));
  msROM := TMemoryStream.Create;
  rsROM.Position := 0;
  msROM.CopyFrom(rsROM, rsRom.Size);
  rsROM.Free;

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(VMEM, msROM, msSearchPosition, msFoundPositionV) then
    DXA1.LoadBankFromStream(msROM, msFoundPositionV);
  msSearchPosition := 0;
  if FindDX_SixOP_MEM(AMEM, msROM, msSearchPosition, msFoundPositionA) then
    DXA1s.LoadSupplBankFromStream(msROM, msFoundPositionA);
  msSearchPosition := msFoundPositionV;
  if FindDX_SixOP_MEM(VMEM, msROM, msSearchPosition, msFoundPositionV) then
    DXA2.LoadBankFromStream(msROM, msFoundPositionV);
  msSearchPosition := msFoundPositionA;
  if FindDX_SixOP_MEM(AMEM, msROM, msSearchPosition, msFoundPositionA) then
    DXA2s.LoadSupplBankFromStream(msROM, msFoundPositionA);
  msSearchPosition := msFoundPositionV;
  if FindDX_SixOP_MEM(VMEM, msROM, msSearchPosition, msFoundPositionV) then
    DXB1.LoadBankFromStream(msROM, msFoundPositionV);
  msSearchPosition := msFoundPositionA;
  if FindDX_SixOP_MEM(AMEM, msROM, msSearchPosition, msFoundPositionA) then
    DXB1s.LoadSupplBankFromStream(msROM, msFoundPositionA);
  msSearchPosition := msFoundPositionV;
  if FindDX_SixOP_MEM(VMEM, msROM, msSearchPosition, msFoundPositionV) then
    DXB2.LoadBankFromStream(msROM, msFoundPositionV);
  msSearchPosition := msFoundPositionA;
  if FindDX_SixOP_MEM(AMEM, msROM, msSearchPosition, msFoundPositionA) then
    DXB2s.LoadSupplBankFromStream(msROM, msFoundPositionA);

  DXI1s.InitSupplBank;
  DXI2s.InitSupplBank;

  MDX := TMDXPerformanceContainer.Create;

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(VMEM, ms, msSearchPosition, msFoundPositionV) then
  begin
    DXI1.LoadBankFromStream(ms, msFoundPositionV);
    WriteLn('');
    WriteLn('VMEM I1 loaded from position ' +
      IntToStr(msFoundPositionV));
    if AVerbose then
      for i := 1 to 32 do
        WriteLn(DXI1.GetVoiceName(i));
  end;

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(AMEM, ms, msSearchPosition, msFoundPositionA) then
  begin
    DXI1s.LoadSupplBankFromStream(ms, msFoundPositionA);
    WriteLn('');
    WriteLn('AMEM I1 loaded from position ' +
      IntToStr(msFoundPositionA));
  end;

  msSearchPosition := msFoundPositionV;
  if (msFoundPositionV <> -1) and (FindDX_SixOP_MEM(VMEM, ms, msSearchPosition, msFoundPositionV)) then
  begin
    DXI2.LoadBankFromStream(ms, msFoundPositionV);
    WriteLn('');
    WriteLn('VMEM I2 loaded from position ' +
      IntToStr(msFoundPositionV));
    if AVerbose then
      for i := 1 to 32 do
        WriteLn(DXI2.GetVoiceName(i));
  end
  else
  begin
    WriteLn('VMEM I2 not found, using INIT parameters');
    DXI2.InitBank;
  end;

  msSearchPosition := msFoundPositionA;
  if (msFoundPositionA <> -1) and (FindDX_SixOP_MEM(AMEM, ms, msSearchPosition, msFoundPositionA)) then
  begin
    DXI2s.LoadSupplBankFromStream(ms, msFoundPositionA);
    WriteLn('');
    WriteLn('AMEM I2 loaded from position ' +
      IntToStr(msFoundPositionA));
  end
  else
  begin
    WriteLn('AMEM I2 not found, using INIT parameters');
    DXI2s.InitSupplBank;
  end;

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(PMEM802, ms, msSearchPosition, msFoundPositionV) then
  begin
    TX802.LoadPerfBankFromStream(ms, msFoundPositionV);
    WriteLn('');
    WriteLn('PMEM802 loaded from position ' +
      IntToStr(msFoundPositionV));
    if AVerbose then
      for i := 1 to 64 do
        WriteLn(TX802.GetPerformanceName(i));
  end;

  for i := 1 to 64 do
  begin
    MDX.InitPerformance;
    MDX.AllMIDIChToZero;
    DX7_VCED := TDX7VoiceContainer.Create;
    DX7II_ACED := TDX7IISupplementContainer.Create;
    TX802_PCED := TTX802PerformanceContainer.Create;
    for j := 1 to 8 do
      MDX_TG := TMDXSupplementContainer.Create;

    TX802.GetPerformance(i, TX802_PCED);
    sName := Format('%.6d', [i + ANumber]) + '_' +
      Trim(GetValidFileName(TX802.GetPerformanceName(i)));
    sName := copy(sName, 1, 21);

    MDX.FMDX_Params.General.Name := TX802.GetPerformanceName(i);
    MDX.FMDX_Params.General.Category := 'Converted';
    MDX.FMDX_Params.General.Origin := 'Conversion from TX802 Performances';

    Params := TX802_PCED.Get_PCED_Params;
    WriteLn('Performance: ' + TX802.GetPerformanceName(i));
    iVoice[1] := Params.VoiceNumber1;
    iVoice[2] := Params.VoiceNumber2;
    iVoice[3] := Params.VoiceNumber3;
    iVoice[4] := Params.VoiceNumber4;
    iVoice[5] := Params.VoiceNumber5;
    iVoice[6] := Params.VoiceNumber6;
    iVoice[7] := Params.VoiceNumber7;
    iVoice[8] := Params.VoiceNumber8;

    // 000 - 063 - Internal
    // 064 - 127 - Cartridge
    // 128 - 191 - Preset A
    // 192 - 255 - Preset B
    for j := 1 to 8 do
    begin
      if (iVoice[j] >= 0) and (iVoice[j] < 32) then
      begin
        //voice is from single bank file
        t := iVoice[j];
        iVoice[j] := iVoice[j] + 1;
        DXI1.GetVoice(iVoice[j], DX7_VCED);
        DXI1s.GetSupplement(iVoice[j], DX7II_ACED);
        perg := DX7II_ACED.Get_ACED_Params.Pitch_EG_Range;
        ams1 := DX7II_ACED.Get_ACED_Params.OP1_AM_Sensitivity;
        ams2 := DX7II_ACED.Get_ACED_Params.OP2_AM_Sensitivity;
        ams3 := DX7II_ACED.Get_ACED_Params.OP3_AM_Sensitivity;
        ams4 := DX7II_ACED.Get_ACED_Params.OP4_AM_Sensitivity;
        ams5 := DX7II_ACED.Get_ACED_Params.OP5_AM_Sensitivity;
        ams6 := DX7II_ACED.Get_ACED_Params.OP6_AM_Sensitivity;
        if GetSettingsFromFile(ASettings, AMS_table, PEGR_table) = True then
          DX7_VCED.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6, AMS_table, PEGR_table)
        else
          DX7_VCED.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6);
        MDX.LoadVoiceToTG(j, DX7_VCED.Get_VCED_Params);
        MDX_TG.Set_PCEDx_Params(LoadTX802toPCEDx(DX7II_ACED, TX802_PCED, j));
        MDX.LoadPCEDxToTG(j, MDX_TG.Get_PCEDx_Params);
        MDX.FMDX_Params.TG[j].BankNumberLSB := 1;
        WriteLn('Voice ' + IntToStr(j) + ' - Internal A:' + IntToStr(iVoice[j]) + '(' + IntToStr(t) + ') :' + DX7_VCED.GetVoiceName);
      end;
      if (iVoice[j] > 31) and (iVoice[j] < 64) then
      begin
        //voice is from bank A2
        t := iVoice[j];
        iVoice[j] := iVoice[j] - 31;
        DXI2.GetVoice(iVoice[j], DX7_VCED);
        DXI2s.GetSupplement(iVoice[j], DX7II_ACED);
        perg := DX7II_ACED.Get_ACED_Params.Pitch_EG_Range;
        ams1 := DX7II_ACED.Get_ACED_Params.OP1_AM_Sensitivity;
        ams2 := DX7II_ACED.Get_ACED_Params.OP2_AM_Sensitivity;
        ams3 := DX7II_ACED.Get_ACED_Params.OP3_AM_Sensitivity;
        ams4 := DX7II_ACED.Get_ACED_Params.OP4_AM_Sensitivity;
        ams5 := DX7II_ACED.Get_ACED_Params.OP5_AM_Sensitivity;
        ams6 := DX7II_ACED.Get_ACED_Params.OP6_AM_Sensitivity;
        if GetSettingsFromFile(ASettings, AMS_table, PEGR_table) = True then
          DX7_VCED.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6, AMS_table, PEGR_table)
        else
          DX7_VCED.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6);
        MDX.LoadVoiceToTG(j, DX7_VCED.Get_VCED_Params);
        MDX_TG.Set_PCEDx_Params(LoadTX802toPCEDx(DX7II_ACED, TX802_PCED, j));
        MDX.LoadPCEDxToTG(j, MDX_TG.Get_PCEDx_Params);
        MDX.FMDX_Params.TG[j].BankNumberLSB := 1;
        WriteLn('Voice ' + IntToStr(j) + ' - Internal B:' + IntToStr(iVoice[j]) + '(' + IntToStr(t) + ') :' + DX7_VCED.GetVoiceName);
      end;

      if (iVoice[j] > 127) and (iVoice[j] < 160) then
      begin
        //voice is from bank A1
        t := iVoice[j];
        iVoice[j] := iVoice[j] - 127;
        DXA1.GetVoice(iVoice[j], DX7_VCED);
        DXA1s.GetSupplement(iVoice[j], DX7II_ACED);
        perg := DX7II_ACED.Get_ACED_Params.Pitch_EG_Range;
        ams1 := DX7II_ACED.Get_ACED_Params.OP1_AM_Sensitivity;
        ams2 := DX7II_ACED.Get_ACED_Params.OP2_AM_Sensitivity;
        ams3 := DX7II_ACED.Get_ACED_Params.OP3_AM_Sensitivity;
        ams4 := DX7II_ACED.Get_ACED_Params.OP4_AM_Sensitivity;
        ams5 := DX7II_ACED.Get_ACED_Params.OP5_AM_Sensitivity;
        ams6 := DX7II_ACED.Get_ACED_Params.OP6_AM_Sensitivity;
        if GetSettingsFromFile(ASettings, AMS_table, PEGR_table) = True then
          DX7_VCED.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6, AMS_table, PEGR_table)
        else
          DX7_VCED.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6);
        MDX.LoadVoiceToTG(j, DX7_VCED.Get_VCED_Params);
        MDX_TG.Set_PCEDx_Params(LoadTX802toPCEDx(DX7II_ACED, TX802_PCED, j));
        MDX.LoadPCEDxToTG(j, MDX_TG.Get_PCEDx_Params);
        MDX.FMDX_Params.TG[j].BankNumberLSB := 1;
        WriteLn('Voice ' + IntToStr(j) + ' - Preset A1:' + IntToStr(iVoice[j]) + '(' + IntToStr(t) + ') :' + DX7_VCED.GetVoiceName);
      end;
      if (iVoice[j] > 159) and (iVoice[j] < 192) then
      begin
        //voice is from bank A2
        t := iVoice[j];
        iVoice[j] := iVoice[j] - 159;
        DXA2.GetVoice(iVoice[j], DX7_VCED);
        DXA2s.GetSupplement(iVoice[j], DX7II_ACED);
        perg := DX7II_ACED.Get_ACED_Params.Pitch_EG_Range;
        ams1 := DX7II_ACED.Get_ACED_Params.OP1_AM_Sensitivity;
        ams2 := DX7II_ACED.Get_ACED_Params.OP2_AM_Sensitivity;
        ams3 := DX7II_ACED.Get_ACED_Params.OP3_AM_Sensitivity;
        ams4 := DX7II_ACED.Get_ACED_Params.OP4_AM_Sensitivity;
        ams5 := DX7II_ACED.Get_ACED_Params.OP5_AM_Sensitivity;
        ams6 := DX7II_ACED.Get_ACED_Params.OP6_AM_Sensitivity;
        if GetSettingsFromFile(ASettings, AMS_table, PEGR_table) = True then
          DX7_VCED.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6, AMS_table, PEGR_table)
        else
          DX7_VCED.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6);
        MDX.LoadVoiceToTG(j, DX7_VCED.Get_VCED_Params);
        MDX_TG.Set_PCEDx_Params(LoadTX802toPCEDx(DX7II_ACED, TX802_PCED, j));
        MDX.LoadPCEDxToTG(j, MDX_TG.Get_PCEDx_Params);
        MDX.FMDX_Params.TG[j].BankNumberLSB := 1;
        WriteLn('Voice ' + IntToStr(j) + ' - Preset A2:' + IntToStr(iVoice[j]) + '(' + IntToStr(t) + ') :' + DX7_VCED.GetVoiceName);
      end;
      if (iVoice[j] > 191) and (iVoice[j] < 224) then
      begin
        //voice is from bank B1
        t := iVoice[j];
        iVoice[j] := iVoice[j] - 192;
        DXB1.GetVoice(iVoice[j], DX7_VCED);
        DXB1s.GetSupplement(iVoice[j], DX7II_ACED);
        perg := DX7II_ACED.Get_ACED_Params.Pitch_EG_Range;
        ams1 := DX7II_ACED.Get_ACED_Params.OP1_AM_Sensitivity;
        ams2 := DX7II_ACED.Get_ACED_Params.OP2_AM_Sensitivity;
        ams3 := DX7II_ACED.Get_ACED_Params.OP3_AM_Sensitivity;
        ams4 := DX7II_ACED.Get_ACED_Params.OP4_AM_Sensitivity;
        ams5 := DX7II_ACED.Get_ACED_Params.OP5_AM_Sensitivity;
        ams6 := DX7II_ACED.Get_ACED_Params.OP6_AM_Sensitivity;
        if GetSettingsFromFile(ASettings, AMS_table, PEGR_table) = True then
          DX7_VCED.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6, AMS_table, PEGR_table)
        else
          DX7_VCED.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6);
        MDX.LoadVoiceToTG(j, DX7_VCED.Get_VCED_Params);
        MDX_TG.Set_PCEDx_Params(LoadTX802toPCEDx(DX7II_ACED, TX802_PCED, j));
        MDX.LoadPCEDxToTG(j, MDX_TG.Get_PCEDx_Params);
        MDX.FMDX_Params.TG[j].BankNumberLSB := 1;
        WriteLn('Voice ' + IntToStr(j) + ' - Preset B1:' + IntToStr(iVoice[j]) + '(' + IntToStr(t) + ') :' + DX7_VCED.GetVoiceName);
      end;
      if (iVoice[j] > 223) and (iVoice[j] < 256) then
      begin
        //voice is from bank B2
        t := iVoice[j];
        iVoice[j] := iVoice[j] - 223;
        DXB2.GetVoice(iVoice[j], DX7_VCED);
        DXB2s.GetSupplement(iVoice[j], DX7II_ACED);
        perg := DX7II_ACED.Get_ACED_Params.Pitch_EG_Range;
        ams1 := DX7II_ACED.Get_ACED_Params.OP1_AM_Sensitivity;
        ams2 := DX7II_ACED.Get_ACED_Params.OP2_AM_Sensitivity;
        ams3 := DX7II_ACED.Get_ACED_Params.OP3_AM_Sensitivity;
        ams4 := DX7II_ACED.Get_ACED_Params.OP4_AM_Sensitivity;
        ams5 := DX7II_ACED.Get_ACED_Params.OP5_AM_Sensitivity;
        ams6 := DX7II_ACED.Get_ACED_Params.OP6_AM_Sensitivity;
        if GetSettingsFromFile(ASettings, AMS_table, PEGR_table) = True then
          DX7_VCED.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6, AMS_table, PEGR_table)
        else
          DX7_VCED.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6);
        MDX.LoadVoiceToTG(j, DX7_VCED.Get_VCED_Params);
        MDX_TG.Set_PCEDx_Params(LoadTX802toPCEDx(DX7II_ACED, TX802_PCED, j));
        MDX.LoadPCEDxToTG(j, MDX_TG.Get_PCEDx_Params);
        MDX.FMDX_Params.TG[j].BankNumberLSB := 1;
        WriteLn('Voice ' + IntToStr(j) + ' - Preset B2:' + IntToStr(iVoice[j]) + '(' + IntToStr(t) + ') :' + DX7_VCED.GetVoiceName);
      end;
      MDX.FMDX_Params.TG[j].VoiceNumber := iVoice[j];
      case j of
        1: MDX.FMDX_Params.TG[j].MIDIChannel := Params.RXChannel1 + 1;
        2: MDX.FMDX_Params.TG[j].MIDIChannel := Params.RXChannel2 + 1;
        3: MDX.FMDX_Params.TG[j].MIDIChannel := Params.RXChannel3 + 1;
        4: MDX.FMDX_Params.TG[j].MIDIChannel := Params.RXChannel4 + 1;
        5: MDX.FMDX_Params.TG[j].MIDIChannel := Params.RXChannel5 + 1;
        6: MDX.FMDX_Params.TG[j].MIDIChannel := Params.RXChannel6 + 1;
        7: MDX.FMDX_Params.TG[j].MIDIChannel := Params.RXChannel7 + 1;
        8: MDX.FMDX_Params.TG[j].MIDIChannel := Params.RXChannel8 + 1;
      end;

    end;
    //simulate linked channels
    if params.VoiceChannelOffset2 <> 1 then MDX.FMDX_Params.TG[2].MIDIChannel := 0;
    if params.VoiceChannelOffset3 <> 2 then MDX.FMDX_Params.TG[3].MIDIChannel := 0;
    if params.VoiceChannelOffset4 <> 3 then MDX.FMDX_Params.TG[4].MIDIChannel := 0;
    if params.VoiceChannelOffset5 <> 4 then MDX.FMDX_Params.TG[5].MIDIChannel := 0;
    if params.VoiceChannelOffset6 <> 5 then MDX.FMDX_Params.TG[6].MIDIChannel := 0;
    if params.VoiceChannelOffset7 <> 6 then MDX.FMDX_Params.TG[7].MIDIChannel := 0;
    if params.VoiceChannelOffset8 <> 7 then MDX.FMDX_Params.TG[8].MIDIChannel := 0;

    WriteLn('Writting ' + sName + '.ini');
    MDX.SavePerformanceToFile(IncludeTrailingPathDelimiter(APath) +
      sName + '.ini', False);

    DX7_VCED.Free;
    DX7II_ACED.Free;
    TX802_PCED.Free;
    MDX_TG.Free;
  end;

  DXI1.Free;
  DXI2.Free;
  DXI1s.Free;
  DXI2s.Free;
  DXA1.Free;
  DXA2.Free;
  DXB1.Free;
  DXB2.Free;
  DXA1s.Free;
  DXA2s.Free;
  DXB1s.Free;
  DXB2s.Free;
  TX802.Free;
  MDX.Free;
  msROM.Free;
end;

procedure ConvertBigDX7IItoMDX(var ms: TMemoryStream; APath: string; ANumber: integer; AVerbose: boolean; ASettings: string);
var
  msA: TMemoryStream;
  msB: TMemoryStream;
  msP: TMemoryStream;
  DXA: TDX7BankContainer;
  DXB: TDX7BankContainer;
  DXAs: TDX7IISupplBankContainer;
  DXBs: TDX7IISupplBankContainer;
  DX7II: TDX7IIPerfBankContainer;
  MDX: TMDXPerformanceContainer;

  DX7_VCED_A: TDX7VoiceContainer;
  DX7_VCED_B: TDX7VoiceContainer;
  DX7II_ACED_A: TDX7IISupplementContainer;
  DX7II_ACED_B: TDX7IISupplementContainer;
  DX7II_PCED: TDX7IIPerformanceContainer;
  MDX_TG1: TMDXSupplementContainer;
  MDX_TG2: TMDXSupplementContainer;

  Params: TDX7II_PCED_Params;
  iVoiceA: integer;
  iVoiceB: integer;

  msSearchPosition: integer;
  msFoundPosition: integer;

  i: integer;
  sName: string;

  perg, ams1, ams2, ams3, ams4, ams5, ams6: byte;
  AMS_table: TAMS;
  PEGR_table: TPEGR;
begin
  msFoundPosition := 0;

  msA := TMemoryStream.Create;
  msA.LoadFromStream(ms);
  msB := TMemoryStream.Create;
  msB.LoadFromStream(ms);
  msP := TMemoryStream.Create;
  msP.LoadFromStream(ms);

  DXA := TDX7BankContainer.Create;
  DXB := TDX7BankContainer.Create;
  DXAs := TDX7IISupplBankContainer.Create;
  DXBs := TDX7IISupplBankContainer.Create;
  DX7II := TDX7IIPerfBankContainer.Create;
  MDX := TMDXPerformanceContainer.Create;

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(VMEM, msA, msSearchPosition, msFoundPosition) then
  begin
    DXA.LoadBankFromStream(msA, msFoundPosition);
    WriteLn('');
    WriteLn('VMEM A loaded from ' + APath + ' from position ' +
      IntToStr(msFoundPosition));
    if AVerbose then
      for i := 1 to 32 do
        WriteLn(DXA.GetVoiceName(i));
  end;

  msSearchPosition := msFoundPosition;
  if FindDX_SixOP_MEM(VMEM, msB, msSearchPosition, msFoundPosition) then
  begin
    DXB.LoadBankFromStream(msB, msFoundPosition);
    WriteLn('');
    WriteLn('VMEM B loaded from ' + APath + ' from position ' +
      IntToStr(msFoundPosition));
    if AVerbose then
      for i := 1 to 32 do
        WriteLn(DXB.GetVoiceName(i));
  end
  else
  begin
    WriteLn('VMEM B not found, using INIT parameters');
    DXB.InitBank;
    msFoundPosition := 0;
  end;

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(AMEM, msA, msSearchPosition, msFoundPosition) then
  begin
    DXAs.LoadSupplBankFromStream(msA, msFoundPosition);
    WriteLn('');
    WriteLn('AMEM A loaded from ' + APath + ' from position ' +
      IntToStr(msFoundPosition));
  end
  else
  begin
    WriteLn('AMEM A not found, using INIT parameters');
    DXAs.InitSupplBank;
    msFoundPosition := 0;
  end;

  msSearchPosition := msFoundPosition;
  if FindDX_SixOP_MEM(AMEM, msB, msSearchPosition, msFoundPosition) then
  begin
    DXBs.LoadSupplBankFromStream(msB, msFoundPosition);
    WriteLn('');
    WriteLn('AMEM B loaded from ' + APath + ' from position ' +
      IntToStr(msFoundPosition));
  end
  else
  begin
    WriteLn('AMEM B not found, using INIT parameters');
    DXBs.InitSupplBank;
    msFoundPosition := 0;
  end;

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(LMPMEM, msP, msSearchPosition, msFoundPosition) then
  begin
    DX7II.LoadPerfBankFromStream(msP, msFoundPosition);
    WriteLn('');
    WriteLn('LM_PMEM loaded from ' + APath + ' from position ' +
      IntToStr(msFoundPosition));
    if AVerbose then
      for i := 1 to 32 do
        WriteLn(DX7II.GetPerformanceName(i));
  end;

  for i := 1 to 32 do
  begin
    MDX.InitPerformance;
    MDX.AllMIDIChToZero;
    DX7_VCED_A := TDX7VoiceContainer.Create;
    DX7_VCED_B := TDX7VoiceContainer.Create;
    DX7II_ACED_A := TDX7IISupplementContainer.Create;
    DX7II_ACED_B := TDX7IISupplementContainer.Create;
    DX7II_PCED := TDX7IIPerformanceContainer.Create;
    MDX_TG1 := TMDXSupplementContainer.Create;
    MDX_TG2 := TMDXSupplementContainer.Create;

    DX7II.GetPerformance(i, DX7II_PCED);
    sName := Format('%.6d', [i + ANumber]) + '_' +
      Trim(GetValidFileName(DX7II.GetPerformanceName(i)));
    sName := copy(sName, 1, 21);

    MDX.FMDX_Params.General.Name := DX7II.GetPerformanceName(i);
    MDX.FMDX_Params.General.Category := 'Converted';
    MDX.FMDX_Params.General.Origin := 'Conversion from DX7II Performances';

    Params := DX7II_PCED.Get_PCED_Params;
    iVoiceA := Params.VoiceANumber;
    iVoiceB := Params.VoiceBNumber;

    // 0 - 63 - Internal
    // 64-127 - Cartridge
    WriteLn('Voice A ' + IntToStr(iVoiceA) + ' ; ' + 'Voice B ' + IntToStr(iVoiceB));
    if iVoiceA < 64 then iVoiceA := iVoiceA + 1
    else
    if iVoiceA > 63 then iVoiceA := iVoiceA - 63;
    if iVoiceB < 64 then iVoiceB := iVoiceB + 1
    else
    if iVoiceB > 63 then iVoiceB := iVoiceB - 63;
    //WriteLn('Voice A* ' + IntToStr(iVoiceA) + ' ; ' + 'Voice B* ' + IntToStr(iVoiceB));

    if iVoiceA < 33 then
    begin
      WriteLn('1: Bank A, Voice ' + IntToStr(iVoiceA) + ' - ' + DXA.GetVoiceName(iVoiceA));
      DXA.GetVoice(iVoiceA, DX7_VCED_A);
      DXAs.GetSupplement(iVoiceA, DX7II_ACED_A);
      perg := DX7II_ACED_A.Get_ACED_Params.Pitch_EG_Range;
      ams1 := DX7II_ACED_A.Get_ACED_Params.OP1_AM_Sensitivity;
      ams2 := DX7II_ACED_A.Get_ACED_Params.OP2_AM_Sensitivity;
      ams3 := DX7II_ACED_A.Get_ACED_Params.OP3_AM_Sensitivity;
      ams4 := DX7II_ACED_A.Get_ACED_Params.OP4_AM_Sensitivity;
      ams5 := DX7II_ACED_A.Get_ACED_Params.OP5_AM_Sensitivity;
      ams6 := DX7II_ACED_A.Get_ACED_Params.OP6_AM_Sensitivity;
      if GetSettingsFromFile(ASettings, AMS_table, PEGR_table) = True then
        DX7_VCED_A.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6, AMS_table, PEGR_table)
      else
        DX7_VCED_A.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6);
    end
    else
    begin
      WriteLn('1: Bank B, Voice ' + IntToStr(iVoiceA - 32) + ' - ' + DXB.GetVoiceName(iVoiceA - 32));
      DXB.GetVoice(iVoiceA - 32, DX7_VCED_A);
      DXBs.GetSupplement(iVoiceA - 32, DX7II_ACED_A);
      perg := DX7II_ACED_A.Get_ACED_Params.Pitch_EG_Range;
      ams1 := DX7II_ACED_A.Get_ACED_Params.OP1_AM_Sensitivity;
      ams2 := DX7II_ACED_A.Get_ACED_Params.OP2_AM_Sensitivity;
      ams3 := DX7II_ACED_A.Get_ACED_Params.OP3_AM_Sensitivity;
      ams4 := DX7II_ACED_A.Get_ACED_Params.OP4_AM_Sensitivity;
      ams5 := DX7II_ACED_A.Get_ACED_Params.OP5_AM_Sensitivity;
      ams6 := DX7II_ACED_A.Get_ACED_Params.OP6_AM_Sensitivity;
      if GetSettingsFromFile(ASettings, AMS_table, PEGR_table) = True then
        DX7_VCED_A.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6, AMS_table, PEGR_table)
      else
        DX7_VCED_A.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6);
    end;
    MDX.LoadVoiceToTG(1, DX7_VCED_A.Get_VCED_Params);
    MDX_TG1.Set_PCEDx_Params(LoadDX7IIACEDPCEDtoPCEDx(True, DX7II_ACED_A, DX7II_PCED));
    MDX.LoadPCEDxToTG(1, MDX_TG1.Get_PCEDx_Params);
    if iVoiceA < 33 then
    begin
      MDX.FMDX_Params.TG[1].BankNumberLSB := 1;
      MDX.FMDX_Params.TG[1].VoiceNumber := iVoiceA;
    end
    else
    begin
      MDX.FMDX_Params.TG[1].BankNumberLSB := 2;
      MDX.FMDX_Params.TG[1].VoiceNumber := iVoiceA - 32;
    end;
    MDX.FMDX_Params.TG[1].MIDIChannel := 1;

    if Params.PerformanceLayerMode <> 0 then
    begin
      if iVoiceB < 33 then
      begin
        WriteLn('2: Bank A, Voice ' + IntToStr(iVoiceB) + ' - ' + DXA.GetVoiceName(iVoiceB));
        DXA.GetVoice(iVoiceB, DX7_VCED_B);
        DXAs.GetSupplement(iVoiceB, DX7II_ACED_B);
        perg := DX7II_ACED_B.Get_ACED_Params.Pitch_EG_Range;
        ams1 := DX7II_ACED_B.Get_ACED_Params.OP1_AM_Sensitivity;
        ams2 := DX7II_ACED_B.Get_ACED_Params.OP2_AM_Sensitivity;
        ams3 := DX7II_ACED_B.Get_ACED_Params.OP3_AM_Sensitivity;
        ams4 := DX7II_ACED_B.Get_ACED_Params.OP4_AM_Sensitivity;
        ams5 := DX7II_ACED_B.Get_ACED_Params.OP5_AM_Sensitivity;
        ams6 := DX7II_ACED_B.Get_ACED_Params.OP6_AM_Sensitivity;
        if GetSettingsFromFile(ASettings, AMS_table, PEGR_table) = True then
          DX7_VCED_B.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6, AMS_table, PEGR_table)
        else
          DX7_VCED_B.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6);
      end
      else
      begin
        WriteLn('2: Bank B, Voice ' + IntToStr(iVoiceB - 32) + ' - ' + DXB.GetVoiceName(iVoiceB - 32));
        DXB.GetVoice(iVoiceB - 32, DX7_VCED_B);
        DXBs.GetSupplement(iVoiceB - 32, DX7II_ACED_B);
        perg := DX7II_ACED_B.Get_ACED_Params.Pitch_EG_Range;
        ams1 := DX7II_ACED_B.Get_ACED_Params.OP1_AM_Sensitivity;
        ams2 := DX7II_ACED_B.Get_ACED_Params.OP2_AM_Sensitivity;
        ams3 := DX7II_ACED_B.Get_ACED_Params.OP3_AM_Sensitivity;
        ams4 := DX7II_ACED_B.Get_ACED_Params.OP4_AM_Sensitivity;
        ams5 := DX7II_ACED_B.Get_ACED_Params.OP5_AM_Sensitivity;
        ams6 := DX7II_ACED_B.Get_ACED_Params.OP6_AM_Sensitivity;
        if GetSettingsFromFile(ASettings, AMS_table, PEGR_table) = True then
          DX7_VCED_B.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6, AMS_table, PEGR_table)
        else
          DX7_VCED_B.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6);
      end;
      MDX.LoadVoiceToTG(2, DX7_VCED_B.Get_VCED_Params);
      MDX_TG2.Set_PCEDx_Params(LoadDX7IIACEDPCEDtoPCEDx(False,
        DX7II_ACED_B, DX7II_PCED));
      MDX.LoadPCEDxToTG(2, MDX_TG2.Get_PCEDx_Params);
      if iVoiceB < 33 then
      begin
        MDX.FMDX_Params.TG[2].BankNumberLSB := 1;
        MDX.FMDX_Params.TG[2].VoiceNumber := iVoiceB;
      end
      else
      begin
        MDX.FMDX_Params.TG[2].BankNumberLSB := 2;
        MDX.FMDX_Params.TG[2].VoiceNumber := iVoiceB - 32;
      end;
      MDX.FMDX_Params.TG[2].MIDIChannel := 1;

    end;

    WriteLn('Writting ' + sName + '.ini');
    MDX.SavePerformanceToFile(IncludeTrailingPathDelimiter(APath) +
      sName + '.ini', False);
    WriteLn('=================================');
    DX7_VCED_A.Free;
    DX7_VCED_B.Free;
    DX7II_ACED_A.Free;
    DX7II_ACED_B.Free;
    DX7II_PCED.Free;
    MDX_TG1.Free;
    MDX_TG2.Free;
  end;

  msA.Free;
  msB.Free;
  msP.Free;
  DXA.Free;
  DXB.Free;
  DXAs.Free;
  DXBs.Free;
  DX7II.Free;
  MDX.Free;
end;

procedure Convert2BigDX7IItoMDX(var msA1, msB1: TMemoryStream; APath: string; ANumber: integer; AVerbose: boolean; ASettings: string);
var
  msA: TMemoryStream;
  msB: TMemoryStream;
  DXA32: TDX7BankContainer;
  DXA64: TDX7BankContainer;
  DXB32: TDX7BankContainer;
  DXB64: TDX7BankContainer;
  DXA32s: TDX7IISupplBankContainer;
  DXA64s: TDX7IISupplBankContainer;
  DXB32s: TDX7IISupplBankContainer;
  DXB64s: TDX7IISupplBankContainer;
  DX7IIA: TDX7IIPerfBankContainer;
  DX7IIB: TDX7IIPerfBankContainer;
  MDX: TMDXPerformanceContainer;

  DX7_VCED_A: TDX7VoiceContainer;
  DX7_VCED_B: TDX7VoiceContainer;
  DX7II_ACED_A: TDX7IISupplementContainer;
  DX7II_ACED_B: TDX7IISupplementContainer;
  DX7II_PCED: TDX7IIPerformanceContainer;
  MDX_TG1: TMDXSupplementContainer;
  MDX_TG2: TMDXSupplementContainer;

  Params: TDX7II_PCED_Params;
  iVoiceA: integer;
  iVoiceB: integer;

  msSearchPosition: integer;
  msFoundPosition: integer;

  i: integer;
  sName: string;

  perg, ams1, ams2, ams3, ams4, ams5, ams6: byte;
  AMS_table: TAMS;
  PEGR_table: TPEGR;
begin
  msFoundPosition := 0;

  msA := TMemoryStream.Create;
  msA.LoadFromStream(msA1);
  msB := TMemoryStream.Create;
  msB.LoadFromStream(msB1);

  DXA32 := TDX7BankContainer.Create;
  DXA64 := TDX7BankContainer.Create;
  DXB32 := TDX7BankContainer.Create;
  DXB64 := TDX7BankContainer.Create;
  DXA32s := TDX7IISupplBankContainer.Create;
  DXA64s := TDX7IISupplBankContainer.Create;
  DXB32s := TDX7IISupplBankContainer.Create;
  DXB64s := TDX7IISupplBankContainer.Create;
  DX7IIA := TDX7IIPerfBankContainer.Create;
  DX7IIB := TDX7IIPerfBankContainer.Create;
  MDX := TMDXPerformanceContainer.Create;

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(VMEM, msA, msSearchPosition, msFoundPosition) then
  begin
    DXA32.LoadBankFromStream(msA, msFoundPosition);
    WriteLn('');
    WriteLn('VMEM A 01-32 loaded from file A, from position ' +
      IntToStr(msFoundPosition));
    if AVerbose then
      for i := 1 to 32 do
        WriteLn(DXA32.GetVoiceName(i));
  end;

  msSearchPosition := msFoundPosition;
  if FindDX_SixOP_MEM(VMEM, msA, msSearchPosition, msFoundPosition) then
  begin
    DXA64.LoadBankFromStream(msA, msFoundPosition);
    WriteLn('');
    WriteLn('VMEM A 33-64 loaded from file A, from position ' +
      IntToStr(msFoundPosition));
    if AVerbose then
      for i := 1 to 32 do
        WriteLn(DXA64.GetVoiceName(i));
  end
  else
  begin
    WriteLn('VMEM A 33-64 not found, using INIT parameters');
    DXA64.InitBank;
  end;

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(AMEM, msA, msSearchPosition, msFoundPosition) then
  begin
    DXA32s.LoadSupplBankFromStream(msA, msFoundPosition);
    WriteLn('');
    WriteLn('AMEM A 01-32 loaded from file A, from position ' +
      IntToStr(msFoundPosition));
  end
  else
  begin
    WriteLn('AMEM A 01-32 not found, using INIT parameters');
    DXA32s.InitSupplBank;
  end;

  msSearchPosition := msFoundPosition;
  if FindDX_SixOP_MEM(AMEM, msA, msSearchPosition, msFoundPosition) then
  begin
    DXA64s.LoadSupplBankFromStream(msA, msFoundPosition);
    WriteLn('');
    WriteLn('AMEM A 33-64 loaded from file A from position ' +
      IntToStr(msFoundPosition));
  end
  else
  begin
    WriteLn('AMEM A 33-64 not found, using INIT parameters');
    DXA64s.InitSupplBank;
  end;

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(LMPMEM, msA, msSearchPosition, msFoundPosition) then
  begin
    DX7IIA.LoadPerfBankFromStream(msA, msFoundPosition);
    WriteLn('');
    WriteLn('LM_PMEM loaded from file A, from position ' +
      IntToStr(msFoundPosition));
    if AVerbose then
      for i := 1 to 32 do
        WriteLn(DX7IIA.GetPerformanceName(i));
  end;

  //=================== Bank B =====================

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(VMEM, msB, msSearchPosition, msFoundPosition) then
  begin
    DXB32.LoadBankFromStream(msB, msFoundPosition);
    WriteLn('');
    WriteLn('VMEM B 01-32 loaded from file B, from position ' +
      IntToStr(msFoundPosition));
    if AVerbose then
      for i := 1 to 32 do
        WriteLn(DXB32.GetVoiceName(i));
  end;

  msSearchPosition := msFoundPosition;
  if FindDX_SixOP_MEM(VMEM, msB, msSearchPosition, msFoundPosition) then
  begin
    DXB64.LoadBankFromStream(msB, msFoundPosition);
    WriteLn('');
    WriteLn('VMEM B 33-64 loaded from file B, from position ' +
      IntToStr(msFoundPosition));
    if AVerbose then
      for i := 1 to 32 do
        WriteLn(DXB64.GetVoiceName(i));
  end
  else
  begin
    WriteLn('VMEM B 33-64 not found, using INIT parameters');
    DXB64.InitBank;
  end;

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(AMEM, msB, msSearchPosition, msFoundPosition) then
  begin
    DXB32s.LoadSupplBankFromStream(msB, msFoundPosition);
    WriteLn('');
    WriteLn('AMEM B 01-32 loaded from file B, from position ' +
      IntToStr(msFoundPosition));
  end
  else
  begin
    WriteLn('AMEM B 01-32 not found, using INIT parameters');
    DXB32s.InitSupplBank;
  end;

  msSearchPosition := msFoundPosition;
  if FindDX_SixOP_MEM(AMEM, msB, msSearchPosition, msFoundPosition) then
  begin
    DXB64s.LoadSupplBankFromStream(msB, msFoundPosition);
    WriteLn('');
    WriteLn('AMEM B 33-64 loaded from file B, from position ' +
      IntToStr(msFoundPosition));
  end
  else
  begin
    WriteLn('AMEM B 33-64 not found, using INIT parameters');
    DXB64s.InitSupplBank;
  end;

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(LMPMEM, msB, msSearchPosition, msFoundPosition) then
  begin
    DX7IIB.LoadPerfBankFromStream(msB, msFoundPosition);
    WriteLn('');
    WriteLn('LM_PMEM loaded from file B, from position ' +
      IntToStr(msFoundPosition));
    if AVerbose then
      for i := 1 to 32 do
        WriteLn(DX7IIB.GetPerformanceName(i));
  end;

  //================== Performance A ======================
  for i := 1 to 32 do
  begin
    MDX.InitPerformance;
    MDX.AllMIDIChToZero;
    DX7_VCED_A := TDX7VoiceContainer.Create;
    DX7_VCED_B := TDX7VoiceContainer.Create;
    DX7II_ACED_A := TDX7IISupplementContainer.Create;
    DX7II_ACED_B := TDX7IISupplementContainer.Create;
    DX7II_PCED := TDX7IIPerformanceContainer.Create;
    MDX_TG1 := TMDXSupplementContainer.Create;
    MDX_TG2 := TMDXSupplementContainer.Create;

    DX7IIA.GetPerformance(i, DX7II_PCED);
    sName := Format('%.6d', [i + ANumber]) + '_' +
      Trim(GetValidFileName(DX7IIA.GetPerformanceName(i)));
    sName := copy(sName, 1, 21);

    MDX.FMDX_Params.General.Name := DX7IIA.GetPerformanceName(i);
    MDX.FMDX_Params.General.Category := 'Converted';
    MDX.FMDX_Params.General.Origin := 'Conversion from DX7II Performances';

    Params := DX7II_PCED.Get_PCED_Params;
    iVoiceA := Params.VoiceANumber;
    iVoiceB := Params.VoiceBNumber;

    // 000 - 063 - Internal
    // 064 - 127 - Cartridge
    WriteLn('Voice A ' + IntToStr(iVoiceA) + ' ; ' + 'Voice B ' + IntToStr(iVoiceB));

    if iVoiceA < 32 then
    begin
      WriteLn('1: Bank A1, Voice ' + IntToStr(iVoiceA + 1) + ' - ' + DXA32.GetVoiceName(iVoiceA + 1));
      DXA32.GetVoice(iVoiceA + 1, DX7_VCED_A);
      DXA32s.GetSupplement(iVoiceA + 1, DX7II_ACED_A);
    end;
    if (iVoiceA > 31) and (iVoiceA < 64) then
    begin
      WriteLn('1: Bank A2, Voice ' + IntToStr(iVoiceA - 31) + ' - ' + DXA64.GetVoiceName(iVoiceA - 31));
      DXA64.GetVoice(iVoiceA - 31, DX7_VCED_A);
      DXA64s.GetSupplement(iVoiceA - 31, DX7II_ACED_A);
    end;
    if (iVoiceA > 63) and (iVoiceA < 96) then
    begin
      WriteLn('1: Bank B1, Voice ' + IntToStr(iVoiceA - 63) + ' - ' + DXB32.GetVoiceName(iVoiceA - 63));
      DXB32.GetVoice(iVoiceA - 63, DX7_VCED_A);
      DXB32s.GetSupplement(iVoiceA - 63, DX7II_ACED_A);
    end;
    if (iVoiceA > 95) and (iVoiceA < 128) then
    begin
      WriteLn('1: Bank B2, Voice ' + IntToStr(iVoiceA - 95) + ' - ' + DXB64.GetVoiceName(iVoiceA - 95));
      DXB64.GetVoice(iVoiceA - 95, DX7_VCED_A);
      DXB64s.GetSupplement(iVoiceA - 95, DX7II_ACED_A);
    end;

    MDX.LoadVoiceToTG(1, DX7_VCED_A.Get_VCED_Params);
    MDX_TG1.Set_PCEDx_Params(LoadDX7IIACEDPCEDtoPCEDx(True, DX7II_ACED_A, DX7II_PCED));
    MDX.LoadPCEDxToTG(1, MDX_TG1.Get_PCEDx_Params);
    if iVoiceA < 33 then
    begin
      MDX.FMDX_Params.TG[1].BankNumberLSB := 1;
      MDX.FMDX_Params.TG[1].VoiceNumber := iVoiceA;
    end
    else
    begin
      MDX.FMDX_Params.TG[1].BankNumberLSB := 2;
      MDX.FMDX_Params.TG[1].VoiceNumber := iVoiceA - 32;
    end;
    MDX.FMDX_Params.TG[1].MIDIChannel := 1;

    if Params.PerformanceLayerMode <> 0 then
    begin
      if iVoiceB < 32 then
      begin
        WriteLn('2: Bank A1, Voice ' + IntToStr(iVoiceB + 1) + ' - ' + DXA32.GetVoiceName(iVoiceB + 1));
        DXA32.GetVoice(iVoiceB + 1, DX7_VCED_B);
        DXA32s.GetSupplement(iVoiceB + 1, DX7II_ACED_A);
      end;
      if (iVoiceB > 31) and (iVoiceB < 64) then
      begin
        WriteLn('2: Bank A2, Voice ' + IntToStr(iVoiceB - 31) + ' - ' + DXA64.GetVoiceName(iVoiceB - 31));
        DXA64.GetVoice(iVoiceB - 31, DX7_VCED_B);
        DXA64s.GetSupplement(iVoiceB - 31, DX7II_ACED_A);
      end;
      if (iVoiceB > 63) and (iVoiceB < 96) then
      begin
        WriteLn('2: Bank B1, Voice ' + IntToStr(iVoiceB - 63) + ' - ' + DXB32.GetVoiceName(iVoiceB - 63));
        DXB32.GetVoice(iVoiceB - 63, DX7_VCED_B);
        DXB32s.GetSupplement(iVoiceB - 63, DX7II_ACED_A);
      end;
      if (iVoiceB > 95) and (iVoiceB < 128) then
      begin
        WriteLn('2: Bank B2, Voice ' + IntToStr(iVoiceB - 95) + ' - ' + DXB64.GetVoiceName(iVoiceB - 95));
        DXB64.GetVoice(iVoiceB - 95, DX7_VCED_B);
        DXB64s.GetSupplement(iVoiceB - 95, DX7II_ACED_A);
      end;

      MDX.LoadVoiceToTG(2, DX7_VCED_B.Get_VCED_Params);
      MDX_TG2.Set_PCEDx_Params(LoadDX7IIACEDPCEDtoPCEDx(False,
        DX7II_ACED_B, DX7II_PCED));
      MDX.LoadPCEDxToTG(2, MDX_TG2.Get_PCEDx_Params);
      if iVoiceB < 33 then
      begin
        MDX.FMDX_Params.TG[2].BankNumberLSB := 1;
        MDX.FMDX_Params.TG[2].VoiceNumber := iVoiceB;
      end
      else
      begin
        MDX.FMDX_Params.TG[2].BankNumberLSB := 2;
        MDX.FMDX_Params.TG[2].VoiceNumber := iVoiceB - 32;
      end;
      MDX.FMDX_Params.TG[2].MIDIChannel := 1;

    end;

    WriteLn('Writting ' + sName + '.ini');
    MDX.SavePerformanceToFile(IncludeTrailingPathDelimiter(APath) +
      sName + '.ini', False);
    WriteLn('=================================');
    DX7_VCED_A.Free;
    DX7_VCED_B.Free;
    DX7II_ACED_A.Free;
    DX7II_ACED_B.Free;
    DX7II_PCED.Free;
    MDX_TG1.Free;
    MDX_TG2.Free;
  end;

  //================== Performance B ======================
  for i := 1 to 32 do
  begin
    MDX.InitPerformance;
    MDX.AllMIDIChToZero;
    DX7_VCED_A := TDX7VoiceContainer.Create;
    DX7_VCED_B := TDX7VoiceContainer.Create;
    DX7II_ACED_A := TDX7IISupplementContainer.Create;
    DX7II_ACED_B := TDX7IISupplementContainer.Create;
    DX7II_PCED := TDX7IIPerformanceContainer.Create;
    MDX_TG1 := TMDXSupplementContainer.Create;
    MDX_TG2 := TMDXSupplementContainer.Create;

    DX7IIB.GetPerformance(i, DX7II_PCED);
    sName := Format('%.6d', [i + ANumber + 32]) + '_' +
      Trim(GetValidFileName(DX7IIB.GetPerformanceName(i)));
    sName := copy(sName, 1, 21);

    MDX.FMDX_Params.General.Name := DX7IIB.GetPerformanceName(i);
    MDX.FMDX_Params.General.Category := 'Converted';
    MDX.FMDX_Params.General.Origin := 'Conversion from DX7II Performances';

    Params := DX7II_PCED.Get_PCED_Params;
    iVoiceA := Params.VoiceANumber;
    iVoiceB := Params.VoiceBNumber;

    // 0 - 63 - Internal
    // 64-127 - Cartridge
    WriteLn('Voice A ' + IntToStr(iVoiceA) + ' ; ' + 'Voice B ' + IntToStr(iVoiceB));

    if iVoiceA < 32 then
    begin
      WriteLn('1: Bank A1, Voice ' + IntToStr(iVoiceA + 1) + ' - ' + DXA32.GetVoiceName(iVoiceA + 1));
      DXA32.GetVoice(iVoiceA + 1, DX7_VCED_A);
      DXA32s.GetSupplement(iVoiceA + 1, DX7II_ACED_A);
      perg := DX7II_ACED_A.Get_ACED_Params.Pitch_EG_Range;
      ams1 := DX7II_ACED_A.Get_ACED_Params.OP1_AM_Sensitivity;
      ams2 := DX7II_ACED_A.Get_ACED_Params.OP2_AM_Sensitivity;
      ams3 := DX7II_ACED_A.Get_ACED_Params.OP3_AM_Sensitivity;
      ams4 := DX7II_ACED_A.Get_ACED_Params.OP4_AM_Sensitivity;
      ams5 := DX7II_ACED_A.Get_ACED_Params.OP5_AM_Sensitivity;
      ams6 := DX7II_ACED_A.Get_ACED_Params.OP6_AM_Sensitivity;
      if GetSettingsFromFile(ASettings, AMS_table, PEGR_table) = True then
        DX7_VCED_A.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6, AMS_table, PEGR_table)
      else
        DX7_VCED_A.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6);
    end;
    if (iVoiceA > 31) and (iVoiceA < 64) then
    begin
      WriteLn('1: Bank A2, Voice ' + IntToStr(iVoiceA - 31) + ' - ' + DXA64.GetVoiceName(iVoiceA - 31));
      DXA64.GetVoice(iVoiceA - 31, DX7_VCED_A);
      DXA64s.GetSupplement(iVoiceA - 31, DX7II_ACED_A);
      perg := DX7II_ACED_A.Get_ACED_Params.Pitch_EG_Range;
      ams1 := DX7II_ACED_A.Get_ACED_Params.OP1_AM_Sensitivity;
      ams2 := DX7II_ACED_A.Get_ACED_Params.OP2_AM_Sensitivity;
      ams3 := DX7II_ACED_A.Get_ACED_Params.OP3_AM_Sensitivity;
      ams4 := DX7II_ACED_A.Get_ACED_Params.OP4_AM_Sensitivity;
      ams5 := DX7II_ACED_A.Get_ACED_Params.OP5_AM_Sensitivity;
      ams6 := DX7II_ACED_A.Get_ACED_Params.OP6_AM_Sensitivity;
      if GetSettingsFromFile(ASettings, AMS_table, PEGR_table) = True then
        DX7_VCED_A.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6, AMS_table, PEGR_table)
      else
        DX7_VCED_A.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6);
    end;
    if (iVoiceA > 63) and (iVoiceA < 96) then
    begin
      WriteLn('1: Bank B1, Voice ' + IntToStr(iVoiceA - 63) + ' - ' + DXB32.GetVoiceName(iVoiceA - 63));
      DXB32.GetVoice(iVoiceA - 63, DX7_VCED_A);
      DXB32s.GetSupplement(iVoiceA - 63, DX7II_ACED_A);
      perg := DX7II_ACED_A.Get_ACED_Params.Pitch_EG_Range;
      ams1 := DX7II_ACED_A.Get_ACED_Params.OP1_AM_Sensitivity;
      ams2 := DX7II_ACED_A.Get_ACED_Params.OP2_AM_Sensitivity;
      ams3 := DX7II_ACED_A.Get_ACED_Params.OP3_AM_Sensitivity;
      ams4 := DX7II_ACED_A.Get_ACED_Params.OP4_AM_Sensitivity;
      ams5 := DX7II_ACED_A.Get_ACED_Params.OP5_AM_Sensitivity;
      ams6 := DX7II_ACED_A.Get_ACED_Params.OP6_AM_Sensitivity;
      if GetSettingsFromFile(ASettings, AMS_table, PEGR_table) = True then
        DX7_VCED_A.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6, AMS_table, PEGR_table)
      else
        DX7_VCED_A.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6);
    end;
    if (iVoiceA > 95) and (iVoiceA < 128) then
    begin
      WriteLn('1: Bank B2, Voice ' + IntToStr(iVoiceA - 95) + ' - ' + DXB64.GetVoiceName(iVoiceA - 95));
      DXB64.GetVoice(iVoiceA - 95, DX7_VCED_A);
      DXB64s.GetSupplement(iVoiceA - 95, DX7II_ACED_A);
      perg := DX7II_ACED_A.Get_ACED_Params.Pitch_EG_Range;
      ams1 := DX7II_ACED_A.Get_ACED_Params.OP1_AM_Sensitivity;
      ams2 := DX7II_ACED_A.Get_ACED_Params.OP2_AM_Sensitivity;
      ams3 := DX7II_ACED_A.Get_ACED_Params.OP3_AM_Sensitivity;
      ams4 := DX7II_ACED_A.Get_ACED_Params.OP4_AM_Sensitivity;
      ams5 := DX7II_ACED_A.Get_ACED_Params.OP5_AM_Sensitivity;
      ams6 := DX7II_ACED_A.Get_ACED_Params.OP6_AM_Sensitivity;
      if GetSettingsFromFile(ASettings, AMS_table, PEGR_table) = True then
        DX7_VCED_A.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6, AMS_table, PEGR_table)
      else
        DX7_VCED_A.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6);
    end;

    MDX.LoadVoiceToTG(1, DX7_VCED_A.Get_VCED_Params);
    MDX_TG1.Set_PCEDx_Params(LoadDX7IIACEDPCEDtoPCEDx(True, DX7II_ACED_A, DX7II_PCED));
    MDX.LoadPCEDxToTG(1, MDX_TG1.Get_PCEDx_Params);
    if iVoiceA < 33 then
    begin
      MDX.FMDX_Params.TG[1].BankNumberLSB := 1;
      MDX.FMDX_Params.TG[1].VoiceNumber := iVoiceA;
    end
    else
    begin
      MDX.FMDX_Params.TG[1].BankNumberLSB := 2;
      MDX.FMDX_Params.TG[1].VoiceNumber := iVoiceA - 32;
    end;
    MDX.FMDX_Params.TG[1].MIDIChannel := 1;

    if Params.PerformanceLayerMode <> 0 then
    begin
      if iVoiceB < 32 then
      begin
        WriteLn('2: Bank A1, Voice ' + IntToStr(iVoiceB + 1) + ' - ' + DXA32.GetVoiceName(iVoiceB + 1));
        DXA32.GetVoice(iVoiceB + 1, DX7_VCED_B);
        DXA32s.GetSupplement(iVoiceB + 1, DX7II_ACED_B);
        perg := DX7II_ACED_B.Get_ACED_Params.Pitch_EG_Range;
        ams1 := DX7II_ACED_B.Get_ACED_Params.OP1_AM_Sensitivity;
        ams2 := DX7II_ACED_B.Get_ACED_Params.OP2_AM_Sensitivity;
        ams3 := DX7II_ACED_B.Get_ACED_Params.OP3_AM_Sensitivity;
        ams4 := DX7II_ACED_B.Get_ACED_Params.OP4_AM_Sensitivity;
        ams5 := DX7II_ACED_B.Get_ACED_Params.OP5_AM_Sensitivity;
        ams6 := DX7II_ACED_B.Get_ACED_Params.OP6_AM_Sensitivity;
        if GetSettingsFromFile(ASettings, AMS_table, PEGR_table) = True then
          DX7_VCED_B.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6, AMS_table, PEGR_table)
        else
          DX7_VCED_B.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6);
      end;
      if (iVoiceB > 31) and (iVoiceB < 64) then
      begin
        WriteLn('2: Bank A2, Voice ' + IntToStr(iVoiceB - 31) + ' - ' + DXA64.GetVoiceName(iVoiceB - 31));
        DXA64.GetVoice(iVoiceB - 31, DX7_VCED_B);
        DXA64s.GetSupplement(iVoiceB - 31, DX7II_ACED_B);
        perg := DX7II_ACED_B.Get_ACED_Params.Pitch_EG_Range;
        ams1 := DX7II_ACED_B.Get_ACED_Params.OP1_AM_Sensitivity;
        ams2 := DX7II_ACED_B.Get_ACED_Params.OP2_AM_Sensitivity;
        ams3 := DX7II_ACED_B.Get_ACED_Params.OP3_AM_Sensitivity;
        ams4 := DX7II_ACED_B.Get_ACED_Params.OP4_AM_Sensitivity;
        ams5 := DX7II_ACED_B.Get_ACED_Params.OP5_AM_Sensitivity;
        ams6 := DX7II_ACED_B.Get_ACED_Params.OP6_AM_Sensitivity;
        if GetSettingsFromFile(ASettings, AMS_table, PEGR_table) = True then
          DX7_VCED_B.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6, AMS_table, PEGR_table)
        else
          DX7_VCED_B.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6);
      end;
      if (iVoiceB > 63) and (iVoiceB < 96) then
      begin
        WriteLn('2: Bank B1, Voice ' + IntToStr(iVoiceB - 63) + ' - ' + DXB32.GetVoiceName(iVoiceB - 63));
        DXB32.GetVoice(iVoiceB - 63, DX7_VCED_B);
        DXB32s.GetSupplement(iVoiceB - 63, DX7II_ACED_B);
        perg := DX7II_ACED_B.Get_ACED_Params.Pitch_EG_Range;
        ams1 := DX7II_ACED_B.Get_ACED_Params.OP1_AM_Sensitivity;
        ams2 := DX7II_ACED_B.Get_ACED_Params.OP2_AM_Sensitivity;
        ams3 := DX7II_ACED_B.Get_ACED_Params.OP3_AM_Sensitivity;
        ams4 := DX7II_ACED_B.Get_ACED_Params.OP4_AM_Sensitivity;
        ams5 := DX7II_ACED_B.Get_ACED_Params.OP5_AM_Sensitivity;
        ams6 := DX7II_ACED_B.Get_ACED_Params.OP6_AM_Sensitivity;
        if GetSettingsFromFile(ASettings, AMS_table, PEGR_table) = True then
          DX7_VCED_B.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6, AMS_table, PEGR_table)
        else
          DX7_VCED_B.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6);
      end;
      if (iVoiceB > 95) and (iVoiceB < 128) then
      begin
        WriteLn('2: Bank B2, Voice ' + IntToStr(iVoiceB - 95) + ' - ' + DXB64.GetVoiceName(iVoiceB - 95));
        DXB64.GetVoice(iVoiceB - 95, DX7_VCED_B);
        DXB64s.GetSupplement(iVoiceB - 95, DX7II_ACED_B);
        perg := DX7II_ACED_B.Get_ACED_Params.Pitch_EG_Range;
        ams1 := DX7II_ACED_B.Get_ACED_Params.OP1_AM_Sensitivity;
        ams2 := DX7II_ACED_B.Get_ACED_Params.OP2_AM_Sensitivity;
        ams3 := DX7II_ACED_B.Get_ACED_Params.OP3_AM_Sensitivity;
        ams4 := DX7II_ACED_B.Get_ACED_Params.OP4_AM_Sensitivity;
        ams5 := DX7II_ACED_B.Get_ACED_Params.OP5_AM_Sensitivity;
        ams6 := DX7II_ACED_B.Get_ACED_Params.OP6_AM_Sensitivity;
        if GetSettingsFromFile(ASettings, AMS_table, PEGR_table) = True then
          DX7_VCED_B.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6, AMS_table, PEGR_table)
        else
          DX7_VCED_B.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6);
      end;

      MDX.LoadVoiceToTG(2, DX7_VCED_B.Get_VCED_Params);
      MDX_TG2.Set_PCEDx_Params(LoadDX7IIACEDPCEDtoPCEDx(False,
        DX7II_ACED_B, DX7II_PCED));
      MDX.LoadPCEDxToTG(2, MDX_TG2.Get_PCEDx_Params);
      if iVoiceB < 33 then
      begin
        MDX.FMDX_Params.TG[2].BankNumberLSB := 1;
        MDX.FMDX_Params.TG[2].VoiceNumber := iVoiceB;
      end
      else
      begin
        MDX.FMDX_Params.TG[2].BankNumberLSB := 2;
        MDX.FMDX_Params.TG[2].VoiceNumber := iVoiceB - 32;
      end;
      MDX.FMDX_Params.TG[2].MIDIChannel := 1;
    end;

    WriteLn('Writting ' + sName + '.ini');
    MDX.SavePerformanceToFile(IncludeTrailingPathDelimiter(APath) +
      sName + '.ini', False);
    WriteLn('=================================');
    DX7_VCED_A.Free;
    DX7_VCED_B.Free;
    DX7II_ACED_A.Free;
    DX7II_ACED_B.Free;
    DX7II_PCED.Free;
    MDX_TG1.Free;
    MDX_TG2.Free;
  end;

  msA.Free;
  msB.Free;
  DXA32.Free;
  DXA64.Free;
  DXB32.Free;
  DXB64.Free;
  DXA32s.Free;
  DXB32s.Free;
  DXA64s.Free;
  DXB64s.Free;
  DX7IIA.Free;
  DX7IIB.Free;
  MDX.Free;
end;

function GetSettingsFromFile(ASettings: string; var aAMS_table: TAMS; var aPEGR_table: TPEGR): boolean;
var
  ini: TIniFile;
begin
  if FileExists(ASettings) then
  begin
    try
      try
        ini := TIniFile.Create(ASettings);
        aAMS_Table[0] := byte(ini.ReadInteger('AMS', 'AMS0', 0));
        aAMS_Table[1] := byte(ini.ReadInteger('AMS', 'AMS1', 1));
        aAMS_Table[2] := byte(ini.ReadInteger('AMS', 'AMS2', 2));
        aAMS_Table[3] := byte(ini.ReadInteger('AMS', 'AMS3', 3));
        aAMS_Table[4] := byte(ini.ReadInteger('AMS', 'AMS4', 3));
        aAMS_Table[5] := byte(ini.ReadInteger('AMS', 'AMS5', 3));
        aAMS_Table[6] := byte(ini.ReadInteger('AMS', 'AMS6', 3));
        aAMS_Table[7] := byte(ini.ReadInteger('AMS', 'AMS7', 3));
        aPEGR_table[0] := single(ini.ReadFloat('PEGR', 'PEGR0', 50));
        aPEGR_table[1] := single(ini.ReadFloat('PEGR', 'PEGR1', 25));
        aPEGR_table[2] := single(ini.ReadFloat('PEGR', 'PEGR2', 6.25));
        aPEGR_table[3] := single(ini.ReadFloat('PEGR', 'PEGR3', 3.125));
      finally
        ini.Free;
        Result := True;
      end;
    except
      on e: Exception do Result := False;
    end;
  end
  else
    Result := False;
end;

end.
