{
 *****************************************************************************
  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************

 Author: Boban Spasic

 Unit description:
 Conversion from TX7, DX5 and DX7II to MiniDexed INI format
}
unit untConvFunct;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Math, untDX7IISupplement, untTX7Function,
  untMDXSupplement, untDX7IIPerformance, untParConst, untTX802Performance;

function LoadDX7IIACEDPCEDtoPCEDx(isVoiceA: boolean; aACED: TDX7IISupplementContainer; aPCED: TDX7IIPerformanceContainer): TMDX_PCEDx_Params;
function LoadDX7IIACEDtoPCEDx(aACED: TDX7IISupplementContainer): TMDX_PCEDx_Params;
function LoadTX7PCEDtoPCEDx(aPCED: TTX7FunctionContainer): TMDX_PCEDx_Params;
function LoadDX5PCEDtoPCEDx(aPCED: TTX7FunctionContainer): TMDX_PCEDx_Params;
function LoadTX802toPCEDx(aACED: TDX7IISupplementContainer; aPCED: TTX802PerformanceContainer; aVc: integer): TMDX_PCEDx_Params;

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
      sup.NoteLimitHigh := pced.SplitPoint - 1
    else
      sup.NoteLimitLow := pced.SplitPoint;
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

  sup.Volume := pced.TotalVolume;

  if pced.PanMode <> 0 then
  begin
    if isVoiceA then
      sup.Pan := 0
    else
      sup.Pan := 127;
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
  if par.G_KeyAssignMode = 1 then
    sup.Pan := 32;
  if par.G_KeyAssignMode = 2 then
  begin
    sup.NoteLimitHigh := par.G_SplitPoint - 1;
    sup.Pan := 0;
  end;
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
  sup.NoteShift := par.B_PerfKeyShift;
  if par.G_KeyAssignMode = 1 then
    sup.Pan := 96;
  if par.G_KeyAssignMode = 2 then
  begin
    sup.NoteLimitLow := par.G_SplitPoint;
    sup.Pan := 127;
  end;
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
      case txp.OutputAssign1 of
        1: sup.Pan := 0;
        2: sup.Pan := 127;
        else
          sup.Pan := 64;
      end;
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
      case txp.OutputAssign2 of
        1: sup.Pan := 0;
        2: sup.Pan := 127;
        else
          sup.Pan := 64;
      end;
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
      case txp.OutputAssign3 of
        1: sup.Pan := 0;
        2: sup.Pan := 127;
        else
          sup.Pan := 64;
      end;
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
      case txp.OutputAssign4 of
        1: sup.Pan := 0;
        2: sup.Pan := 127;
        else
          sup.Pan := 64;
      end;
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
      case txp.OutputAssign5 of
        1: sup.Pan := 0;
        2: sup.Pan := 127;
        else
          sup.Pan := 64;
      end;
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
      case txp.OutputAssign6 of
        1: sup.Pan := 0;
        2: sup.Pan := 127;
        else
          sup.Pan := 64;
      end;
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
      case txp.OutputAssign7 of
        1: sup.Pan := 0;
        2: sup.Pan := 127;
        else
          sup.Pan := 64;
      end;
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
      case txp.OutputAssign8 of
        1: sup.Pan := 0;
        2: sup.Pan := 127;
        else
          sup.Pan := 64;
      end;
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

end.
