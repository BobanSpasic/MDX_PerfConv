{
 *****************************************************************************
  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************

 Author: Boban Spasic

 Unit description:
 Class implementing TX7 Function Data and related functions for one Voice.

 See the comments in the untDX7Voice about the Checksumm and CalculateHash functions.
}

unit untTX7Function;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, untUtils, untParConst
  {$IFNDEF CMDLINE}
  , HlpHashFactory
  {$ENDIF}
  ;

type
  TTX7_PMEM_Dump = array [0..63] of byte;
  TTX7_PCED_Dump = array [0..93] of byte;

type
  TTX7_PCED_Params = packed record
    case boolean of
      True: (params: TTX7_PCED_Dump);
      False: (
        A_VoiceNr: byte;                  //       0-63 Undocumented: Voice Nr. (source: JSynthLib)
        A_Source_Select: byte;            //DX5    0-15 (MIDI channel)
        A_PolyMono: byte;                 //       0-1
        A_PitchBendRange: byte;           //       0-12
        A_PitchBendStep: byte;            //       0-12
        A_PortamentoTime: byte;           //       0-99
        A_PortaGlissando: byte;           //       0-1
        A_PortamentoMode: byte;           //       0-1
        A_PortamentoPedal: byte;          //DX5    0-1
        A_ModWheelSens: byte;             //       0-15  translates to 0-99 for DX7
        A_ModWheelAssign: byte;           //       0-7
        A_FootCtrlSens: byte;             //       0-15  translates to 0-99 for DX7
        A_FootCtrlAssign: byte;           //       0-7
        A_AfterTouchSens: byte;           //       0-15  translates to 0-99 for DX7
        A_AfterTouchAssign: byte;         //       0-7
        A_BrthCtrlSens: byte;             //       0-15  translates to 0-99 for DX7
        A_BrthCtrlAssign: byte;           //       0-7
        A_KeyIndividualAftTchSens: byte;  //DX5    0-15
        A_KIAT_OP1_Sens: byte;            //DX5    0-15
        A_KIAT_OP2_Sens: byte;            //DX5    0-15
        A_KIAT_OP3_Sens: byte;            //DX5    0-15
        A_KIAT_OP4_Sens: byte;            //DX5    0-15
        A_KIAT_OP5_Sens: byte;            //DX5    0-15
        A_KIAT_OP6_Sens: byte;            //DX5    0-15
        A_KIAT_DecayRate: byte;           //DX5    0-99
        A_KIAT_ReleaseRate: byte;         //DX5    0-99
        A_VoiceAttn: byte;                //       0-7  translates to 0-99 for DX7
        A_ProgramOutput: byte;            //DX5    0-1
        A_SustainPedal: byte;             //DX5    0-1
        A_PerfKeyShift: byte;             //DX5    0-48  center=24

        B_VoiceNr: byte;                  //       0-63 Undocumented: Voice Nr.
        B_Source_Select: byte;            //DX5    0-15 (MIDI channel)
        B_PolyMono: byte;                 //       0-1
        B_PitchBendRange: byte;           //       0-12
        B_PitchBendStep: byte;            //       0-12
        B_PortamentoTime: byte;           //       0-99
        B_PortaGlissando: byte;           //       0-1
        B_PortamentoMode: byte;           //       0-1
        B_PortamentoPedal: byte;          //DX5    0-1
        B_ModWheelSens: byte;             //       0-15  translates to 0-99 for DX7
        B_ModWheelAssign: byte;           //       0-7
        B_FootCtrlSens: byte;             //       0-15  translates to 0-99 for DX7
        B_FootCtrlAssign: byte;           //       0-7
        B_AfterTouchSens: byte;           //       0-15  translates to 0-99 for DX7
        B_AfterTouchAssign: byte;         //       0-7
        B_BrthCtrlSens: byte;             //       0-15  translates to 0-99 for DX7
        B_BrthCtrlAssign: byte;           //       0-7
        B_KeyIndividualAftTchSens: byte;  //DX5    0-15
        B_KIAT_OP1_Sens: byte;            //DX5    0-15
        B_KIAT_OP2_Sens: byte;            //DX5    0-15
        B_KIAT_OP3_Sens: byte;            //DX5    0-15
        B_KIAT_OP4_Sens: byte;            //DX5    0-15
        B_KIAT_OP5_Sens: byte;            //DX5    0-15
        B_KIAT_OP6_Sens: byte;            //DX5    0-15
        B_KIAT_DecayRate: byte;           //DX5    0-99
        B_KIAT_ReleaseRate: byte;         //DX5    0-99
        B_VoiceAttn: byte;                //       0-7  translates to 0-99 for DX7
        B_ProgramOutput: byte;            //DX5    0-1
        B_SustainPedal: byte;             //DX5    0-1
        B_PerfKeyShift: byte;             //DX5    0-48  center=24

        G_KeyAssignMode: byte;            //DX5    0-2   0,1,2 = single, dual, split
        G_VoiceMemSelFlag: byte;          //       0-1   if KMOD=0: VMS=0 > Voice A plays; VMS=1 Voice B plays
        G_DualModeDetune: byte;           //DX5    0-15
        G_SplitPoint: byte;               //DX5    0-99
        G_PerfName01: byte;               //       ASCII
        G_PerfName02: byte;               //       ASCII
        G_PerfName03: byte;               //       ASCII
        G_PerfName04: byte;               //       ASCII
        G_PerfName05: byte;               //       ASCII
        G_PerfName06: byte;               //       ASCII
        G_PerfName07: byte;               //       ASCII
        G_PerfName08: byte;               //       ASCII
        G_PerfName09: byte;               //       ASCII
        G_PerfName10: byte;               //       ASCII
        G_PerfName11: byte;               //       ASCII
        G_PerfName12: byte;               //       ASCII
        G_PerfName13: byte;               //       ASCII
        G_PerfName14: byte;               //       ASCII
        G_PerfName15: byte;               //       ASCII
        G_PerfName16: byte;               //       ASCII
        G_PerfName17: byte;               //       ASCII
        G_PerfName18: byte;               //       ASCII
        G_PerfName19: byte;               //       ASCII
        G_PerfName20: byte;               //       ASCII
        G_PerfName21: byte;               //       ASCII
        G_PerfName22: byte;               //       ASCII
        G_PerfName23: byte;               //       ASCII
        G_PerfName24: byte;               //       ASCII
        G_PerfName25: byte;               //       ASCII
        G_PerfName26: byte;               //       ASCII
        G_PerfName27: byte;               //       ASCII
        G_PerfName28: byte;               //       ASCII
        G_PerfName29: byte;               //       ASCII
        G_PerfName30: byte;               //       ASCII
      )
  end;

  TTX7_PMEM_Params = packed record
    case boolean of
      True: (params: TTX7_PMEM_Dump);
      False: (
                                          //     |    |    |    |    |    |    |    |
        A_PolyMono: byte;                 //     | PM |    Undocumented: Voice Nr.  |
        A_PBSlo_PBR: byte;                //     |    PBS Lo    |        PBR        |
        A_PortaTime: byte;                //     |  0-99                            |
        A_PM_PGL: byte;                   //     | 0  |              | PP | M  | GL |    PortamentoPedal, source JSynthLib
        A_MWA_MWS: byte;                  //     |     MWA      |        MWS        |
        A_FCA_FCS: byte;                  //     |     FCA      |        FCS        |
        A_ATA_ATS: byte;                  //     |     ATA      |        ATS        |
        A_BCA_BCS: byte;                  //     |     BCA      |        BCS        |
        A_NU08: byte;
        A_NU09: byte;
        A_NU10: byte;
        A_NU11: byte;
        A_NU12: byte;
        A_NU13: byte;
        A_ATN: byte;                      //     | 0 |               |    ATN       |
        A_PBShi: byte;                    //     | PS|                              |  PitchBendStep, Bit4

        B_PolyMono: byte;                 //     | PM |    Undocumented: Voice Nr.  |
        B_PBSlo_PBR: byte;                //     |    PBS Lo    |        PBR        |
        B_PortaTime: byte;                //     |  0-99                            |
        B_PM_PGL: byte;                   //     | 0  |                   | M  | GL |
        B_MWA_MWS: byte;                  //     |     MWA      |        MWS        |
        B_FCA_FCS: byte;                  //     |     FCA      |        FCS        |
        B_ATA_ATS: byte;                  //     |     ATA      |        ATS        |
        B_BCA_BCS: byte;                  //     |     BCA      |        BCS        |
        B_NU08: byte;
        B_NU09: byte;
        B_NU10: byte;
        B_NU11: byte;
        B_NU12: byte;
        B_NU13: byte;
        B_ATN: byte;                      //     | 0 |               |    ATN       |
        B_PBShi: byte;                    //     | PS|                              |  PitchBendStep, Bit4

        G_VMS_KMOD: byte;                 //     | 0 |      DMD     | VMS|   KMOD   |  DualModeDetune, source JSynthLib
        G_SplitPoint: byte;               //       Just a blind guess
        G_PerfName01: byte;               //       ASCII
        G_PerfName02: byte;               //       ASCII
        G_PerfName03: byte;               //       ASCII
        G_PerfName04: byte;               //       ASCII
        G_PerfName05: byte;               //       ASCII
        G_PerfName06: byte;               //       ASCII
        G_PerfName07: byte;               //       ASCII
        G_PerfName08: byte;               //       ASCII
        G_PerfName09: byte;               //       ASCII
        G_PerfName10: byte;               //       ASCII
        G_PerfName11: byte;               //       ASCII
        G_PerfName12: byte;               //       ASCII
        G_PerfName13: byte;               //       ASCII
        G_PerfName14: byte;               //       ASCII
        G_PerfName15: byte;               //       ASCII
        G_PerfName16: byte;               //       ASCII
        G_PerfName17: byte;               //       ASCII
        G_PerfName18: byte;               //       ASCII
        G_PerfName19: byte;               //       ASCII
        G_PerfName20: byte;               //       ASCII
        G_PerfName21: byte;               //       ASCII
        G_PerfName22: byte;               //       ASCII
        G_PerfName23: byte;               //       ASCII
        G_PerfName24: byte;               //       ASCII
        G_PerfName25: byte;               //       ASCII
        G_PerfName26: byte;               //       ASCII
        G_PerfName27: byte;               //       ASCII
        G_PerfName28: byte;               //       ASCII
        G_PerfName29: byte;               //       ASCII
        G_PerfName30: byte;               //       ASCII
      )
  end;

