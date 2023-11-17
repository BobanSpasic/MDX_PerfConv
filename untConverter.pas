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
  untDXUtils, untParConst, Math, untUtils, untTX802Performance, untTX802PerformanceBank;

procedure ConvertTX7toMDX(ABank: string; ANumber: integer);
procedure ConvertDX7IItoMDX(ABank: string; ANumber: integer);
procedure ConvertDX7IItoMDX(ABankA, ABankB, APerf: string; ANumber: integer); overload;
procedure ConvertDX5toMDX(ABankA1, ABankB1, ABankA2, ABankB2, APerf: string; ANumber: integer);
procedure ConvertTX802ToMDX(ABankA1, ABankA2, ABankB1, ABankB2, APerf: string; ANumber: integer);
procedure ConvertBigDX7IItoMDX(ABankA: string; ANumber: integer);
procedure Convert2BigDX7IItoMDX(ABankA, ABankB: string; ANumber: integer);

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
      sup.NoteLimitLow := pced.SplitPoint + 1;
  end;

  if (pced.PerformanceLayerMode = 1) and (pced.DualDetune <> 0) then
  begin
    if isVoiceA then
    begin
      sup.DetuneSGN := 0;
      {DX77II - value 7 = 25c
       MiniDexed - value 12,375 = 25c}
      //sup.DetuneVAL := Floor(pced.DualDetune * 3.572);
      sup.DetuneVAL := Floor(pced.DualDetune * 1.768);
    end
    else
    begin
      sup.DetuneSGN := 1;
      //sup.DetuneVAL := Floor(pced.DualDetune * 3.572);
      sup.DetuneVAL := Floor(pced.DualDetune * 1.768);
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
    sup.NoteLimitHigh := par.G_SplitPoint;
  if (par.G_KeyAssignMode = 1) and (par.G_DualModeDetune <> 0) then
  begin
    sup.DetuneSGN := 0;
    //sup.DetuneVAL := Floor(par.G_DualModeDetune * 1.786);
    sup.DetuneVAL := Floor(par.G_DualModeDetune * 0.886);
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
    sup.NoteLimitLow := par.G_SplitPoint + 1;
  if (par.G_KeyAssignMode = 1) and (par.G_DualModeDetune <> 0) then
  begin
    sup.DetuneSGN := 1;
    //sup.DetuneVAL := Floor(par.G_DualModeDetune * 1.786);
    sup.DetuneVAL := Floor(par.G_DualModeDetune * 0.886);
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

