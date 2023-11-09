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
  untDXUtils, untParConst, Math, untUtils;

procedure ConvertTX7toMDX(ABank: string);
procedure ConvertDX7IItoMDX(ABank: string);
procedure ConvertDX7IItoMDX(ABankA, ABankB, APerf: string); overload;
procedure ConvertDX5toMDX(ABankA1, ABankB1, ABankA2, ABankB2, APerf: string);


implementation

function LoadDX7IIACEDPCEDtoPCEDx(isVoiceA: boolean; aACED: TDX7IISupplementContainer; aPCED: TDX7IIPerformanceContainer): TMDX_PCEDx_Params;
var
  aced: TDX7II_ACED_Params;
  pced: TDX7II_PCED_Params;
  sup: TMDX_PCEDx_Params;
  bits: integer;
begin
  aced := aACED.Get_ACED_Params;
  pced := aPCED.Get_PCED_Params;
  GetDefinedValues(MDX, finit, sup.params);

  sup.PitchBendRange := aced.Pitch_Bend_Range;
  sup.PitchBendStep := aced.Pitch_Bend_Step;
  sup.PortamentoMode := aced.Portamento_Mode;
  if aced.Portamento_Step > 0 then
    sup.PortamentoGlissando := 1
  else
    sup.PortamentoGlissando := 0;
  sup.PortamentoTime := aced.Portamento_Time;
  sup.MonoMode := 0;
  sup.ModulationWheelRange :=
    MaxIntValue([aced.ModWhell_Ampl_Mod_Range, aced.ModWhell_Pitch_Mod_Range,
    aced.ModWhell_EG_Bias_Range]);
  bits := 0;
  if aced.ModWhell_Pitch_Mod_Range > 0 then bits := bits + 1;
  if aced.ModWhell_Ampl_Mod_Range > 0 then bits := bits + 2;
  if aced.ModWhell_EG_Bias_Range > 0 then bits := bits + 4;
  sup.ModulationWheelTarget := bits;
  sup.FootControlRange :=
    MaxIntValue([aced.FootCtr_Ampl_Mod_Range, aced.FootCtr_Pitch_Mod_Range,
    aced.FootCtr_EG_Bias_Range]);
  bits := 0;
  if aced.FootCtr_Pitch_Mod_Range > 0 then bits := bits + 1;
  if aced.FootCtr_Ampl_Mod_Range > 0 then bits := bits + 2;
  if aced.FootCtr_EG_Bias_Range > 0 then bits := bits + 4;
  sup.FootControlTarget := bits;
  sup.BreathControlRange :=
    MaxIntValue([aced.BrthCtr_Ampl_Mod_Range, aced.BrthCtr_Pitch_Mod_Range,
    aced.BrthCtr_EG_Bias_Range]);
  bits := 0;
  if aced.BrthCtr_Pitch_Mod_Range > 0 then bits := bits + 1;
  if aced.BrthCtr_Ampl_Mod_Range > 0 then bits := bits + 2;
  if aced.BrthCtr_EG_Bias_Range > 0 then bits := bits + 4;
  sup.BreathControlTarget := bits;
  sup.AftertouchRange :=
    MaxIntValue([aced.AftrTch_Ampl_Mod_Range, aced.AftrTch_Pitch_Mod_Range,
    aced.AftrTch_EG_Bias_Range]);
  bits := 0;
  if aced.AftrTch_Pitch_Mod_Range > 0 then bits := bits + 1;
  if aced.AftrTch_Ampl_Mod_Range > 0 then bits := bits + 2;
  if aced.AftrTch_EG_Bias_Range > 0 then bits := bits + 4;
  sup.AftertouchTarget := bits;

  //do PCED conversions
  if isVoiceA then
    sup.NoteShift := pced.NoteShiftRangeA
  else
  begin
    if (pced.PerformanceLayerMode = 0) or (pced.PerformanceLayerMode = 1) then
      sup.NoteShift := 24
    else
      sup.NoteShift := pced.NoteShiftRangeB;
  end;

  if pced.PerformanceLayerMode = 2 then
  begin
    if isVoiceA then
      sup.NoteLimitHigh := pced.SplitPoint
    else
      sup.NoteLimitLow := pced.SplitPoint - 1;
  end;

  if (pced.PerformanceLayerMode = 1) and (pced.DualDetune <> 0) then
  begin
    if isVoiceA then
    begin
      sup.DetuneSGN := 0;
      sup.DetuneVAL := Floor(pced.DualDetune * 14);
    end
    else
    begin
      sup.DetuneSGN := 1;
      sup.DetuneVAL := Floor(pced.DualDetune * 14);
    end;
  end;
  Result := sup;