type
  TTX7FunctionContainer = class(TPersistent)
  private
    FTX7_PCED_Params: TTX7_PCED_Params;
    FTX7_PMEM_Params: TTX7_PMEM_Params;
  public
    function Load_PMEM_FromStream(var aStream: TMemoryStream;
      Position: integer): boolean;
    function Load_PCED_FromStream(var aStream: TMemoryStream;
      Position: integer): boolean;
    procedure InitFunction; //set defaults
    function Get_PMEM_Params: TTX7_PMEM_Params;
    function Get_PCED_Params: TTX7_PCED_Params;
    function Set_PMEM_Params(aParams: TTX7_PMEM_Params): boolean;
    function Save_PMEM_ToStream(var aStream: TMemoryStream): boolean;
    function Save_PCED_ToStream(var aStream: TMemoryStream): boolean;
    function Add_PCED_ToStream(var aStream: TMemoryStream): boolean;
    function FunctIsInit: boolean;
    function GetChecksumPart: integer;
    function GetChecksum: integer;
    function GetFunctionName: string;
    procedure SysExFunctionToStream(aCh: integer; var aStream: TMemoryStream);
    {$IFNDEF CMDLINE}
    function CalculateHash: string;
    {$ENDIF}
  end;

function PCEDtoPMEM(aPar: TTX7_PCED_Params): TTX7_PMEM_Params;
function PMEMtoPCED(aPar: TTX7_PMEM_Params): TTX7_PCED_Params;