function LoadTX802toPCEDx(aACED: TDX7IISupplementContainer; aPCED: TTX802PerformanceContainer; aVc: integer): TMDX_PCEDx_Params;
var
  par: TDX7II_ACED_Params;
  sup: TMDX_PCEDx_Params;
  txp: TTX802_PCED_Params;
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

  //TX802 part
  txp := aPCED.Get_PCED_Params;
  case aVc of
    1: begin
      sup.Volume := txp.OutputVolume1;
      sup.NoteShift := txp.NoteShift1;
      sup.NoteLimitLow := txp.NoteLimitLow1;
      sup.NoteLimitHigh := txp.NoteLimitHigh1;
      if txp.Detune1 > 7 then
      begin
        sup.DetuneSGN := 0;
        sup.DetuneVAL := Floor((txp.Detune1 - 7) * 3.572);
      end
      else
      begin
        sup.DetuneSGN := 1;
        sup.DetuneVAL := Floor((7 - txp.Detune1) * 3.572);
      end;
    end;
    2: begin
      sup.Volume := txp.OutputVolume2;
      sup.NoteShift := txp.NoteShift2;
      sup.NoteLimitLow := txp.NoteLimitLow2;
      sup.NoteLimitHigh := txp.NoteLimitHigh2;
      if txp.Detune2 > 7 then
      begin
        sup.DetuneSGN := 0;
        sup.DetuneVAL := Floor((txp.Detune2 - 7) * 3.572);
      end
      else
      begin
        sup.DetuneSGN := 1;
        sup.DetuneVAL := Floor((7 - txp.Detune2) * 3.572);
      end;
    end;
    3: begin
      sup.Volume := txp.OutputVolume3;
      sup.NoteShift := txp.NoteShift3;
      sup.NoteLimitLow := txp.NoteLimitLow3;
      sup.NoteLimitHigh := txp.NoteLimitHigh3;
      if txp.Detune3 > 7 then
      begin
        sup.DetuneSGN := 0;
        sup.DetuneVAL := Floor((txp.Detune3 - 7) * 3.572);
      end
      else
      begin
        sup.DetuneSGN := 1;
        sup.DetuneVAL := Floor((7 - txp.Detune3) * 3.572);
      end;
    end;
    4: begin
      sup.Volume := txp.OutputVolume4;
      sup.NoteShift := txp.NoteShift4;
      sup.NoteLimitLow := txp.NoteLimitLow4;
      sup.NoteLimitHigh := txp.NoteLimitHigh4;
      if txp.Detune4 > 7 then
      begin
        sup.DetuneSGN := 0;
        sup.DetuneVAL := Floor((txp.Detune4 - 7) * 3.572);
      end
      else
      begin
        sup.DetuneSGN := 1;
        sup.DetuneVAL := Floor((7 - txp.Detune4) * 3.572);
      end;
    end;
    5: begin
      sup.Volume := txp.OutputVolume5;
      sup.NoteShift := txp.NoteShift5;
      sup.NoteLimitLow := txp.NoteLimitLow5;
      sup.NoteLimitHigh := txp.NoteLimitHigh5;
      if txp.Detune5 > 7 then
      begin
        sup.DetuneSGN := 0;
        sup.DetuneVAL := Floor((txp.Detune5 - 7) * 3.572);
      end
      else
      begin
        sup.DetuneSGN := 1;
        sup.DetuneVAL := Floor((7 - txp.Detune5) * 3.572);
      end;
    end;
    6: begin
      sup.Volume := txp.OutputVolume6;
      sup.NoteShift := txp.NoteShift6;
      sup.NoteLimitLow := txp.NoteLimitLow6;
      sup.NoteLimitHigh := txp.NoteLimitHigh6;
      if txp.Detune6 > 7 then
      begin
        sup.DetuneSGN := 0;
        sup.DetuneVAL := Floor((txp.Detune6 - 7) * 3.572);
      end
      else
      begin
        sup.DetuneSGN := 1;
        sup.DetuneVAL := Floor((7 - txp.Detune6) * 3.572);
      end;
    end;
    7: begin
      sup.Volume := txp.OutputVolume7;
      sup.NoteShift := txp.NoteShift7;
      sup.NoteLimitLow := txp.NoteLimitLow7;
      sup.NoteLimitHigh := txp.NoteLimitHigh7;
      if txp.Detune7 > 7 then
      begin
        sup.DetuneSGN := 0;
        sup.DetuneVAL := Floor((txp.Detune7 - 7) * 3.572);
      end
      else
      begin
        sup.DetuneSGN := 1;
        sup.DetuneVAL := Floor((7 - txp.Detune7) * 3.572);
      end;
    end;
    8: begin
      sup.Volume := txp.OutputVolume8;
      sup.NoteShift := txp.NoteShift8;
      sup.NoteLimitLow := txp.NoteLimitLow8;
      sup.NoteLimitHigh := txp.NoteLimitHigh8;
      if txp.Detune8 > 7 then
      begin
        sup.DetuneSGN := 0;
        sup.DetuneVAL := Floor((txp.Detune8 - 7) * 3.572);
      end
      else
      begin
        sup.DetuneSGN := 1;
        sup.DetuneVAL := Floor((7 - txp.Detune8) * 3.572);
      end;
    end;
  end;

  Result := sup;