end;

function LoadDX7IIACEDtoPCEDx(aACED: TDX7IISupplementContainer): TMDX_PCEDx_Params;
var
  par: TDX7II_ACED_Params;
  sup: TMDX_PCEDx_Params;
  bits: integer;
begin
  par := aACED.Get_ACED_Params;
  GetDefinedValues(MDX, finit, sup.params);
  sup.PitchBendRange := par.Pitch_Bend_Range;
  sup.PitchBendStep := par.Pitch_Bend_Step;
  sup.PortamentoMode := par.Portamento_Mode;
  if par.Portamento_Step > 0 then
    sup.PortamentoGlissando := 1
  else
    sup.PortamentoGlissando := 0;
  sup.PortamentoTime := par.Portamento_Time;
  sup.MonoMode := 0;
  sup.ModulationWheelRange :=
    MaxIntValue([par.ModWhell_Ampl_Mod_Range, par.ModWhell_Pitch_Mod_Range,
    par.ModWhell_EG_Bias_Range]);
  bits := 0;
  if par.ModWhell_Pitch_Mod_Range > 0 then bits := bits + 1;
  if par.ModWhell_Ampl_Mod_Range > 0 then bits := bits + 2;
  if par.ModWhell_EG_Bias_Range > 0 then bits := bits + 4;
  sup.ModulationWheelTarget := bits;
  sup.FootControlRange :=
    MaxIntValue([par.FootCtr_Ampl_Mod_Range, par.FootCtr_Pitch_Mod_Range,
    par.FootCtr_EG_Bias_Range]);
  bits := 0;
  if par.FootCtr_Pitch_Mod_Range > 0 then bits := bits + 1;
  if par.FootCtr_Ampl_Mod_Range > 0 then bits := bits + 2;
  if par.FootCtr_EG_Bias_Range > 0 then bits := bits + 4;
  sup.FootControlTarget := bits;
  sup.BreathControlRange :=
    MaxIntValue([par.BrthCtr_Ampl_Mod_Range, par.BrthCtr_Pitch_Mod_Range,
    par.BrthCtr_EG_Bias_Range]);
  bits := 0;
  if par.BrthCtr_Pitch_Mod_Range > 0 then bits := bits + 1;
  if par.BrthCtr_Ampl_Mod_Range > 0 then bits := bits + 2;
  if par.BrthCtr_EG_Bias_Range > 0 then bits := bits + 4;
  sup.BreathControlTarget := bits;
  sup.AftertouchRange :=
    MaxIntValue([par.AftrTch_Ampl_Mod_Range, par.AftrTch_Pitch_Mod_Range,
    par.AftrTch_EG_Bias_Range]);
  bits := 0;
  if par.AftrTch_Pitch_Mod_Range > 0 then bits := bits + 1;
  if par.AftrTch_Ampl_Mod_Range > 0 then bits := bits + 2;
  if par.AftrTch_EG_Bias_Range > 0 then bits := bits + 4;
  sup.AftertouchTarget := bits;
  Result := sup;
end;

function LoadTX7PCEDtoPCEDx(aPCED: TTX7FunctionContainer): TMDX_PCEDx_Params;
var
  par: TTX7_PCED_Params;
  sup: TMDX_PCEDx_Params;