implementation

function PCEDtoPMEM(aPar: TTX7_PCED_Params): TTX7_PMEM_Params;
var
  t: TTX7_PMEM_Params;
begin
  t.A_NU08 := 0;
  t.A_NU09 := 0;
  t.A_NU10 := 0;
  t.A_NU11 := 0;
  t.A_NU12 := 0;
  t.A_NU13 := 0;

  t.B_NU08 := 0;
  t.B_NU09 := 0;
  t.B_NU10 := 0;
  t.B_NU11 := 0;
  t.B_NU12 := 0;
  t.B_NU13 := 0;

  //first the parameters without conversion
  t.G_PerfName01 := aPar.G_PerfName01;
  t.G_PerfName02 := aPar.G_PerfName02;
  t.G_PerfName03 := aPar.G_PerfName03;
  t.G_PerfName04 := aPar.G_PerfName04;
  t.G_PerfName05 := aPar.G_PerfName05;
  t.G_PerfName06 := aPar.G_PerfName06;
  t.G_PerfName07 := aPar.G_PerfName07;
  t.G_PerfName08 := aPar.G_PerfName08;
  t.G_PerfName09 := aPar.G_PerfName09;
  t.G_PerfName10 := aPar.G_PerfName10;
  t.G_PerfName11 := aPar.G_PerfName11;
  t.G_PerfName12 := aPar.G_PerfName12;
  t.G_PerfName13 := aPar.G_PerfName13;
  t.G_PerfName14 := aPar.G_PerfName14;
  t.G_PerfName15 := aPar.G_PerfName15;
  t.G_PerfName16 := aPar.G_PerfName16;
  t.G_PerfName17 := aPar.G_PerfName17;
  t.G_PerfName18 := aPar.G_PerfName18;
  t.G_PerfName19 := aPar.G_PerfName19;
  t.G_PerfName20 := aPar.G_PerfName20;
  t.G_PerfName21 := aPar.G_PerfName21;
  t.G_PerfName22 := aPar.G_PerfName22;
  t.G_PerfName23 := aPar.G_PerfName23;
  t.G_PerfName24 := aPar.G_PerfName24;
  t.G_PerfName25 := aPar.G_PerfName25;
  t.G_PerfName26 := aPar.G_PerfName26;
  t.G_PerfName27 := aPar.G_PerfName27;
  t.G_PerfName28 := aPar.G_PerfName28;
  t.G_PerfName29 := aPar.G_PerfName29;
  t.G_PerfName30 := aPar.G_PerfName30;
  t.A_PortaTime := aPar.A_PortamentoTime;
  t.B_PortaTime := aPar.B_PortamentoTime;
  t.A_ATN := aPar.A_VoiceAttn;
  t.B_ATN := aPar.B_VoiceAttn;
  t.G_SplitPoint := aPar.G_SplitPoint;

  //now parameters with conversion
  t.A_PolyMono := (aPar.A_PolyMono shl 6) + (aPar.A_VoiceNr and 63);
  t.A_PBSlo_PBR := ((aPar.A_PitchBendStep and 7) shl 4) + aPar.A_PitchBendRange;
  t.A_PM_PGL := (aPar.A_PortamentoPedal shl 2) + (aPar.A_PortamentoMode shl 1) +
    aPar.A_PortaGlissando;
  t.A_MWA_MWS := (aPar.A_ModWheelAssign shl 4) + aPar.A_ModWheelSens;
  t.A_FCA_FCS := (aPar.A_FootCtrlAssign shl 4) + aPar.A_FootCtrlSens;
  t.A_ATA_ATS := (aPar.A_AfterTouchAssign shl 4) + aPar.A_AfterTouchSens;
  t.A_BCA_BCS := (aPar.A_BrthCtrlAssign shl 4) + aPar.A_BrthCtrlSens;
  t.A_PBShi := (aPar.A_PitchBendStep and 8) shl 6;

  t.B_PolyMono := (aPar.B_PolyMono shl 6) + (aPar.B_VoiceNr and 63);
  t.B_PBSlo_PBR := ((aPar.B_PitchBendStep and 7) shl 4) + aPar.B_PitchBendRange;
  t.B_PM_PGL := (aPar.B_PortamentoPedal shl 2) + (aPar.B_PortamentoMode shl 1) +
    aPar.B_PortaGlissando;
  t.B_MWA_MWS := (aPar.B_ModWheelAssign shl 4) + aPar.B_ModWheelSens;
  t.B_FCA_FCS := (aPar.B_FootCtrlAssign shl 4) + aPar.B_FootCtrlSens;
  t.B_ATA_ATS := (aPar.B_AfterTouchAssign shl 4) + aPar.B_AfterTouchSens;
  t.B_BCA_BCS := (aPar.B_BrthCtrlAssign shl 4) + aPar.B_BrthCtrlSens;
  t.B_PBShi := (aPar.B_PitchBendStep and 8) shl 6;

  t.G_VMS_KMOD := (aPar.G_DualModeDetune shl 3) + (aPar.G_VoiceMemSelFlag shl 2) +
    (aPar.G_KeyAssignMode);

  Result := t;