end;

procedure ConvertTX7toMDX(ABank: string; ANumber: integer);
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
  sName: string;
  sPath: string;
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

  sPath := ExtractFilePath(ABank);
  if sPath = '' then sPath := GetCurrentDir;
  WriteLn('');
  WriteLn('Writting to the directory ' + sPath);
  WriteLn('');

  for i := 0 to 3 do
  begin
    MDX.InitPerformance;
    MDX.AllMIDIChToZero;
    MDX.FMDX_Params.General.Name := TX7.GetFunctionName(i);
    MDX.FMDX_Params.General.Category := 'Converted';
    MDX.FMDX_Params.General.Origin := 'Conversion from TX7 Performances';

    sName := Format('%.6d', [i + ANumber]) + '_' +
      Trim(ExtractFileNameWithoutExt(ExtractFileName(ABank)));
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
      MDX.SavePerformanceToFile(IncludeTrailingPathDelimiter(sPath) +
        sName + '.ini', False);

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

procedure ConvertDX7IItoMDX(ABank: string; ANumber: integer);
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
  sName: string;
  sPath: string;

  perg, ams1, ams2, ams3, ams4, ams5, ams6: byte;

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

  sPath := ExtractFilePath(ABank);
  if sPath = '' then sPath := GetCurrentDir;
  WriteLn('');
  WriteLn('Writting to the directory ' + sPath);
  WriteLn('');

  for i := 0 to 3 do
  begin
    MDX.InitPerformance;
    MDX.AllMIDIChToZero;
    MDX.FMDX_Params.General.Name :=
      'Voices ' + IntToStr(i * 8) + ' to ' + IntToStr((i + 1) * 8 - 1);
    MDX.FMDX_Params.General.Category := 'Converted';
    MDX.FMDX_Params.General.Origin := 'Conversion from DX7II Voices';

    sName := Format('%.6d', [i + ANumber + 1]) + '_' +
      Trim(ExtractFileNameWithoutExt(ExtractFileName(ABank)));
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
      DX7_VCED.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6);
      MDX.LoadVoiceToTG(j, DX7_VCED.Get_VCED_Params);
      MDX_TG.Set_PCEDx_Params(LoadDX7IIACEDtoPCEDx(DX7II_ACED));
      MDX.LoadPCEDxToTG(j, MDX_TG.Get_PCEDx_Params);
      MDX.FMDX_Params.TG[j].MIDIChannel := j;
      MDX.SavePerformanceToFile(IncludeTrailingPathDelimiter(sPath) +
        sName + '.ini', False);

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

procedure ConvertDX5toMDX(ABankA1, ABankB1, ABankA2, ABankB2, APerf: string; ANumber: integer);
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
    MDX.AllMIDIChToZero;
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