begin
  par := aPCED.Get_PCED_Params;
  GetDefinedValues(MDX, fInit, sup.params);
  sup.NoteShift := par.A_PerfKeyShift;
  if par.G_KeyAssignMode = 2 then
    sup.NoteLimitHigh := par.G_SplitPoint - 1;
  if (par.G_KeyAssignMode = 1) and (par.G_DualModeDetune <> 0) then
  begin
    sup.DetuneSGN := 0;
    sup.DetuneVAL := Floor(par.G_DualModeDetune * 6.6);
  end;
  sup.PitchBendRange := par.A_PitchBendRange;
  sup.PitchBendStep := par.A_PitchBendStep;
  sup.PortamentoMode := par.A_PortamentoMode;
  sup.PortamentoGlissando := par.A_PortaGlissando;
  sup.PortamentoTime := par.A_PortamentoTime;
  sup.MonoMode := par.A_PortamentoTime;
  sup.ModulationWheelRange := Floor(par.A_ModWheelSens * 6.6);
  sup.ModulationWheelTarget := par.A_ModWheelAssign;
  sup.FootControlRange := Floor(par.A_FootCtrlSens * 6.6);
  sup.FootControlTarget := par.A_FootCtrlAssign;
  sup.BreathControlRange := Floor(par.A_BrthCtrlSens * 6.6);
  sup.BreathControlTarget := par.A_BrthCtrlAssign;
  sup.AftertouchRange := Floor(par.A_AfterTouchSens * 6.6);
  sup.AftertouchTarget := par.A_AfterTouchAssign;
  sup.Volume := Ceil(par.A_VoiceAttn * 18.14);
  Result := sup;
end;

function LoadDX5PCEDtoPCEDx(aPCED: TTX7FunctionContainer): TMDX_PCEDx_Params;
var
  par: TTX7_PCED_Params;
  sup: TMDX_PCEDx_Params;
begin
  par := aPCED.Get_PCED_Params;
  GetDefinedValues(MDX, fInit, sup.params);
  sup.NoteShift := par.A_PerfKeyShift;
  if par.G_KeyAssignMode = 2 then
    sup.NoteLimitLow := par.G_SplitPoint;
  if (par.G_KeyAssignMode = 1) and (par.G_DualModeDetune <> 0) then
  begin
    sup.DetuneSGN := 1;
    sup.DetuneVAL := Floor(par.G_DualModeDetune * 6.6);
  end;
  sup.PitchBendRange := par.B_PitchBendRange;
  sup.PitchBendStep := par.B_PitchBendStep;
  sup.PortamentoMode := par.B_PortamentoMode;
  sup.PortamentoGlissando := par.B_PortaGlissando;
  sup.PortamentoTime := par.B_PortamentoTime;
  sup.MonoMode := par.B_PortamentoTime;
  sup.ModulationWheelRange := Floor(par.B_ModWheelSens * 6.6);
  sup.ModulationWheelTarget := par.B_ModWheelAssign;
  sup.FootControlRange := Floor(par.B_FootCtrlSens * 6.6);
  sup.FootControlTarget := par.B_FootCtrlAssign;
  sup.BreathControlRange := Floor(par.B_BrthCtrlSens * 6.6);
  sup.BreathControlTarget := par.B_BrthCtrlAssign;
  sup.AftertouchRange := Floor(par.B_AfterTouchSens * 6.6);
  sup.AftertouchTarget := par.B_AfterTouchAssign;
  sup.Volume := Ceil(par.B_VoiceAttn * 18.14);
  Result := sup;
end;

procedure ConvertTX7toMDX(ABank: string);
var
  ms: TMemoryStream;
  DX: TDX7BankContainer;
  TX7: TTX7FunctBankContainer;
  MDX: TMDXPerformanceContainer;

  DX7_VCED: TDX7VoiceContainer;
  TX7_PCED: TTX7FunctionContainer;
  MDX_TG: TMDXSupplementContainer;

  msSearchPosition: integer;
  msFoundPosition: integer;

  i, j: integer;