end;

function PMEMtoPCED(aPar: TTX7_PMEM_Params): TTX7_PCED_Params;
var
  t: TTX7_PCED_Params;
begin

  t.A_KeyIndividualAftTchSens := 0;
  t.A_KIAT_OP1_Sens := 0;
  t.A_KIAT_OP2_Sens := 0;
  t.A_KIAT_OP3_Sens := 0;
  t.A_KIAT_OP4_Sens := 0;
  t.A_KIAT_OP5_Sens := 0;
  t.A_KIAT_OP6_Sens := 0;
  t.A_KIAT_DecayRate := 0;
  t.A_KIAT_ReleaseRate := 0;
  t.A_ProgramOutput := 0;
  t.A_SustainPedal := 0;
  t.A_PerfKeyShift := 0;

  t.B_KeyIndividualAftTchSens := 0;
  t.B_KIAT_OP1_Sens := 0;
  t.B_KIAT_OP2_Sens := 0;
  t.B_KIAT_OP3_Sens := 0;
  t.B_KIAT_OP4_Sens := 0;
  t.B_KIAT_OP5_Sens := 0;
  t.B_KIAT_OP6_Sens := 0;
  t.B_KIAT_DecayRate := 0;
  t.B_KIAT_ReleaseRate := 0;
  t.B_ProgramOutput := 0;
  t.B_SustainPedal := 0;
  t.B_PerfKeyShift := 0;

  //first the parameters without conversion
  t.G_PerfName01 := aPar.G_PerfName01;
  t.G_PerfName02 := aPar.G_PerfName02;
  t.G_PerfName03 := aPar.G_PerfName03;
  t.G_PerfName04 := aPar.G_PerfName04;
  t.G_PerfName05 := aPar.G_PerfName05;
  t.G_PerfName06 := aPar.G_PerfName06;
  t.G_PerfName07 := aPar.G_PerfName07;
  t.G_PerfName08 := aPar.G_PerfName08;
  t.G_PerfName09 := aPar.G_PerfName09;
  t.G_PerfName10 := aPar.G_PerfName10;
  t.G_PerfName11 := aPar.G_PerfName11;
  t.G_PerfName12 := aPar.G_PerfName12;
  t.G_PerfName13 := aPar.G_PerfName13;
  t.G_PerfName14 := aPar.G_PerfName14;
  t.G_PerfName15 := aPar.G_PerfName15;
  t.G_PerfName16 := aPar.G_PerfName16;
  t.G_PerfName17 := aPar.G_PerfName17;
  t.G_PerfName18 := aPar.G_PerfName18;
  t.G_PerfName19 := aPar.G_PerfName19;
  t.G_PerfName20 := aPar.G_PerfName20;
  t.G_PerfName21 := aPar.G_PerfName21;
  t.G_PerfName22 := aPar.G_PerfName22;
  t.G_PerfName23 := aPar.G_PerfName23;
  t.G_PerfName24 := aPar.G_PerfName24;
  t.G_PerfName25 := aPar.G_PerfName25;
  t.G_PerfName26 := aPar.G_PerfName26;
  t.G_PerfName27 := aPar.G_PerfName27;
  t.G_PerfName28 := aPar.G_PerfName28;
  t.G_PerfName29 := aPar.G_PerfName29;
  t.G_PerfName30 := aPar.G_PerfName30;
  t.A_PortamentoTime := aPar.A_PortaTime and 127;
  t.B_PortamentoTime := aPar.B_PortaTime and 127;
  t.A_VoiceAttn := aPar.A_ATN and 7;
  t.B_VoiceAttn := aPar.B_ATN and 7;
  t.G_SplitPoint := aPar.G_SplitPoint;

  t.A_PolyMono := (aPar.A_PolyMono and 64) shr 6;
  t.A_VoiceNr := aPar.A_PolyMono and 63;
  t.A_PitchBendStep := ((aPar.A_PBShi and 64) shr 3) +
    ((aPar.A_PBSlo_PBR and 112) shr 4);
  t.A_PitchBendRange := aPar.A_PBSlo_PBR and 15;
  t.A_PortamentoMode := (aPar.A_PM_PGL shr 1) and 1;
  t.A_PortaGlissando := aPar.A_PM_PGL and 1;
  t.A_PortamentoPedal := (aPar.A_PM_PGL shr 2) and 1;
  t.A_ModWheelSens := aPar.A_MWA_MWS and 15;
  t.A_ModWheelAssign := aPar.A_MWA_MWS shr 4;
  t.A_FootCtrlSens := aPar.A_FCA_FCS and 15;
  t.A_FootCtrlAssign := aPar.A_FCA_FCS shr 4;
  t.A_AfterTouchSens := aPar.A_ATA_ATS and 15;
  t.A_AfterTouchAssign := aPar.A_ATA_ATS shr 4;
  t.A_BrthCtrlSens := aPar.A_BCA_BCS and 15;
  t.A_BrthCtrlAssign := aPar.A_BCA_BCS shr 4;

  t.B_PolyMono := (aPar.B_PolyMono and 64) shr 6;
  t.B_VoiceNr := aPar.B_PolyMono and 63;
  t.B_PitchBendStep := ((aPar.B_PBShi and 64) shr 3) +
    ((aPar.B_PBSlo_PBR and 112) shr 4);
  t.B_PitchBendRange := aPar.B_PBSlo_PBR and 15;
  t.B_PortamentoMode := (aPar.B_PM_PGL shr 1) and 1;
  t.B_PortaGlissando := aPar.B_PM_PGL and 1;
  t.B_PortamentoPedal := (aPar.B_PM_PGL shr 2) and 1;
  t.B_ModWheelSens := aPar.B_MWA_MWS and 15;
  t.B_ModWheelAssign := aPar.B_MWA_MWS shr 4;
  t.B_FootCtrlSens := aPar.B_FCA_FCS and 15;
  t.B_FootCtrlAssign := aPar.B_FCA_FCS shr 4;
  t.B_AfterTouchSens := aPar.B_ATA_ATS and 15;
  t.B_AfterTouchAssign := aPar.B_ATA_ATS shr 4;
  t.B_BrthCtrlSens := aPar.B_BCA_BCS and 15;
  t.B_BrthCtrlAssign := aPar.B_BCA_BCS shr 4;

  t.G_VoiceMemSelFlag := (aPar.G_VMS_KMOD shr 2) and 1;
  t.G_KeyAssignMode := aPar.G_VMS_KMOD and 3;
  t.G_DualModeDetune := (aPar.G_VMS_KMOD shr 3) and 15;
  Result := t;