procedure ConvertDX7IItoMDX(ABankA, ABankB, APerf: string; ANumber: integer); overload;
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

  perg, ams1, ams2, ams3, ams4, ams5, ams6: byte;

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
    {for i := 1 to 32 do
      WriteLn(DXA.GetVoiceName(i));}
  end;

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(VMEM, msB, msSearchPosition, msFoundPosition) then
  begin
    DXB.LoadBankFromStream(msB, msFoundPosition);
    WriteLn('');
    WriteLn('VMEM B loaded from ' + ABankB + ' from position ' +
      IntToStr(msFoundPosition));
    {for i := 1 to 32 do
      WriteLn(DXB.GetVoiceName(i));}
  end;

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(AMEM, msA, msSearchPosition, msFoundPosition) then
  begin
    DXAs.LoadSupplBankFromStream(msA, msFoundPosition);
    WriteLn('');
    WriteLn('AMEM A loaded from ' + ABankA + ' from position ' +
      IntToStr(msFoundPosition));
  end
  else
  begin
    WriteLn('AMEM A not found, using INIT parameters');
    DXAs.InitSupplBank;
  end;

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(AMEM, msB, msSearchPosition, msFoundPosition) then
  begin
    DXBs.LoadSupplBankFromStream(msB, msFoundPosition);
    WriteLn('');
    WriteLn('AMEM B loaded from ' + ABankB + ' from position ' +
      IntToStr(msFoundPosition));
  end
  else
  begin
    WriteLn('AMEM B not found, using INIT parameters');
    DXBs.InitSupplBank;
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
        DX7_VCED_B.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6);
      end
      else
      begin
        WriteLn('2: Bank B, Voice ' + IntToStr(iVoiceB - 32) + ' - ' + DXA.GetVoiceName(iVoiceB - 32));
        DXB.GetVoice(iVoiceB - 32, DX7_VCED_B);
        DXBs.GetSupplement(iVoiceB - 32, DX7II_ACED_B);
        perg := DX7II_ACED_B.Get_ACED_Params.Pitch_EG_Range;
        ams1 := DX7II_ACED_B.Get_ACED_Params.OP1_AM_Sensitivity;
        ams2 := DX7II_ACED_B.Get_ACED_Params.OP2_AM_Sensitivity;
        ams3 := DX7II_ACED_B.Get_ACED_Params.OP3_AM_Sensitivity;
        ams4 := DX7II_ACED_B.Get_ACED_Params.OP4_AM_Sensitivity;
        ams5 := DX7II_ACED_B.Get_ACED_Params.OP5_AM_Sensitivity;
        ams6 := DX7II_ACED_B.Get_ACED_Params.OP6_AM_Sensitivity;
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
    MDX.SavePerformanceToFile(IncludeTrailingPathDelimiter(sPath) +
      sName + '.ini', False);

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