begin
  msSearchPosition := 0;
  msFoundPosition := 0;

  ms := TMemoryStream.Create;
  ms.LoadFromFile(ABank);

  DX := TDX7BankContainer.Create;
  TX7 := TTX7FunctBankContainer.Create;
  MDX := TMDXPerformanceContainer.Create;
  if FindDX_SixOP_MEM(VMEM, ms, msSearchPosition, msFoundPosition) then
  begin
    DX.LoadBankFromStream(ms, msFoundPosition);
    WriteLn('VMEM loaded from ' + IntToStr(msFoundPosition));
    for i := 1 to 32 do
      WriteLn(DX.GetVoiceName(i));
  end;
  msSearchPosition := 0;
  if FindDX_SixOP_MEM(PMEM, ms, msSearchPosition, msFoundPosition) then
  begin
    TX7.LoadFunctBankFromStream(ms, msFoundPosition);
    WriteLn('PMEM loaded from ' + IntToStr(msFoundPosition));
    for i := 1 to 32 do
      WriteLn(TX7.GetFunctionName(i));
  end;

  for i := 0 to 3 do
  begin
    MDX.InitPerformance;
    MDX.FMDX_Params.General.Name := TX7.GetFunctionName(i);
    MDX.FMDX_Params.General.Category := 'Converted';
    MDX.FMDX_Params.General.Origin := 'Conversion from TX7/DX1/DX5 Performances';
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
      MDX.SavePerformanceToFile(ABank + IntToStr(i) + '.ini', False);

      DX7_VCED.Free;
      TX7_PCED.Free;
      MDX_TG.Free;
    end;
  end;

  ms.Free;
  DX.Free;
  TX7.Free;
  MDX.Free;
end;

procedure ConvertDX7IItoMDX(ABank: string);
var
  ms: TMemoryStream;
  DX7: TDX7BankContainer;
  DX7II: TDX7IISupplBankContainer;
  MDX: TMDXPerformanceContainer;

  DX7_VCED: TDX7VoiceContainer;
  DX7II_ACED: TDX7IISupplementContainer;
  MDX_TG: TMDXSupplementContainer;

  msSearchPosition: integer;
  msFoundPosition: integer;

  i, j: integer;
begin
  msSearchPosition := 0;
  msFoundPosition := 0;

  ms := TMemoryStream.Create;
  ms.LoadFromFile(ABank);

  DX7 := TDX7BankContainer.Create;
  DX7II := TDX7IISupplBankContainer.Create;
  MDX := TMDXPerformanceContainer.Create;
  if FindDX_SixOP_MEM(VMEM, ms, msSearchPosition, msFoundPosition) then
  begin
    DX7.LoadBankFromStream(ms, msFoundPosition);
    WriteLn('VMEM loaded from ' + IntToStr(msFoundPosition));
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
    MDX.FMDX_Params.General.Name :=
      'Voices ' + IntToStr(i * 8) + ' to ' + IntToStr((i + 1) * 8 - 1);
    MDX.FMDX_Params.General.Category := 'Converted';
    MDX.FMDX_Params.General.Origin := 'Conversion from DX7II Voices';
    for j := 1 to 8 do
    begin
      DX7_VCED := TDX7VoiceContainer.Create;
      DX7II_ACED := TDX7IISupplementContainer.Create;
      MDX_TG := TMDXSupplementContainer.Create;

      DX7.GetVoice(i * 8 + j, DX7_VCED);
      DX7II.GetSupplement(i * 8 + j, DX7II_ACED);
      MDX.LoadVoiceToTG(j, DX7_VCED.Get_VCED_Params);
      MDX_TG.Set_PCEDx_Params(LoadDX7IIACEDtoPCEDx(DX7II_ACED));
      MDX.LoadPCEDxToTG(j, MDX_TG.Get_PCEDx_Params);
      MDX.SavePerformanceToFile(ABank + IntToStr(i) + '.ini', False);

      DX7_VCED.Free;
      DX7II_ACED.Free;
      MDX_TG.Free;
    end;
  end;

  ms.Free;
  DX7.Free;
  DX7II.Free;
  MDX.Free;
end;

procedure ConvertDX5toMDX(ABankA1, ABankB1, ABankA2, ABankB2, APerf: string);
var
  msA1: TMemoryStream;
  msB1: TMemoryStream;
  msA2: TMemoryStream;
  msB2: TMemoryStream;
  msP: TMemoryStream;
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
  sPath: string;