end;

function TTX7FunctionContainer.Load_PMEM_FromStream(var aStream: TMemoryStream;
  Position: integer): boolean;
var
  i: integer;
begin
  Result := False;
  if (Position + 63) <= aStream.Size then
    aStream.Position := Position
  else
    Exit;
  try
    for i := 0 to 63 do
      FTX7_PMEM_Params.params[i] := aStream.ReadByte;

    FTX7_PCED_Params := PMEMtoPCED(FTX7_PMEM_Params);
    Result := True;
  except
    Result := False;
  end;
end;

function TTX7FunctionContainer.Load_PCED_FromStream(var aStream: TMemoryStream;
  Position: integer): boolean;
var
  i: integer;
begin
  Result := False;
  if (Position + 93) <= aStream.Size then
    aStream.Position := Position
  else
    Exit;
  try
    for i := 0 to 93 do
      FTX7_PCED_Params.params[i] := aStream.ReadByte;

    FTX7_PMEM_Params := PCEDtoPMEM(FTX7_PCED_Params);
    Result := True;
  except
    Result := False;
  end;
end;

procedure TTX7FunctionContainer.InitFunction;
begin
  GetDefinedValues(TX7, fInit, FTX7_PCED_Params.params);
  FTX7_PMEM_Params := PCEDtoPMEM(FTX7_PCED_Params);