procedure ConvertTX802ToMDX(ABankA1, ABankA2, ABankB1, ABankB2, APerf: string; ANumber: integer);
var
  msA1: TMemoryStream;
  msB1: TMemoryStream;
  msA2: TMemoryStream;
  msB2: TMemoryStream;
  msP: TMemoryStream;

  DXA1: TDX7BankContainer;
  DXB1: TDX7BankContainer;
  DXA1s: TDX7IISupplBankContainer;
  DXB1s: TDX7IISupplBankContainer;
  DXA2: TDX7BankContainer;
  DXB2: TDX7BankContainer;
  DXA2s: TDX7IISupplBankContainer;
  DXB2s: TDX7IISupplBankContainer;

  TX802: TTX802PerfBankContainer;
  MDX: TMDXPerformanceContainer;

  DX7_VCED: TDX7VoiceContainer;
  DX7II_ACED: TDX7IISupplementContainer;
  TX802_PCED: TTX802PerformanceContainer;
  MDX_TG: TMDXSupplementContainer;

  Params: TTX802_PCED_Params;
  iVoice: array [1..8] of integer;

  msSearchPosition: integer;
  msFoundPosition: integer;

  i, j, t: integer;
  sName: string;
  sPath: string;

  perg, ams1, ams2, ams3, ams4, ams5, ams6: byte;

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
  DXA1s := TDX7IISupplBankContainer.Create;
  DXB1s := TDX7IISupplBankContainer.Create;
  DXA2 := TDX7BankContainer.Create;
  DXB2 := TDX7BankContainer.Create;
  DXA2s := TDX7IISupplBankContainer.Create;
  DXB2s := TDX7IISupplBankContainer.Create;
  TX802 := TTX802PerfBankContainer.Create;

  DXA1s.InitSupplBank;
  DXB1s.InitSupplBank;
  DXA2s.InitSupplBank;
  DXB2s.InitSupplBank;

  MDX := TMDXPerformanceContainer.Create;

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(VMEM, msA1, msSearchPosition, msFoundPosition) then
  begin
    DXA1.LoadBankFromStream(msA1, msFoundPosition);
    WriteLn('');
    WriteLn('VMEM A1 loaded from ' + ABankA1 + ' from position ' +
      IntToStr(msFoundPosition));
    for i := 1 to 32 do
      WriteLn(DXA1.GetVoiceName(i));
  end;

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(AMEM, msA1, msSearchPosition, msFoundPosition) then
  begin
    DXA1s.LoadSupplBankFromStream(msA1, msFoundPosition);
    WriteLn('');
    WriteLn('AMEM A1 loaded from ' + ABankA1 + ' from position ' +
      IntToStr(msFoundPosition));
  end;

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(VMEM, msA2, msSearchPosition, msFoundPosition) then
  begin
    DXA2.LoadBankFromStream(msA2, msFoundPosition);
    WriteLn('');
    WriteLn('VMEM A2 loaded from ' + ABankA2 + ' from position ' +
      IntToStr(msFoundPosition));
    for i := 1 to 32 do
      WriteLn(DXA2.GetVoiceName(i));
  end;

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(AMEM, msA2, msSearchPosition, msFoundPosition) then
  begin
    DXA2s.LoadSupplBankFromStream(msA2, msFoundPosition);
    WriteLn('');
    WriteLn('AMEM A2 loaded from ' + ABankA2 + ' from position ' +
      IntToStr(msFoundPosition));
  end;

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(VMEM, msB1, msSearchPosition, msFoundPosition) then
  begin
    DXB1.LoadBankFromStream(msB1, msFoundPosition);
    WriteLn('');
    WriteLn('VMEM B1 loaded from ' + ABankB1 + ' from position ' +
      IntToStr(msFoundPosition));
    for i := 1 to 32 do
      WriteLn(DXB1.GetVoiceName(i));
  end;

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(AMEM, msB1, msSearchPosition, msFoundPosition) then
  begin
    DXB1s.LoadSupplBankFromStream(msB1, msFoundPosition);
    WriteLn('');
    WriteLn('AMEM B1 loaded from ' + ABankB1 + ' from position ' +
      IntToStr(msFoundPosition));
  end;

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(VMEM, msB2, msSearchPosition, msFoundPosition) then
  begin
    DXB2.LoadBankFromStream(msB2, msFoundPosition);
    WriteLn('');
    WriteLn('VMEM B2 loaded from ' + ABankB2 + ' from position ' +
      IntToStr(msFoundPosition));
    for i := 1 to 32 do
      WriteLn(DXB2.GetVoiceName(i));
  end;

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(AMEM, msB2, msSearchPosition, msFoundPosition) then
  begin
    DXB2s.LoadSupplBankFromStream(msB2, msFoundPosition);
    WriteLn('');
    WriteLn('AMEM B2 loaded from ' + ABankB2 + ' from position ' +
      IntToStr(msFoundPosition));
  end;

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(PMEM802, msP, msSearchPosition, msFoundPosition) then
  begin
    TX802.LoadPerfBankFromStream(msP, msFoundPosition);
    WriteLn('');
    WriteLn('PMEM802 loaded from ' + APerf + ' from position ' +
      IntToStr(msFoundPosition));
    for i := 1 to 64 do
      WriteLn(TX802.GetPerformanceName(i));
  end;

  sPath := ExtractFilePath(APerf);
  if sPath = '' then sPath := GetCurrentDir;
  WriteLn('');
  WriteLn('Writting to the directory ' + sPath);
  WriteLn('');

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
        DX7_VCED.Mk2ToMk1(perg, ams1, ams2, ams3, ams4, ams5, ams6);
        MDX.LoadVoiceToTG(j, DX7_VCED.Get_VCED_Params);
        MDX_TG.Set_PCEDx_Params(LoadTX802toPCEDx(DX7II_ACED, TX802_PCED, j));
        MDX.LoadPCEDxToTG(j, MDX_TG.Get_PCEDx_Params);
        MDX.FMDX_Params.TG[j].BankNumberLSB := 1;
        WriteLn('Voice ' + IntToStr(j) + ' - Preset B2:' + IntToStr(iVoice[j]) + '(' + IntToStr(t) + ') :' + DX7_VCED.GetVoiceName);
      end;
      MDX.FMDX_Params.TG[j].VoiceNumber := iVoice[j];
      case j of
        1: MDX.FMDX_Params.TG[j].MIDIChannel := Params.RXChannel1;
        2: MDX.FMDX_Params.TG[j].MIDIChannel := Params.RXChannel2;
        3: MDX.FMDX_Params.TG[j].MIDIChannel := Params.RXChannel3;
        4: MDX.FMDX_Params.TG[j].MIDIChannel := Params.RXChannel4;
        5: MDX.FMDX_Params.TG[j].MIDIChannel := Params.RXChannel5;
        6: MDX.FMDX_Params.TG[j].MIDIChannel := Params.RXChannel6;
        7: MDX.FMDX_Params.TG[j].MIDIChannel := Params.RXChannel7;
        8: MDX.FMDX_Params.TG[j].MIDIChannel := Params.RXChannel8;
      end;
    end;

    WriteLn('Writting ' + sName + '.ini');
    MDX.SavePerformanceToFile(IncludeTrailingPathDelimiter(sPath) +
      sName + '.ini', False);

    DX7_VCED.Free;
    DX7II_ACED.Free;
    TX802_PCED.Free;
    MDX_TG.Free;
  end;

  msA1.Free;
  msB1.Free;
  msA2.Free;
  msB2.Free;
  msP.Free;
  DXA1.Free;
  DXB1.Free;
  DXA1s.Free;
  DXB1s.Free;
  DXA2.Free;
  DXB2.Free;
  DXA2s.Free;
  DXB2s.Free;
  TX802.Free;
  MDX.Free;