begin
  msFoundPosition := 0;

  msA1 := TMemoryStream.Create;
  msA1.LoadFromFile(ABankA1);
  msB1 := TMemoryStream.Create;
  msB1.LoadFromFile(ABankB1);
  msA2 := TMemoryStream.Create;
  msA2.LoadFromFile(ABankA2);
  msB2 := TMemoryStream.Create;
  msB2.LoadFromFile(ABankB2);
  msP := TMemoryStream.Create;
  msP.LoadFromFile(APerf);

  DXA1 := TDX7BankContainer.Create;
  DXB1 := TDX7BankContainer.Create;
  DXA2 := TDX7BankContainer.Create;
  DXB2 := TDX7BankContainer.Create;
  TX7 := TTX7FunctBankContainer.Create;
  MDX := TMDXPerformanceContainer.Create;

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(VMEM, msA1, msSearchPosition, msFoundPosition) then
  begin
    DXA1.LoadBankFromStream(msA1, msFoundPosition);
    WriteLn('VMEM loaded from ' + IntToStr(msFoundPosition));
    for i := 1 to 32 do
      WriteLn(DXA1.GetVoiceName(i));
  end;

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(VMEM, msB1, msSearchPosition, msFoundPosition) then
  begin
    DXB1.LoadBankFromStream(msB1, msFoundPosition);
    WriteLn('VMEM loaded from ' + IntToStr(msFoundPosition));
    for i := 1 to 32 do
      WriteLn(DXB1.GetVoiceName(i));
  end;

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(VMEM, msA2, msSearchPosition, msFoundPosition) then
  begin
    DXA2.LoadBankFromStream(msA2, msFoundPosition);
    WriteLn('VMEM loaded from ' + IntToStr(msFoundPosition));
    for i := 1 to 32 do
      WriteLn(DXA2.GetVoiceName(i));
  end;

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(VMEM, msB2, msSearchPosition, msFoundPosition) then
  begin
    DXB2.LoadBankFromStream(msB2, msFoundPosition);
    WriteLn('VMEM loaded from ' + IntToStr(msFoundPosition));
    for i := 1 to 32 do
      WriteLn(DXB2.GetVoiceName(i));
  end;

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(PMEM, msP, msSearchPosition, msFoundPosition) then
  begin
    TX7.LoadFunctBankFromStream(msP, msFoundPosition);
    WriteLn('PMEM loaded from ' + IntToStr(msFoundPosition));
    for i := 1 to 64 do
      WriteLn(TX7.GetFunctionName(i));
  end;

  sPath := ExtractFilePath(APerf);
  if sPath = '' then sPath := GetCurrentDir;
  WriteLn('Writting to the directory ' + sPath);

  WriteLn('Writting A1,B1');
  //Banks A1 and B1, performances 1 to 32
  for i := 1 to 32 do
  begin
    MDX.InitPerformance;
    MDX.FMDX_Params.General.Name := TX7.GetFunctionName(i);
    MDX.FMDX_Params.General.Category := 'Converted';
    MDX.FMDX_Params.General.Origin := 'Conversion from TX7/DX1/DX5 Performances';
    DX7_VCED := TDX7VoiceContainer.Create;
    TX7_PCED := TTX7FunctionContainer.Create;
    MDX_TG1 := TMDXSupplementContainer.Create;
    MDX_TG2 := TMDXSupplementContainer.Create;

    TX7.GetFunction(i, TX7_PCED);
    sName := Format('%.6d', [i]) + '_' + Trim(GetValidFileName(TX7.GetFunctionName(i)));

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
    MDX.SavePerformanceToFile(IncludeTrailingPathDelimiter(sPath) +
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
    DX7_VCED := TDX7VoiceContainer.Create;
    TX7_PCED := TTX7FunctionContainer.Create;
    MDX_TG1 := TMDXSupplementContainer.Create;
    MDX_TG2 := TMDXSupplementContainer.Create;

    TX7.GetFunction(32 + i, TX7_PCED);
    sName := Format('%.6d', [i + 32]) + '_' +
      Trim(GetValidFileName(TX7.GetFunctionName(i + 32)));

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
    MDX.SavePerformanceToFile(IncludeTrailingPathDelimiter(sPath) +
      sName + '.ini', False);

    DX7_VCED.Free;
    TX7_PCED.Free;
    MDX_TG1.Free;
    MDX_TG2.Free;
  end;

  msA1.Free;
  msB1.Free;
  msA2.Free;
  msB2.Free;
  msP.Free;
  DXA1.Free;
  DXB1.Free;
  DXA2.Free;
  DXB2.Free;
  TX7.Free;
  MDX.Free;
end;

procedure ConvertDX7IItoMDX(ABankA, ABankB, APerf: string); overload;
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
  sPath: string;
begin
  msFoundPosition := 0;

  msA := TMemoryStream.Create;
  msA.LoadFromFile(ABankA);
  msB := TMemoryStream.Create;
  msB.LoadFromFile(ABankB);
  msP := TMemoryStream.Create;
  msP.LoadFromFile(APerf);

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
    WriteLn('VMEM A loaded from ' + ABankA + ' from position ' +
      IntToStr(msFoundPosition));
    for i := 1 to 32 do
      WriteLn(DXA.GetVoiceName(i));
  end;

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(VMEM, msB, msSearchPosition, msFoundPosition) then
  begin
    DXB.LoadBankFromStream(msB, msFoundPosition);
    WriteLn('');
    WriteLn('VMEM B loaded from ' + ABankB + ' from position ' +
      IntToStr(msFoundPosition));
    for i := 1 to 32 do
      WriteLn(DXB.GetVoiceName(i));
  end;

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(AMEM, msA, msSearchPosition, msFoundPosition) then
  begin
    DXAs.LoadSupplBankFromStream(msA, msFoundPosition);
    WriteLn('');
    WriteLn('AMEM A loaded from ' + ABankA + ' from position ' +
      IntToStr(msFoundPosition));
  end;

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(AMEM, msB, msSearchPosition, msFoundPosition) then
  begin
    DXBs.LoadSupplBankFromStream(msB, msFoundPosition);
    WriteLn('');
    WriteLn('AMEM B loaded from ' + ABankB + ' from position ' +
      IntToStr(msFoundPosition));
  end;

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(LMPMEM, msP, msSearchPosition, msFoundPosition) then
  begin
    DX7II.LoadPerfBankFromStream(msP, msFoundPosition);
    WriteLn('');
    WriteLn('LM_PMEM loaded from ' + APerf + ' from position ' +
      IntToStr(msFoundPosition));
    for i := 1 to 32 do
      WriteLn(DX7II.GetPerformanceName(i));
  end;

  sPath := ExtractFilePath(APerf);
  if sPath = '' then sPath := GetCurrentDir;
  WriteLn('');
  WriteLn('Writting to the directory ' + sPath);
  WriteLn('');

  for i := 1 to 32 do
  begin
    MDX.InitPerformance;
    DX7_VCED_A := TDX7VoiceContainer.Create;
    DX7_VCED_B := TDX7VoiceContainer.Create;
    DX7II_ACED_A := TDX7IISupplementContainer.Create;
    DX7II_ACED_B := TDX7IISupplementContainer.Create;
    DX7II_PCED := TDX7IIPerformanceContainer.Create;
    MDX_TG1 := TMDXSupplementContainer.Create;
    MDX_TG2 := TMDXSupplementContainer.Create;

    DX7II.GetPerformance(i, DX7II_PCED);
    sName := Format('%.6d', [i]) + '_' +
      Trim(GetValidFileName(DX7II.GetPerformanceName(i)));
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
      WriteLn('1: Bank A, Voice ' + IntToStr(iVoiceA));
      DXA.GetVoice(iVoiceA, DX7_VCED_A);
      DXAs.GetSupplement(iVoiceA, DX7II_ACED_A);
    end
    else
    begin
      WriteLn('1: Bank B, Voice ' + IntToStr(iVoiceA - 32));
      DXB.GetVoice(iVoiceA - 32, DX7_VCED_A);
      DXBs.GetSupplement(iVoiceA - 32, DX7II_ACED_A);
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
        WriteLn('2: Bank A, Voice ' + IntToStr(iVoiceB));
        DXA.GetVoice(iVoiceB, DX7_VCED_B);
        DXAs.GetSupplement(iVoiceB, DX7II_ACED_B);
      end
      else
      begin
        WriteLn('2: Bank B, Voice ' + IntToStr(iVoiceB - 32));
        DXB.GetVoice(iVoiceB - 32, DX7_VCED_B);
        DXBs.GetSupplement(iVoiceB - 32, DX7II_ACED_B);
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

      WriteLn('Writting ' + sName + '.ini');
      MDX.SavePerformanceToFile(IncludeTrailingPathDelimiter(sPath) +
        sName + '.ini', False);
    end;

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

end.