end;

function TTX7FunctionContainer.Get_PMEM_Params: TTX7_PMEM_Params;
begin
  Result := FTX7_PMEM_Params;
end;

function TTX7FunctionContainer.Get_PCED_Params: TTX7_PCED_Params;
begin
  Result := FTX7_PCED_Params;
end;

function TTX7FunctionContainer.Set_PMEM_Params(aParams: TTX7_PMEM_Params): boolean;
begin
  FTX7_PMEM_Params := aParams;
  FTX7_PCED_Params := PMEMtoPCED(FTX7_PMEM_Params);
  Result := True;
end;

function TTX7FunctionContainer.Save_PMEM_ToStream(var aStream: TMemoryStream): boolean;
var
  i: integer;
begin
  //dont clear the stream here or else bulk dump won't work
  if Assigned(aStream) then
  begin
    for i := 0 to 63 do
      aStream.WriteByte(FTX7_PMEM_Params.params[i]);
    Result := True;
  end
  else
    Result := False;
end;

function TTX7FunctionContainer.Save_PCED_ToStream(var aStream: TMemoryStream): boolean;
var
  i: integer;
begin
  if Assigned(aStream) then
  begin
    aStream.Clear;
    for i := 0 to 93 do
      aStream.WriteByte(FTX7_PCED_Params.params[i]);
    Result := True;
  end
  else
    Result := False;