end;

procedure ConvertBigDX7IItoMDX(ABankA: string; ANumber: integer);
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

  perg, ams1, ams2, ams3, ams4, ams5, ams6: byte;

begin
  msFoundPosition := 0;

  msA := TMemoryStream.Create;
  msA.LoadFromFile(ABankA);
  msB := TMemoryStream.Create;
  msB.LoadFromFile(ABankA);
  msP := TMemoryStream.Create;
  msP.LoadFromFile(ABankA);

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
    {for i := 1 to 32 do
      WriteLn(DXA.GetVoiceName(i)); }
  end;

  msSearchPosition := msFoundPosition;
  if FindDX_SixOP_MEM(VMEM, msB, msSearchPosition, msFoundPosition) then
  begin
    DXB.LoadBankFromStream(msB, msFoundPosition);
    WriteLn('');
    WriteLn('VMEM B loaded from ' + ABankA + ' from position ' +
      IntToStr(msFoundPosition));
    {for i := 1 to 32 do
      WriteLn(DXB.GetVoiceName(i));}
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
    WriteLn('AMEM A loaded from ' + ABankA + ' from position ' +
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
    WriteLn('AMEM B loaded from ' + ABankA + ' from position ' +
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
    WriteLn('LM_PMEM loaded from ' + ABankA + ' from position ' +
      IntToStr(msFoundPosition));
    {for i := 1 to 32 do
      WriteLn(DX7II.GetPerformanceName(i));}
  end;

  sPath := ExtractFilePath(ABankA);
  if sPath = '' then sPath := GetCurrentDir;
  WriteLn('');
  WriteLn('Writting to the directory ' + sPath);
  WriteLn('');

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
    MDX.SavePerformanceToFile(IncludeTrailingPathDelimiter(sPath) +
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

procedure Convert2BigDX7IItoMDX(ABankA, ABankB: string; ANumber: integer);
var
  msA: TMemoryStream;
  msB: TMemoryStream;
  msPA: TMemoryStream;
  msPB: TMemoryStream;
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
  sPath: string;

  perg, ams1, ams2, ams3, ams4, ams5, ams6: byte;

begin
  msFoundPosition := 0;

  msA := TMemoryStream.Create;
  msA.LoadFromFile(ABankA);
  msB := TMemoryStream.Create;
  msB.LoadFromFile(ABankB);
  msPA := TMemoryStream.Create;
  msPA.LoadFromFile(ABankA);
  msPB := TMemoryStream.Create;
  msPB.LoadFromFile(ABankB);

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
    WriteLn('VMEM A 01-32 loaded from ' + ABankA + ' from position ' +
      IntToStr(msFoundPosition));
  end;

  msSearchPosition := msFoundPosition;
  if FindDX_SixOP_MEM(VMEM, msA, msSearchPosition, msFoundPosition) then
  begin
    DXA64.LoadBankFromStream(msA, msFoundPosition);
    WriteLn('');
    WriteLn('VMEM A 33-64 loaded from ' + ABankA + ' from position ' +
      IntToStr(msFoundPosition));
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
    WriteLn('AMEM A 01-32 loaded from ' + ABankA + ' from position ' +
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
    WriteLn('AMEM A 33-64 loaded from ' + ABankA + ' from position ' +
      IntToStr(msFoundPosition));
  end
  else
  begin
    WriteLn('AMEM A 33-64 not found, using INIT parameters');
    DXA64s.InitSupplBank;
  end;

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(LMPMEM, msPA, msSearchPosition, msFoundPosition) then
  begin
    DX7IIA.LoadPerfBankFromStream(msPA, msFoundPosition);
    WriteLn('');
    WriteLn('LM_PMEM loaded from ' + ABankA + ' from position ' +
      IntToStr(msFoundPosition));
  end;

  //=================== Bank B =====================

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(VMEM, msB, msSearchPosition, msFoundPosition) then
  begin
    DXB32.LoadBankFromStream(msB, msFoundPosition);
    WriteLn('');
    WriteLn('VMEM B 01-32 loaded from ' + ABankB + ' from position ' +
      IntToStr(msFoundPosition));
  end;

  msSearchPosition := msFoundPosition;
  if FindDX_SixOP_MEM(VMEM, msB, msSearchPosition, msFoundPosition) then
  begin
    DXB64.LoadBankFromStream(msB, msFoundPosition);
    WriteLn('');
    WriteLn('VMEM B 33-64 loaded from ' + ABankB + ' from position ' +
      IntToStr(msFoundPosition));
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
    WriteLn('AMEM B 01-32 loaded from ' + ABankB + ' from position ' +
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
    WriteLn('AMEM B 33-64 loaded from ' + ABankB + ' from position ' +
      IntToStr(msFoundPosition));
  end
  else
  begin
    WriteLn('AMEM B 33-64 not found, using INIT parameters');
    DXB64s.InitSupplBank;
  end;

  msSearchPosition := 0;
  if FindDX_SixOP_MEM(LMPMEM, msPB, msSearchPosition, msFoundPosition) then
  begin
    DX7IIB.LoadPerfBankFromStream(msPB, msFoundPosition);
    WriteLn('');
    WriteLn('LM_PMEM loaded from ' + ABankB + ' from position ' +
      IntToStr(msFoundPosition));
  end;

  sPath := ExtractFilePath(ABankA);
  if sPath = '' then sPath := GetCurrentDir;
  WriteLn('');
  WriteLn('Writting to the directory ' + sPath);
  WriteLn('');

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

    // 0 - 63 - Internal
    // 64-127 - Cartridge
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
    MDX.SavePerformanceToFile(IncludeTrailingPathDelimiter(sPath) +
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
    MDX.SavePerformanceToFile(IncludeTrailingPathDelimiter(sPath) +
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
  msPA.Free;
  msPB.Free;
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

end.