end;

function TTX7FunctionContainer.Add_PCED_ToStream(var aStream: TMemoryStream): boolean;
var
  i: integer;
begin
  if Assigned(aStream) then
  begin
    for i := 0 to 93 do
      aStream.WriteByte(FTX7_PCED_Params.params[i]);
    Result := True;
  end
  else
    Result := False;
end;

{$IFNDEF CMDLINE}
function TTX7FunctionContainer.CalculateHash: string;
var
  aStream: TMemoryStream;
  i: integer;
begin
  aStream := TMemoryStream.Create;
  for i := 0 to 63 do
    aStream.WriteByte(FTX7_PCED_Params.params[i]);
  aStream.Position := 0;
  Result := THashFactory.TCrypto.CreateSHA2_256().ComputeStream(aStream).ToString();
  aStream.Free;
end;
{$ENDIF}

function TTX7FunctionContainer.FunctIsInit: boolean;
var
  init: TTX7_PCED_Dump;
begin
  GetDefinedValues(TX7, finit, init);
  Result := SameArrays(FTX7_PCED_Params.params, init);
end;

function TTX7FunctionContainer.GetChecksumPart: integer;
var
  checksum: integer;
  i: integer;
  tmpStream: TMemoryStream;
begin
  checksum := 0;
  tmpStream := TMemoryStream.Create;
  Save_PMEM_ToStream(tmpStream);
  tmpStream.Position := 0;
  for i := 0 to tmpStream.Size - 1 do
    checksum := checksum + tmpStream.ReadByte;
  Result := checksum;
  tmpStream.Free;
end;

function TTX7FunctionContainer.GetChecksum: integer;
var
  checksum: integer;
begin
  checksum := 0;
  try
    checksum := GetChecksumPart;
    Result := ((not (checksum and 255)) and 127) + 1;
  except
    on e: Exception do Result := 0;
  end;
end;

function TTX7FunctionContainer.GetFunctionName: string;
var
  s: string;
begin
  s := '';
  s := s + Printable(chr(FTX7_PMEM_Params.G_PerfName01));
  s := s + Printable(chr(FTX7_PMEM_Params.G_PerfName02));
  s := s + Printable(chr(FTX7_PMEM_Params.G_PerfName03));
  s := s + Printable(chr(FTX7_PMEM_Params.G_PerfName04));
  s := s + Printable(chr(FTX7_PMEM_Params.G_PerfName05));
  s := s + Printable(chr(FTX7_PMEM_Params.G_PerfName06));
  s := s + Printable(chr(FTX7_PMEM_Params.G_PerfName07));
  s := s + Printable(chr(FTX7_PMEM_Params.G_PerfName08));
  s := s + Printable(chr(FTX7_PMEM_Params.G_PerfName09));
  s := s + Printable(chr(FTX7_PMEM_Params.G_PerfName10));
  s := s + Printable(chr(FTX7_PMEM_Params.G_PerfName11));
  s := s + Printable(chr(FTX7_PMEM_Params.G_PerfName12));
  s := s + Printable(chr(FTX7_PMEM_Params.G_PerfName13));
  s := s + Printable(chr(FTX7_PMEM_Params.G_PerfName14));
  s := s + Printable(chr(FTX7_PMEM_Params.G_PerfName15));
  s := s + Printable(chr(FTX7_PMEM_Params.G_PerfName16));
  s := s + Printable(chr(FTX7_PMEM_Params.G_PerfName17));
  s := s + Printable(chr(FTX7_PMEM_Params.G_PerfName18));
  s := s + Printable(chr(FTX7_PMEM_Params.G_PerfName19));
  s := s + Printable(chr(FTX7_PMEM_Params.G_PerfName20));
  s := s + Printable(chr(FTX7_PMEM_Params.G_PerfName21));
  s := s + Printable(chr(FTX7_PMEM_Params.G_PerfName22));
  s := s + Printable(chr(FTX7_PMEM_Params.G_PerfName23));
  s := s + Printable(chr(FTX7_PMEM_Params.G_PerfName24));
  s := s + Printable(chr(FTX7_PMEM_Params.G_PerfName25));
  s := s + Printable(chr(FTX7_PMEM_Params.G_PerfName26));
  s := s + Printable(chr(FTX7_PMEM_Params.G_PerfName27));
  s := s + Printable(chr(FTX7_PMEM_Params.G_PerfName28));
  s := s + Printable(chr(FTX7_PMEM_Params.G_PerfName29));
  s := s + Printable(chr(FTX7_PMEM_Params.G_PerfName30));
  Result := s;
end;

procedure TTX7FunctionContainer.SysExFunctionToStream(aCh: integer;
  var aStream: TMemoryStream);
var
  FCh: byte;
begin
  FCh := aCh - 1;
  aStream.Clear;
  aStream.Position := 0;
  aStream.WriteByte($F0);
  aStream.WriteByte($43);
  aStream.WriteByte($00 + FCh); //MIDI channel
  aStream.WriteByte($01);       //Function
  aStream.WriteByte($00);
  aStream.WriteByte($5E);
  Add_PCED_ToStream(aStream);
  aStream.WriteByte(GetChecksum);
  aStream.WriteByte($F7);
end;

end.
