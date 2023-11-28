{
 *****************************************************************************
  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************

 Author: Boban Spasic

 Unit description:
 Class implementing DX7 Voice Data and related functions for one Voice.


 - function GetChecksum implements the calculation of Checksum for one Voice.

 - function GetChecksumPart implements partial Checksum for use in calculating the
 checksum of a whole bank.

 - function CalculateHash is used for calculating a unique identifier for use
 in database storage.
 It does not take Voice Name into calculation, just the synth parameters.
 It is done on purpose to eliminite the dupplicates even if the names differ.
 It is not DX-related function.
}

unit untDX7Voice;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Math, untUtils, untParConst
  {$IFNDEF CMDLINE} , HlpHashFactory {$ENDIF}  ;

type
  TDX7_VMEM_Dump = array [0..127] of byte;
  TDX7_VCED_Dump = array [0..155] of byte;

type
  TDX7_VCED_Params = packed record
    case boolean of
      True: (params: TDX7_VCED_Dump);
      False: (
        OP6_EG_rate_1: byte;              //       0-99
        OP6_EG_rate_2: byte;              //       0-99
        OP6_EG_rate_3: byte;              //       0-99
        OP6_EG_rate_4: byte;              //       0-99
        OP6_EG_level_1: byte;             //       0-99
        OP6_EG_level_2: byte;             //       0-99
        OP6_EG_level_3: byte;             //       0-99
        OP6_EG_level_4: byte;             //       0-99
        OP6_KBD_LEV_SCL_BRK_PT: byte;     //       0-99   C3= $27
        OP6_KBD_LEV_SCL_LFT_DEPTH: byte;  //       0-99   C3= $27
        OP6_KBD_LEV_SCL_RHT_DEPTH: byte;  //       0-99   C3= $27
        OP6_KBD_LEV_SCL_LFT_CURVE: byte;  //       0-3    0=-LIN, -EXP, +EXP, +LIN
        OP6_KBD_LEV_SCL_RHT_CURVE: byte;  //       0-3    0=-LIN, -EXP, +EXP, +LIN
        OP6_KBD_RATE_SCALING: byte;       //       0-7
        OP6_AMP_MOD_SENSITIVITY: byte;    //       0-3
        OP6_KEY_VEL_SENSITIVITY: byte;    //       0-7
        OP6_OPERATOR_OUTPUT_LEVEL: byte;  //       0-99
        OP6_OSC_MODE: byte;               //       0-1    (fixed/ratio)   0=ratio
        OP6_OSC_FREQ_COARSE: byte;        //       0-31
        OP6_OSC_FREQ_FINE: byte;          //       0-99
        OP6_OSC_DETUNE: byte;             //       0-14   0: det=-7
        OP5_EG_rate_1: byte;              //       0-99
        OP5_EG_rate_2: byte;              //       0-99
        OP5_EG_rate_3: byte;              //       0-99
        OP5_EG_rate_4: byte;              //       0-99
        OP5_EG_level_1: byte;             //       0-99
        OP5_EG_level_2: byte;             //       0-99
        OP5_EG_level_3: byte;             //       0-99
        OP5_EG_level_4: byte;             //       0-99
        OP5_KBD_LEV_SCL_BRK_PT: byte;     //       0-99   C3= $27
        OP5_KBD_LEV_SCL_LFT_DEPTH: byte;  //       0-99   C3= $27
        OP5_KBD_LEV_SCL_RHT_DEPTH: byte;  //       0-99   C3= $27
        OP5_KBD_LEV_SCL_LFT_CURVE: byte;  //       0-3    0=-LIN, -EXP, +EXP, +LIN
        OP5_KBD_LEV_SCL_RHT_CURVE: byte;  //       0-3    0=-LIN, -EXP, +EXP, +LIN
        OP5_KBD_RATE_SCALING: byte;       //       0-7
        OP5_AMP_MOD_SENSITIVITY: byte;    //       0-3
        OP5_KEY_VEL_SENSITIVITY: byte;    //       0-7
        OP5_OPERATOR_OUTPUT_LEVEL: byte;  //       0-99
        OP5_OSC_MODE: byte;               //       0-1    (fixed/ratio)   0=ratio
        OP5_OSC_FREQ_COARSE: byte;        //       0-31
        OP5_OSC_FREQ_FINE: byte;          //       0-99
        OP5_OSC_DETUNE: byte;             //       0-14   0: det=-7
        OP4_EG_rate_1: byte;              //       0-99
        OP4_EG_rate_2: byte;              //       0-99
        OP4_EG_rate_3: byte;              //       0-99
        OP4_EG_rate_4: byte;              //       0-99
        OP4_EG_level_1: byte;             //       0-99
        OP4_EG_level_2: byte;             //       0-99
        OP4_EG_level_3: byte;             //       0-99
        OP4_EG_level_4: byte;             //       0-99
        OP4_KBD_LEV_SCL_BRK_PT: byte;     //       0-99   C3= $27
        OP4_KBD_LEV_SCL_LFT_DEPTH: byte;  //       0-99   C3= $27
        OP4_KBD_LEV_SCL_RHT_DEPTH: byte;  //       0-99   C3= $27
        OP4_KBD_LEV_SCL_LFT_CURVE: byte;  //       0-3    0=-LIN, -EXP, +EXP, +LIN
        OP4_KBD_LEV_SCL_RHT_CURVE: byte;  //       0-3    0=-LIN, -EXP, +EXP, +LIN
        OP4_KBD_RATE_SCALING: byte;       //       0-7
        OP4_AMP_MOD_SENSITIVITY: byte;    //       0-3
        OP4_KEY_VEL_SENSITIVITY: byte;    //       0-7
        OP4_OPERATOR_OUTPUT_LEVEL: byte;  //       0-99
        OP4_OSC_MODE: byte;               //       0-1    (fixed/ratio)   0=ratio
        OP4_OSC_FREQ_COARSE: byte;        //       0-31
        OP4_OSC_FREQ_FINE: byte;          //       0-99
        OP4_OSC_DETUNE: byte;             //       0-14   0: det=-7
        OP3_EG_rate_1: byte;              //       0-99
        OP3_EG_rate_2: byte;              //       0-99
        OP3_EG_rate_3: byte;              //       0-99
        OP3_EG_rate_4: byte;              //       0-99
        OP3_EG_level_1: byte;             //       0-99
        OP3_EG_level_2: byte;             //       0-99
        OP3_EG_level_3: byte;             //       0-99
        OP3_EG_level_4: byte;             //       0-99
        OP3_KBD_LEV_SCL_BRK_PT: byte;     //       0-99   C3= $27
        OP3_KBD_LEV_SCL_LFT_DEPTH: byte;  //       0-99   C3= $27
        OP3_KBD_LEV_SCL_RHT_DEPTH: byte;  //       0-99   C3= $27
        OP3_KBD_LEV_SCL_LFT_CURVE: byte;  //       0-3    0=-LIN, -EXP, +EXP, +LIN
        OP3_KBD_LEV_SCL_RHT_CURVE: byte;  //       0-3    0=-LIN, -EXP, +EXP, +LIN
        OP3_KBD_RATE_SCALING: byte;       //       0-7
        OP3_AMP_MOD_SENSITIVITY: byte;    //       0-3
        OP3_KEY_VEL_SENSITIVITY: byte;    //       0-7
        OP3_OPERATOR_OUTPUT_LEVEL: byte;  //       0-99
        OP3_OSC_MODE: byte;               //       0-1    (fixed/ratio)   0=ratio
        OP3_OSC_FREQ_COARSE: byte;        //       0-31
        OP3_OSC_FREQ_FINE: byte;          //       0-99
        OP3_OSC_DETUNE: byte;             //       0-14   0: det=-7
        OP2_EG_rate_1: byte;              //       0-99
        OP2_EG_rate_2: byte;              //       0-99
        OP2_EG_rate_3: byte;              //       0-99
        OP2_EG_rate_4: byte;              //       0-99
        OP2_EG_level_1: byte;             //       0-99
        OP2_EG_level_2: byte;             //       0-99
        OP2_EG_level_3: byte;             //       0-99
        OP2_EG_level_4: byte;             //       0-99
        OP2_KBD_LEV_SCL_BRK_PT: byte;     //       0-99   C3= $27
        OP2_KBD_LEV_SCL_LFT_DEPTH: byte;  //       0-99   C3= $27
        OP2_KBD_LEV_SCL_RHT_DEPTH: byte;  //       0-99   C3= $27
        OP2_KBD_LEV_SCL_LFT_CURVE: byte;  //       0-3    0=-LIN, -EXP, +EXP, +LIN
        OP2_KBD_LEV_SCL_RHT_CURVE: byte;  //       0-3    0=-LIN, -EXP, +EXP, +LIN
        OP2_KBD_RATE_SCALING: byte;       //       0-7
        OP2_AMP_MOD_SENSITIVITY: byte;    //       0-3
        OP2_KEY_VEL_SENSITIVITY: byte;    //       0-7
        OP2_OPERATOR_OUTPUT_LEVEL: byte;  //       0-99
        OP2_OSC_MODE: byte;               //       0-1    (fixed/ratio)   0=ratio
        OP2_OSC_FREQ_COARSE: byte;        //       0-31
        OP2_OSC_FREQ_FINE: byte;          //       0-99
        OP2_OSC_DETUNE: byte;             //       0-14   0: det=-7
        OP1_EG_rate_1: byte;              //       0-99
        OP1_EG_rate_2: byte;              //       0-99
        OP1_EG_rate_3: byte;              //       0-99
        OP1_EG_rate_4: byte;              //       0-99
        OP1_EG_level_1: byte;             //       0-99
        OP1_EG_level_2: byte;             //       0-99
        OP1_EG_level_3: byte;             //       0-99
        OP1_EG_level_4: byte;             //       0-99
        OP1_KBD_LEV_SCL_BRK_PT: byte;     //       0-99   C3= $27
        OP1_KBD_LEV_SCL_LFT_DEPTH: byte;  //       0-99   C3= $27
        OP1_KBD_LEV_SCL_RHT_DEPTH: byte;  //       0-99   C3= $27
        OP1_KBD_LEV_SCL_LFT_CURVE: byte;  //       0-3    0=-LIN, -EXP, +EXP, +LIN
        OP1_KBD_LEV_SCL_RHT_CURVE: byte;  //       0-3    0=-LIN, -EXP, +EXP, +LIN
        OP1_KBD_RATE_SCALING: byte;       //       0-7
        OP1_AMP_MOD_SENSITIVITY: byte;    //       0-3
        OP1_KEY_VEL_SENSITIVITY: byte;    //       0-7
        OP1_OPERATOR_OUTPUT_LEVEL: byte;  //       0-99
        OP1_OSC_MODE: byte;               //       0-1    (fixed/ratio)   0=ratio
        OP1_OSC_FREQ_COARSE: byte;        //       0-31
        OP1_OSC_FREQ_FINE: byte;          //       0-99
        OP1_OSC_DETUNE: byte;             //       0-14   0: det=-7

        PITCH_EG_RATE_1: byte;            //       0-99
        PITCH_EG_RATE_2: byte;            //       0-99
        PITCH_EG_RATE_3: byte;            //       0-99
        PITCH_EG_RATE_4: byte;            //       0-99
        PITCH_EG_LEVEL_1: byte;           //       0-99
        PITCH_EG_LEVEL_2: byte;           //       0-99
        PITCH_EG_LEVEL_3: byte;           //       0-99
        PITCH_EG_LEVEL_4: byte;           //       0-99
        ALGORITHM: byte;                  //       0-31
        FEEDBACK: byte;                   //       0-7
        OSCILLATOR_SYNC: byte;            //       0-1
        LFO_SPEED: byte;                  //       0-99
        LFO_DELAY: byte;                  //       0-99
        LFO_PITCH_MOD_DEPTH: byte;        //       0-99
        LFO_AMP_MOD_DEPTH: byte;          //       0-99
        LFO_SYNC: byte;                   //       0-1
        LFO_WAVEFORM: byte;               //       0-5, (data sheet claims 9-4 ?!?)
                                          //       0:TR, 1:SD, 2:SU,
                                          //       3:SQ, 4:SI, 5:SH
        PITCH_MOD_SENSITIVITY: byte;      //       0-7
        TRANSPOSE: byte;                  //       0-48   12 = C2
        VOICE_NAME_CHAR_1: byte;          //       ASCII
        VOICE_NAME_CHAR_2: byte;          //       ASCII
        VOICE_NAME_CHAR_3: byte;          //       ASCII
        VOICE_NAME_CHAR_4: byte;          //       ASCII
        VOICE_NAME_CHAR_5: byte;          //       ASCII
        VOICE_NAME_CHAR_6: byte;          //       ASCII
        VOICE_NAME_CHAR_7: byte;          //       ASCII
        VOICE_NAME_CHAR_8: byte;          //       ASCII
        VOICE_NAME_CHAR_9: byte;          //       ASCII
        VOICE_NAME_CHAR_10: byte;         //       ASCII
        OPERATOR_ON_OFF: byte;            //       bit6 = 0 / bit 5: OP1 / .. .
                                          //       ... / bit 0: OP6
      );
  end;

  TDX7_VMEM_Params = packed record
    case boolean of
      True: (params: TDX7_VMEM_Dump);
      False: (
        OP6_EG_rate_1: byte;              //       0-99
        OP6_EG_rate_2: byte;              //       0-99
        OP6_EG_rate_3: byte;              //       0-99
        OP6_EG_rate_4: byte;              //       0-99
        OP6_EG_level_1: byte;             //       0-99
        OP6_EG_level_2: byte;             //       0-99
        OP6_EG_level_3: byte;             //       0-99
        OP6_EG_level_4: byte;             //       0-99
        OP6_KBD_LEV_SCL_BRK_PT: byte;     //       0-99   C3= $27
        OP6_KBD_LEV_SCL_LFT_DEPTH: byte;  //       0-99   C3= $27
        OP6_KBD_LEV_SCL_RHT_DEPTH: byte;  //       0-99   C3= $27
        OP6_KBD_LEV_SCL_RC_LC: byte;      //  | 0   0   0 |  RC   |   LC  |
        OP6_OSC_DET_RS: byte;             //  |      DET      |     RS    |
        OP6_KVS_AMS: byte;                //  | 0   0 |    KVS    |  AMS  |
        OP6_OPERATOR_OUTPUT_LEVEL: byte;  //       0-99
        OP6_FC_M: byte;                   //  | 0 |         FC        | M |
        OP6_OSC_FREQ_FINE: byte;          //       0-99
        OP5_EG_rate_1: byte;              //       0-99
        OP5_EG_rate_2: byte;              //       0-99
        OP5_EG_rate_3: byte;              //       0-99
        OP5_EG_rate_4: byte;              //       0-99
        OP5_EG_level_1: byte;             //       0-99
        OP5_EG_level_2: byte;             //       0-99
        OP5_EG_level_3: byte;             //       0-99
        OP5_EG_level_4: byte;             //       0-99
        OP5_KBD_LEV_SCL_BRK_PT: byte;     //       0-99   C3= $27
        OP5_KBD_LEV_SCL_LFT_DEPTH: byte;  //       0-99   C3= $27
        OP5_KBD_LEV_SCL_RHT_DEPTH: byte;  //       0-99   C3= $27
        OP5_KBD_LEV_SCL_RC_LC: byte;      //  | 0   0   0 |  RC   |   LC  |
        OP5_OSC_DET_RS: byte;             //  |      DET      |     RS    |
        OP5_KVS_AMS: byte;                //  | 0   0 |    KVS    |  AMS  |
        OP5_OPERATOR_OUTPUT_LEVEL: byte;  //       0-99
        OP5_FC_M: byte;                   //  | 0 |         FC        | M |
        OP5_OSC_FREQ_FINE: byte;          //       0-99
        OP4_EG_rate_1: byte;              //       0-99
        OP4_EG_rate_2: byte;              //       0-99
        OP4_EG_rate_3: byte;              //       0-99
        OP4_EG_rate_4: byte;              //       0-99
        OP4_EG_level_1: byte;             //       0-99
        OP4_EG_level_2: byte;             //       0-99
        OP4_EG_level_3: byte;             //       0-99
        OP4_EG_level_4: byte;             //       0-99
        OP4_KBD_LEV_SCL_BRK_PT: byte;     //       0-99   C3= $27
        OP4_KBD_LEV_SCL_LFT_DEPTH: byte;  //       0-99   C3= $27
        OP4_KBD_LEV_SCL_RHT_DEPTH: byte;  //       0-99   C3= $27
        OP4_KBD_LEV_SCL_RC_LC: byte;      //  | 0   0   0 |  RC   |   LC  |
        OP4_OSC_DET_RS: byte;             //  |      DET      |     RS    |
        OP4_KVS_AMS: byte;                //  | 0   0 |    KVS    |  AMS  |
        OP4_OPERATOR_OUTPUT_LEVEL: byte;  //       0-99
        OP4_FC_M: byte;                   //  | 0 |         FC        | M |
        OP4_OSC_FREQ_FINE: byte;          //       0-99
        OP3_EG_rate_1: byte;              //       0-99
        OP3_EG_rate_2: byte;              //       0-99
        OP3_EG_rate_3: byte;              //       0-99
        OP3_EG_rate_4: byte;              //       0-99
        OP3_EG_level_1: byte;             //       0-99
        OP3_EG_level_2: byte;             //       0-99
        OP3_EG_level_3: byte;             //       0-99
        OP3_EG_level_4: byte;             //       0-99
        OP3_KBD_LEV_SCL_BRK_PT: byte;     //       0-99   C3= $27
        OP3_KBD_LEV_SCL_LFT_DEPTH: byte;  //       0-99   C3= $27
        OP3_KBD_LEV_SCL_RHT_DEPTH: byte;  //       0-99   C3= $27
        OP3_KBD_LEV_SCL_RC_LC: byte;      //  | 0   0   0 |  RC   |   LC  |
        OP3_OSC_DET_RS: byte;             //  |      DET      |     RS    |
        OP3_KVS_AMS: byte;                //  | 0   0 |    KVS    |  AMS  |
        OP3_OPERATOR_OUTPUT_LEVEL: byte;  //       0-99
        OP3_FC_M: byte;                   //  | 0 |         FC        | M |
        OP3_OSC_FREQ_FINE: byte;          //       0-99
        OP2_EG_rate_1: byte;              //       0-99
        OP2_EG_rate_2: byte;              //       0-99
        OP2_EG_rate_3: byte;              //       0-99
        OP2_EG_rate_4: byte;              //       0-99
        OP2_EG_level_1: byte;             //       0-99
        OP2_EG_level_2: byte;             //       0-99
        OP2_EG_level_3: byte;             //       0-99
        OP2_EG_level_4: byte;             //       0-99
        OP2_KBD_LEV_SCL_BRK_PT: byte;     //       0-99   C3= $27
        OP2_KBD_LEV_SCL_LFT_DEPTH: byte;  //       0-99   C3= $27
        OP2_KBD_LEV_SCL_RHT_DEPTH: byte;  //       0-99   C3= $27
        OP2_KBD_LEV_SCL_RC_LC: byte;      //  | 0   0   0 |  RC   |   LC  |
        OP2_OSC_DET_RS: byte;             //  |      DET      |     RS    |
        OP2_KVS_AMS: byte;                //  | 0   0 |    KVS    |  AMS  |
        OP2_OPERATOR_OUTPUT_LEVEL: byte;  //       0-99
        OP2_FC_M: byte;                   //  | 0 |         FC        | M |
        OP2_OSC_FREQ_FINE: byte;          //       0-99
        OP1_EG_rate_1: byte;              //       0-99
        OP1_EG_rate_2: byte;              //       0-99
        OP1_EG_rate_3: byte;              //       0-99
        OP1_EG_rate_4: byte;              //       0-99
        OP1_EG_level_1: byte;             //       0-99
        OP1_EG_level_2: byte;             //       0-99
        OP1_EG_level_3: byte;             //       0-99
        OP1_EG_level_4: byte;             //       0-99
        OP1_KBD_LEV_SCL_BRK_PT: byte;     //       0-99   C3= $27
        OP1_KBD_LEV_SCL_LFT_DEPTH: byte;  //       0-99   C3= $27
        OP1_KBD_LEV_SCL_RHT_DEPTH: byte;  //       0-99   C3= $27
        OP1_KBD_LEV_SCL_RC_LC: byte;      //  | 0   0   0 |  RC   |   LC  |
        OP1_OSC_DET_RS: byte;             //  |      DET      |     RS    |
        OP1_KVS_AMS: byte;                //  | 0   0 |    KVS    |  AMS  |
        OP1_OPERATOR_OUTPUT_LEVEL: byte;  //       0-99
        OP1_FC_M: byte;                   //  | 0 |         FC        | M |
        OP1_OSC_FREQ_FINE: byte;          //       0-99
        PITCH_EG_RATE_1: byte;            //       0-99
        PITCH_EG_RATE_2: byte;            //       0-99
        PITCH_EG_RATE_3: byte;            //       0-99
        PITCH_EG_RATE_4: byte;            //       0-99
        PITCH_EG_LEVEL_1: byte;           //       0-99
        PITCH_EG_LEVEL_2: byte;           //       0-99
        PITCH_EG_LEVEL_3: byte;           //       0-99
        PITCH_EG_LEVEL_4: byte;           //       0-99
        ALGORITHM: byte;                  //       0-31
        OSCSYNC_FEEDBACK: byte;           //   | 0   0   0 |OKS|    FB     |
        LFO_SPEED: byte;                  //       0-99
        LFO_DELAY: byte;                  //       0-99
        LFO_PITCH_MOD_DEPTH: byte;        //       0-99
        LFO_AMP_MOD_DEPTH: byte;          //       0-99
        PMS_WAVE_SYNC: byte;              //   |  LPMS |      LFW      |LKS|
        TRANSPOSE: byte;                  //       0-48   12 = C2
        VOICE_NAME_CHAR_1: byte;          //       ASCII
        VOICE_NAME_CHAR_2: byte;          //       ASCII
        VOICE_NAME_CHAR_3: byte;          //       ASCII
        VOICE_NAME_CHAR_4: byte;          //       ASCII
        VOICE_NAME_CHAR_5: byte;          //       ASCII
        VOICE_NAME_CHAR_6: byte;          //       ASCII
        VOICE_NAME_CHAR_7: byte;          //       ASCII
        VOICE_NAME_CHAR_8: byte;          //       ASCII
        VOICE_NAME_CHAR_9: byte;          //       ASCII
        VOICE_NAME_CHAR_10: byte;         //       ASCII
      );
  end;

type
  TDX7VoiceContainer = class(TPersistent)
  private
    FDX7_VCED_Params: TDX7_VCED_Params;
    FDX7_VMEM_Params: TDX7_VMEM_Params;
  public
    function Load_VMEM_FromStream(var aStream: TMemoryStream; Position: integer): boolean;
    function Load_VCED_FromStream(var aStream: TMemoryStream; Position: integer): boolean;
    procedure InitVoice; //set defaults
    function GetVoiceName: string;
    procedure SetVoiceName(aName: string);
    function Get_VMEM_Params: TDX7_VMEM_Params;
    function Get_VCED_Params: TDX7_VCED_Params;
    function Set_VMEM_Params(aParams: TDX7_VMEM_Params): boolean;
    function Set_VCED_Params(aParams: TDX7_VCED_Params): boolean;
    function Save_VMEM_ToStream(var aStream: TMemoryStream): boolean;
    function Save_VCED_ToStream(var aStream: TMemoryStream): boolean;
    function Add_VCED_ToStream(var aStream: TMemoryStream): boolean;
    function GetChecksumPart: integer;
    function GetChecksum: integer;
    function GetVCEDChecksum: byte;
    procedure SysExVoiceToStream(aCh: integer; var aStream: TMemoryStream);
    {$IFNDEF CMDLINE}
    function CalculateHash: string;
    {$ENDIF}
    function CheckMinMax(var slReport: TStringList): boolean;
    function HasNullInName: boolean;
    procedure Normalize;
    procedure Mk2ToMk1(aPEGR, aAMS1, aAMS2, aAMS3, aAMS4, aAMS5, aAMS6: byte);
    procedure Mk2ToMk1(aPEGR, aAMS1, aAMS2, aAMS3, aAMS4, aAMS5, aAMS6: byte; aAMS_table: TAMS; aPEGR_table: TPEGR); overload;
  end;

function VCEDtoVMEM(aPar: TDX7_VCED_Params): TDX7_VMEM_Params;
function VMEMtoVCED(aPar: TDX7_VMEM_Params): TDX7_VCED_Params;

implementation

function VCEDtoVMEM(aPar: TDX7_VCED_Params): TDX7_VMEM_Params;
var
  t: TDX7_VMEM_Params;
begin
  //first the parameters without conversion
  t.OP6_EG_rate_1 := aPar.OP6_EG_rate_1 and 127;
  t.OP6_EG_rate_2 := aPar.OP6_EG_rate_2 and 127;
  t.OP6_EG_rate_3 := aPar.OP6_EG_rate_3 and 127;
  t.OP6_EG_rate_4 := aPar.OP6_EG_rate_4 and 127;
  t.OP6_EG_level_1 := aPar.OP6_EG_level_1 and 127;
  t.OP6_EG_level_2 := aPar.OP6_EG_level_2 and 127;
  t.OP6_EG_level_3 := aPar.OP6_EG_level_3 and 127;
  t.OP6_EG_level_4 := aPar.OP6_EG_level_4 and 127;
  t.OP6_KBD_LEV_SCL_BRK_PT := aPar.OP6_KBD_LEV_SCL_BRK_PT and 127;
  t.OP6_KBD_LEV_SCL_LFT_DEPTH := aPar.OP6_KBD_LEV_SCL_LFT_DEPTH and 127;
  t.OP6_KBD_LEV_SCL_RHT_DEPTH := aPar.OP6_KBD_LEV_SCL_RHT_DEPTH and 127;
  t.OP6_OPERATOR_OUTPUT_LEVEL := aPar.OP6_OPERATOR_OUTPUT_LEVEL and 127;
  t.OP6_OSC_FREQ_FINE := aPar.OP6_OSC_FREQ_FINE and 127;
  //now parameters with conversion
  t.OP6_KBD_LEV_SCL_RC_LC :=
    ((aPar.OP6_KBD_LEV_SCL_RHT_CURVE shl 2) and 12) +
    (aPar.OP6_KBD_LEV_SCL_LFT_CURVE and 3);
  t.OP6_OSC_DET_RS := ((aPar.OP6_OSC_DETUNE shl 3) and 120) +
    (aPar.OP6_KBD_RATE_SCALING and 7);
  t.OP6_KVS_AMS := ((aPar.OP6_KEY_VEL_SENSITIVITY shl 2) and 28) +
    (aPar.OP6_AMP_MOD_SENSITIVITY and 3);
  t.OP6_FC_M := ((aPar.OP6_OSC_FREQ_COARSE shl 1) and 62) + (aPar.OP6_OSC_MODE and 1);

  //first the parameters without conversion
  t.OP5_EG_rate_1 := aPar.OP5_EG_rate_1 and 127;
  t.OP5_EG_rate_2 := aPar.OP5_EG_rate_2 and 127;
  t.OP5_EG_rate_3 := aPar.OP5_EG_rate_3 and 127;
  t.OP5_EG_rate_4 := aPar.OP5_EG_rate_4 and 127;
  t.OP5_EG_level_1 := aPar.OP5_EG_level_1 and 127;
  t.OP5_EG_level_2 := aPar.OP5_EG_level_2 and 127;
  t.OP5_EG_level_3 := aPar.OP5_EG_level_3 and 127;
  t.OP5_EG_level_4 := aPar.OP5_EG_level_4 and 127;
  t.OP5_KBD_LEV_SCL_BRK_PT := aPar.OP5_KBD_LEV_SCL_BRK_PT and 127;
  t.OP5_KBD_LEV_SCL_LFT_DEPTH := aPar.OP5_KBD_LEV_SCL_LFT_DEPTH and 127;
  t.OP5_KBD_LEV_SCL_RHT_DEPTH := aPar.OP5_KBD_LEV_SCL_RHT_DEPTH and 127;
  t.OP5_OPERATOR_OUTPUT_LEVEL := aPar.OP5_OPERATOR_OUTPUT_LEVEL and 127;
  t.OP5_OSC_FREQ_FINE := aPar.OP5_OSC_FREQ_FINE and 127;
  //now parameters with conversion
  t.OP5_KBD_LEV_SCL_RC_LC :=
    ((aPar.OP5_KBD_LEV_SCL_RHT_CURVE shl 2) and 12) +
    (aPar.OP5_KBD_LEV_SCL_LFT_CURVE and 3);
  t.OP5_OSC_DET_RS := ((aPar.OP5_OSC_DETUNE shl 3) and 120) +
    (aPar.OP5_KBD_RATE_SCALING and 7);
  t.OP5_KVS_AMS := ((aPar.OP5_KEY_VEL_SENSITIVITY shl 2) and 28) +
    (aPar.OP5_AMP_MOD_SENSITIVITY and 3);
  t.OP5_FC_M := ((aPar.OP5_OSC_FREQ_COARSE shl 1) and 62) + (aPar.OP5_OSC_MODE and 1);

  //first the parameters without conversion
  t.OP4_EG_rate_1 := aPar.OP4_EG_rate_1 and 127;
  t.OP4_EG_rate_2 := aPar.OP4_EG_rate_2 and 127;
  t.OP4_EG_rate_3 := aPar.OP4_EG_rate_3 and 127;
  t.OP4_EG_rate_4 := aPar.OP4_EG_rate_4 and 127;
  t.OP4_EG_level_1 := aPar.OP4_EG_level_1 and 127;
  t.OP4_EG_level_2 := aPar.OP4_EG_level_2 and 127;
  t.OP4_EG_level_3 := aPar.OP4_EG_level_3 and 127;
  t.OP4_EG_level_4 := aPar.OP4_EG_level_4 and 127;
  t.OP4_KBD_LEV_SCL_BRK_PT := aPar.OP4_KBD_LEV_SCL_BRK_PT and 127;
  t.OP4_KBD_LEV_SCL_LFT_DEPTH := aPar.OP4_KBD_LEV_SCL_LFT_DEPTH and 127;
  t.OP4_KBD_LEV_SCL_RHT_DEPTH := aPar.OP4_KBD_LEV_SCL_RHT_DEPTH and 127;
  t.OP4_OPERATOR_OUTPUT_LEVEL := aPar.OP4_OPERATOR_OUTPUT_LEVEL and 127;
  t.OP4_OSC_FREQ_FINE := aPar.OP4_OSC_FREQ_FINE and 127;
  //now parameters with conversion
  t.OP4_KBD_LEV_SCL_RC_LC :=
    ((aPar.OP4_KBD_LEV_SCL_RHT_CURVE shl 2) and 12) +
    (aPar.OP4_KBD_LEV_SCL_LFT_CURVE and 3);
  t.OP4_OSC_DET_RS := ((aPar.OP4_OSC_DETUNE shl 3) and 120) +
    (aPar.OP4_KBD_RATE_SCALING and 7);
  t.OP4_KVS_AMS := ((aPar.OP4_KEY_VEL_SENSITIVITY shl 2) and 28) +
    (aPar.OP4_AMP_MOD_SENSITIVITY and 3);
  t.OP4_FC_M := ((aPar.OP4_OSC_FREQ_COARSE shl 1) and 62) + (aPar.OP4_OSC_MODE and 1);

  //first the parameters without conversion
  t.OP3_EG_rate_1 := aPar.OP3_EG_rate_1 and 127;
  t.OP3_EG_rate_2 := aPar.OP3_EG_rate_2 and 127;
  t.OP3_EG_rate_3 := aPar.OP3_EG_rate_3 and 127;
  t.OP3_EG_rate_4 := aPar.OP3_EG_rate_4 and 127;
  t.OP3_EG_level_1 := aPar.OP3_EG_level_1 and 127;
  t.OP3_EG_level_2 := aPar.OP3_EG_level_2 and 127;
  t.OP3_EG_level_3 := aPar.OP3_EG_level_3 and 127;
  t.OP3_EG_level_4 := aPar.OP3_EG_level_4 and 127;
  t.OP3_KBD_LEV_SCL_BRK_PT := aPar.OP3_KBD_LEV_SCL_BRK_PT and 127;
  t.OP3_KBD_LEV_SCL_LFT_DEPTH := aPar.OP3_KBD_LEV_SCL_LFT_DEPTH and 127;
  t.OP3_KBD_LEV_SCL_RHT_DEPTH := aPar.OP3_KBD_LEV_SCL_RHT_DEPTH and 127;
  t.OP3_OPERATOR_OUTPUT_LEVEL := aPar.OP3_OPERATOR_OUTPUT_LEVEL and 127;
  t.OP3_OSC_FREQ_FINE := aPar.OP3_OSC_FREQ_FINE and 127;
  //now parameters with conversion
  t.OP3_KBD_LEV_SCL_RC_LC :=
    ((aPar.OP3_KBD_LEV_SCL_RHT_CURVE shl 2) and 12) +
    (aPar.OP3_KBD_LEV_SCL_LFT_CURVE and 3);
  t.OP3_OSC_DET_RS := ((aPar.OP3_OSC_DETUNE shl 3) and 120) +
    (aPar.OP3_KBD_RATE_SCALING and 7);
  t.OP3_KVS_AMS := ((aPar.OP3_KEY_VEL_SENSITIVITY shl 2) and 28) +
    (aPar.OP3_AMP_MOD_SENSITIVITY and 3);
  t.OP3_FC_M := ((aPar.OP3_OSC_FREQ_COARSE shl 1) and 62) + (aPar.OP3_OSC_MODE and 1);

  //first the parameters without conversion
  t.OP2_EG_rate_1 := aPar.OP2_EG_rate_1 and 127;
  t.OP2_EG_rate_2 := aPar.OP2_EG_rate_2 and 127;
  t.OP2_EG_rate_3 := aPar.OP2_EG_rate_3 and 127;
  t.OP2_EG_rate_4 := aPar.OP2_EG_rate_4 and 127;
  t.OP2_EG_level_1 := aPar.OP2_EG_level_1 and 127;
  t.OP2_EG_level_2 := aPar.OP2_EG_level_2 and 127;
  t.OP2_EG_level_3 := aPar.OP2_EG_level_3 and 127;
  t.OP2_EG_level_4 := aPar.OP2_EG_level_4 and 127;
  t.OP2_KBD_LEV_SCL_BRK_PT := aPar.OP2_KBD_LEV_SCL_BRK_PT and 127;
  t.OP2_KBD_LEV_SCL_LFT_DEPTH := aPar.OP2_KBD_LEV_SCL_LFT_DEPTH and 127;
  t.OP2_KBD_LEV_SCL_RHT_DEPTH := aPar.OP2_KBD_LEV_SCL_RHT_DEPTH and 127;
  t.OP2_OPERATOR_OUTPUT_LEVEL := aPar.OP2_OPERATOR_OUTPUT_LEVEL and 127;
  t.OP2_OSC_FREQ_FINE := aPar.OP2_OSC_FREQ_FINE and 127;
  //now parameters with conversion
  t.OP2_KBD_LEV_SCL_RC_LC :=
    ((aPar.OP2_KBD_LEV_SCL_RHT_CURVE shl 2) and 12) +
    (aPar.OP2_KBD_LEV_SCL_LFT_CURVE and 3);
  t.OP2_OSC_DET_RS := ((aPar.OP2_OSC_DETUNE shl 3) and 120) +
    (aPar.OP2_KBD_RATE_SCALING and 7);
  t.OP2_KVS_AMS := ((aPar.OP2_KEY_VEL_SENSITIVITY shl 2) and 28) +
    (aPar.OP2_AMP_MOD_SENSITIVITY and 3);
  t.OP2_FC_M := ((aPar.OP2_OSC_FREQ_COARSE shl 1) and 62) + (aPar.OP2_OSC_MODE and 1);

  //first the parameters without conversion
  t.OP1_EG_rate_1 := aPar.OP1_EG_rate_1 and 127;
  t.OP1_EG_rate_2 := aPar.OP1_EG_rate_2 and 127;
  t.OP1_EG_rate_3 := aPar.OP1_EG_rate_3 and 127;
  t.OP1_EG_rate_4 := aPar.OP1_EG_rate_4 and 127;
  t.OP1_EG_level_1 := aPar.OP1_EG_level_1 and 127;
  t.OP1_EG_level_2 := aPar.OP1_EG_level_2 and 127;
  t.OP1_EG_level_3 := aPar.OP1_EG_level_3 and 127;
  t.OP1_EG_level_4 := aPar.OP1_EG_level_4 and 127;
  t.OP1_KBD_LEV_SCL_BRK_PT := aPar.OP1_KBD_LEV_SCL_BRK_PT and 127;
  t.OP1_KBD_LEV_SCL_LFT_DEPTH := aPar.OP1_KBD_LEV_SCL_LFT_DEPTH and 127;
  t.OP1_KBD_LEV_SCL_RHT_DEPTH := aPar.OP1_KBD_LEV_SCL_RHT_DEPTH and 127;
  t.OP1_OPERATOR_OUTPUT_LEVEL := aPar.OP1_OPERATOR_OUTPUT_LEVEL and 127;
  t.OP1_OSC_FREQ_FINE := aPar.OP1_OSC_FREQ_FINE and 127;
  //now parameters with conversion
  t.OP1_KBD_LEV_SCL_RC_LC :=
    ((aPar.OP1_KBD_LEV_SCL_RHT_CURVE shl 2) and 12) +
    (aPar.OP1_KBD_LEV_SCL_LFT_CURVE and 3);
  t.OP1_OSC_DET_RS := ((aPar.OP1_OSC_DETUNE shl 3) and 120) +
    (aPar.OP1_KBD_RATE_SCALING and 7);
  t.OP1_KVS_AMS := ((aPar.OP1_KEY_VEL_SENSITIVITY shl 2) and 28) +
    (aPar.OP1_AMP_MOD_SENSITIVITY and 3);
  t.OP1_FC_M := ((aPar.OP1_OSC_FREQ_COARSE shl 1) and 62) + (aPar.OP1_OSC_MODE and 1);

  //global parameters
  t.PITCH_EG_RATE_1 := aPar.PITCH_EG_RATE_1 and 127;
  t.PITCH_EG_RATE_2 := aPar.PITCH_EG_RATE_2 and 127;
  t.PITCH_EG_RATE_3 := aPar.PITCH_EG_RATE_3 and 127;
  t.PITCH_EG_RATE_4 := aPar.PITCH_EG_RATE_4 and 127;
  t.PITCH_EG_LEVEL_1 := aPar.PITCH_EG_LEVEL_1 and 127;
  t.PITCH_EG_LEVEL_2 := aPar.PITCH_EG_LEVEL_2 and 127;
  t.PITCH_EG_LEVEL_3 := aPar.PITCH_EG_LEVEL_3 and 127;
  t.PITCH_EG_LEVEL_4 := aPar.PITCH_EG_LEVEL_4 and 127;
  t.ALGORITHM := aPar.ALGORITHM and 31;
  t.OSCSYNC_FEEDBACK := ((aPar.OSCILLATOR_SYNC shl 3) and 8) + (aPar.FEEDBACK and 7);
  t.LFO_SPEED := aPar.LFO_SPEED and 127;
  t.LFO_DELAY := aPar.LFO_DELAY and 127;
  t.LFO_PITCH_MOD_DEPTH := aPar.LFO_PITCH_MOD_DEPTH and 127;
  t.LFO_AMP_MOD_DEPTH := aPar.LFO_AMP_MOD_DEPTH and 127;
  t.PMS_WAVE_SYNC := ((aPar.PITCH_MOD_SENSITIVITY shl 4) and 112) +
    ((aPar.LFO_WAVEFORM shl 1) and 14) + (aPar.LFO_SYNC and 1);
  t.TRANSPOSE := aPar.TRANSPOSE and 63;
  t.VOICE_NAME_CHAR_1 := aPar.VOICE_NAME_CHAR_1 and 127;
  t.VOICE_NAME_CHAR_2 := aPar.VOICE_NAME_CHAR_2 and 127;
  t.VOICE_NAME_CHAR_3 := aPar.VOICE_NAME_CHAR_3 and 127;
  t.VOICE_NAME_CHAR_4 := aPar.VOICE_NAME_CHAR_4 and 127;
  t.VOICE_NAME_CHAR_5 := aPar.VOICE_NAME_CHAR_5 and 127;
  t.VOICE_NAME_CHAR_6 := aPar.VOICE_NAME_CHAR_6 and 127;
  t.VOICE_NAME_CHAR_7 := aPar.VOICE_NAME_CHAR_7 and 127;
  t.VOICE_NAME_CHAR_8 := aPar.VOICE_NAME_CHAR_8 and 127;
  t.VOICE_NAME_CHAR_9 := aPar.VOICE_NAME_CHAR_9 and 127;
  t.VOICE_NAME_CHAR_10 := aPar.VOICE_NAME_CHAR_10 and 127;

  Result := t;
end;

function VMEMtoVCED(aPar: TDX7_VMEM_Params): TDX7_VCED_Params;
var
  t: TDX7_VCED_Params;
begin
  //first the parameters without conversion
  t.OP6_EG_rate_1 := aPar.OP6_EG_rate_1 and 127;
  t.OP6_EG_rate_2 := aPar.OP6_EG_rate_2 and 127;
  t.OP6_EG_rate_3 := aPar.OP6_EG_rate_3 and 127;
  t.OP6_EG_rate_4 := aPar.OP6_EG_rate_4 and 127;
  t.OP6_EG_level_1 := aPar.OP6_EG_level_1 and 127;
  t.OP6_EG_level_2 := aPar.OP6_EG_level_2 and 127;
  t.OP6_EG_level_3 := aPar.OP6_EG_level_3 and 127;
  t.OP6_EG_level_4 := aPar.OP6_EG_level_4 and 127;
  t.OP6_KBD_LEV_SCL_BRK_PT := aPar.OP6_KBD_LEV_SCL_BRK_PT and 127;
  t.OP6_KBD_LEV_SCL_LFT_DEPTH := aPar.OP6_KBD_LEV_SCL_LFT_DEPTH and 127;
  t.OP6_KBD_LEV_SCL_RHT_DEPTH := aPar.OP6_KBD_LEV_SCL_RHT_DEPTH and 127;
  t.OP6_OPERATOR_OUTPUT_LEVEL := aPar.OP6_OPERATOR_OUTPUT_LEVEL and 127;
  t.OP6_OSC_FREQ_FINE := aPar.OP6_OSC_FREQ_FINE and 127;
  //now parameters with conversion
  t.OP6_KBD_LEV_SCL_RHT_CURVE := (aPar.OP6_KBD_LEV_SCL_RC_LC shr 2) and 3;
  t.OP6_KBD_LEV_SCL_LFT_CURVE := aPar.OP6_KBD_LEV_SCL_RC_LC and 3;
  t.OP6_OSC_DETUNE := (aPar.OP6_OSC_DET_RS shr 3) and 15;
  t.OP6_KBD_RATE_SCALING := aPar.OP6_OSC_DET_RS and 7;
  t.OP6_KEY_VEL_SENSITIVITY := (aPar.OP6_KVS_AMS shr 2) and 7;
  t.OP6_AMP_MOD_SENSITIVITY := aPar.OP6_KVS_AMS and 3;
  t.OP6_OSC_FREQ_COARSE := (aPar.OP6_FC_M shr 1) and 31;
  t.OP6_OSC_MODE := aPar.OP6_FC_M and 1;

  //first the parameters without conversion
  t.OP5_EG_rate_1 := aPar.OP5_EG_rate_1 and 127;
  t.OP5_EG_rate_2 := aPar.OP5_EG_rate_2 and 127;
  t.OP5_EG_rate_3 := aPar.OP5_EG_rate_3 and 127;
  t.OP5_EG_rate_4 := aPar.OP5_EG_rate_4 and 127;
  t.OP5_EG_level_1 := aPar.OP5_EG_level_1 and 127;
  t.OP5_EG_level_2 := aPar.OP5_EG_level_2 and 127;
  t.OP5_EG_level_3 := aPar.OP5_EG_level_3 and 127;
  t.OP5_EG_level_4 := aPar.OP5_EG_level_4 and 127;
  t.OP5_KBD_LEV_SCL_BRK_PT := aPar.OP5_KBD_LEV_SCL_BRK_PT and 127;
  t.OP5_KBD_LEV_SCL_LFT_DEPTH := aPar.OP5_KBD_LEV_SCL_LFT_DEPTH and 127;
  t.OP5_KBD_LEV_SCL_RHT_DEPTH := aPar.OP5_KBD_LEV_SCL_RHT_DEPTH and 127;
  t.OP5_OPERATOR_OUTPUT_LEVEL := aPar.OP5_OPERATOR_OUTPUT_LEVEL and 127;
  t.OP5_OSC_FREQ_FINE := aPar.OP5_OSC_FREQ_FINE and 127;
  //now parameters with conversion
  t.OP5_KBD_LEV_SCL_RHT_CURVE := (aPar.OP5_KBD_LEV_SCL_RC_LC shr 2) and 3;
  t.OP5_KBD_LEV_SCL_LFT_CURVE := aPar.OP5_KBD_LEV_SCL_RC_LC and 3;
  t.OP5_OSC_DETUNE := (aPar.OP5_OSC_DET_RS shr 3) and 15;
  t.OP5_KBD_RATE_SCALING := aPar.OP5_OSC_DET_RS and 7;
  t.OP5_KEY_VEL_SENSITIVITY := (aPar.OP5_KVS_AMS shr 2) and 7;
  t.OP5_AMP_MOD_SENSITIVITY := aPar.OP5_KVS_AMS and 3;
  t.OP5_OSC_FREQ_COARSE := (aPar.OP5_FC_M shr 1) and 31;
  t.OP5_OSC_MODE := aPar.OP5_FC_M and 1;

  //first the parameters without conversion
  t.OP4_EG_rate_1 := aPar.OP4_EG_rate_1 and 127;
  t.OP4_EG_rate_2 := aPar.OP4_EG_rate_2 and 127;
  t.OP4_EG_rate_3 := aPar.OP4_EG_rate_3 and 127;
  t.OP4_EG_rate_4 := aPar.OP4_EG_rate_4 and 127;
  t.OP4_EG_level_1 := aPar.OP4_EG_level_1 and 127;
  t.OP4_EG_level_2 := aPar.OP4_EG_level_2 and 127;
  t.OP4_EG_level_3 := aPar.OP4_EG_level_3 and 127;
  t.OP4_EG_level_4 := aPar.OP4_EG_level_4 and 127;
  t.OP4_KBD_LEV_SCL_BRK_PT := aPar.OP4_KBD_LEV_SCL_BRK_PT and 127;
  t.OP4_KBD_LEV_SCL_LFT_DEPTH := aPar.OP4_KBD_LEV_SCL_LFT_DEPTH and 127;
  t.OP4_KBD_LEV_SCL_RHT_DEPTH := aPar.OP4_KBD_LEV_SCL_RHT_DEPTH and 127;
  t.OP4_OPERATOR_OUTPUT_LEVEL := aPar.OP4_OPERATOR_OUTPUT_LEVEL and 127;
  t.OP4_OSC_FREQ_FINE := aPar.OP4_OSC_FREQ_FINE and 127;
  //now parameters with conversion
  t.OP4_KBD_LEV_SCL_RHT_CURVE := (aPar.OP4_KBD_LEV_SCL_RC_LC shr 2) and 3;
  t.OP4_KBD_LEV_SCL_LFT_CURVE := aPar.OP4_KBD_LEV_SCL_RC_LC and 3;
  t.OP4_OSC_DETUNE := (aPar.OP4_OSC_DET_RS shr 3) and 15;
  t.OP4_KBD_RATE_SCALING := aPar.OP4_OSC_DET_RS and 7;
  t.OP4_KEY_VEL_SENSITIVITY := (aPar.OP4_KVS_AMS shr 2) and 7;
  t.OP4_AMP_MOD_SENSITIVITY := aPar.OP4_KVS_AMS and 3;
  t.OP4_OSC_FREQ_COARSE := (aPar.OP4_FC_M shr 1) and 31;
  t.OP4_OSC_MODE := aPar.OP4_FC_M and 1;

  //first the parameters without conversion
  t.OP3_EG_rate_1 := aPar.OP3_EG_rate_1 and 127;
  t.OP3_EG_rate_2 := aPar.OP3_EG_rate_2 and 127;
  t.OP3_EG_rate_3 := aPar.OP3_EG_rate_3 and 127;
  t.OP3_EG_rate_4 := aPar.OP3_EG_rate_4 and 127;
  t.OP3_EG_level_1 := aPar.OP3_EG_level_1 and 127;
  t.OP3_EG_level_2 := aPar.OP3_EG_level_2 and 127;
  t.OP3_EG_level_3 := aPar.OP3_EG_level_3 and 127;
  t.OP3_EG_level_4 := aPar.OP3_EG_level_4 and 127;
  t.OP3_KBD_LEV_SCL_BRK_PT := aPar.OP3_KBD_LEV_SCL_BRK_PT and 127;
  t.OP3_KBD_LEV_SCL_LFT_DEPTH := aPar.OP3_KBD_LEV_SCL_LFT_DEPTH and 127;
  t.OP3_KBD_LEV_SCL_RHT_DEPTH := aPar.OP3_KBD_LEV_SCL_RHT_DEPTH and 127;
  t.OP3_OPERATOR_OUTPUT_LEVEL := aPar.OP3_OPERATOR_OUTPUT_LEVEL and 127;
  t.OP3_OSC_FREQ_FINE := aPar.OP3_OSC_FREQ_FINE and 127;
  //now parameters with conversion
  t.OP3_KBD_LEV_SCL_RHT_CURVE := (aPar.OP3_KBD_LEV_SCL_RC_LC shr 2) and 3;
  t.OP3_KBD_LEV_SCL_LFT_CURVE := aPar.OP3_KBD_LEV_SCL_RC_LC and 3;
  t.OP3_OSC_DETUNE := (aPar.OP3_OSC_DET_RS shr 3) and 15;
  t.OP3_KBD_RATE_SCALING := aPar.OP3_OSC_DET_RS and 7;
  t.OP3_KEY_VEL_SENSITIVITY := (aPar.OP3_KVS_AMS shr 2) and 7;
  t.OP3_AMP_MOD_SENSITIVITY := aPar.OP3_KVS_AMS and 3;
  t.OP3_OSC_FREQ_COARSE := (aPar.OP3_FC_M shr 1) and 31;
  t.OP3_OSC_MODE := aPar.OP3_FC_M and 1;

  //first the parameters without conversion
  t.OP2_EG_rate_1 := aPar.OP2_EG_rate_1 and 127;
  t.OP2_EG_rate_2 := aPar.OP2_EG_rate_2 and 127;
  t.OP2_EG_rate_3 := aPar.OP2_EG_rate_3 and 127;
  t.OP2_EG_rate_4 := aPar.OP2_EG_rate_4 and 127;
  t.OP2_EG_level_1 := aPar.OP2_EG_level_1 and 127;
  t.OP2_EG_level_2 := aPar.OP2_EG_level_2 and 127;
  t.OP2_EG_level_3 := aPar.OP2_EG_level_3 and 127;
  t.OP2_EG_level_4 := aPar.OP2_EG_level_4 and 127;
  t.OP2_KBD_LEV_SCL_BRK_PT := aPar.OP2_KBD_LEV_SCL_BRK_PT and 127;
  t.OP2_KBD_LEV_SCL_LFT_DEPTH := aPar.OP2_KBD_LEV_SCL_LFT_DEPTH and 127;
  t.OP2_KBD_LEV_SCL_RHT_DEPTH := aPar.OP2_KBD_LEV_SCL_RHT_DEPTH and 127;
  t.OP2_OPERATOR_OUTPUT_LEVEL := aPar.OP2_OPERATOR_OUTPUT_LEVEL and 127;
  t.OP2_OSC_FREQ_FINE := aPar.OP2_OSC_FREQ_FINE and 127;
  //now parameters with conversion
  t.OP2_KBD_LEV_SCL_RHT_CURVE := (aPar.OP2_KBD_LEV_SCL_RC_LC shr 2) and 3;
  t.OP2_KBD_LEV_SCL_LFT_CURVE := aPar.OP2_KBD_LEV_SCL_RC_LC and 3;
  t.OP2_OSC_DETUNE := (aPar.OP2_OSC_DET_RS shr 3) and 15;
  t.OP2_KBD_RATE_SCALING := aPar.OP2_OSC_DET_RS and 7;
  t.OP2_KEY_VEL_SENSITIVITY := (aPar.OP2_KVS_AMS shr 2) and 7;
  t.OP2_AMP_MOD_SENSITIVITY := aPar.OP2_KVS_AMS and 3;
  t.OP2_OSC_FREQ_COARSE := (aPar.OP2_FC_M shr 1) and 31;
  t.OP2_OSC_MODE := aPar.OP2_FC_M and 1;

  //first the parameters without conversion
  t.OP1_EG_rate_1 := aPar.OP1_EG_rate_1 and 127;
  t.OP1_EG_rate_2 := aPar.OP1_EG_rate_2 and 127;
  t.OP1_EG_rate_3 := aPar.OP1_EG_rate_3 and 127;
  t.OP1_EG_rate_4 := aPar.OP1_EG_rate_4 and 127;
  t.OP1_EG_level_1 := aPar.OP1_EG_level_1 and 127;
  t.OP1_EG_level_2 := aPar.OP1_EG_level_2 and 127;
  t.OP1_EG_level_3 := aPar.OP1_EG_level_3 and 127;
  t.OP1_EG_level_4 := aPar.OP1_EG_level_4 and 127;
  t.OP1_KBD_LEV_SCL_BRK_PT := aPar.OP1_KBD_LEV_SCL_BRK_PT and 127;
  t.OP1_KBD_LEV_SCL_LFT_DEPTH := aPar.OP1_KBD_LEV_SCL_LFT_DEPTH and 127;
  t.OP1_KBD_LEV_SCL_RHT_DEPTH := aPar.OP1_KBD_LEV_SCL_RHT_DEPTH and 127;
  t.OP1_OPERATOR_OUTPUT_LEVEL := aPar.OP1_OPERATOR_OUTPUT_LEVEL and 127;
  t.OP1_OSC_FREQ_FINE := aPar.OP1_OSC_FREQ_FINE and 127;
  //now parameters with conversion
  t.OP1_KBD_LEV_SCL_RHT_CURVE := (aPar.OP1_KBD_LEV_SCL_RC_LC shr 2) and 3;
  t.OP1_KBD_LEV_SCL_LFT_CURVE := aPar.OP1_KBD_LEV_SCL_RC_LC and 3;
  t.OP1_OSC_DETUNE := (aPar.OP1_OSC_DET_RS shr 3) and 15;
  t.OP1_KBD_RATE_SCALING := aPar.OP1_OSC_DET_RS and 7;
  t.OP1_KEY_VEL_SENSITIVITY := (aPar.OP1_KVS_AMS shr 2) and 7;
  t.OP1_AMP_MOD_SENSITIVITY := aPar.OP1_KVS_AMS and 3;
  t.OP1_OSC_FREQ_COARSE := (aPar.OP1_FC_M shr 1) and 31;
  t.OP1_OSC_MODE := aPar.OP1_FC_M and 1;

  //global parameters
  t.PITCH_EG_RATE_1 := aPar.PITCH_EG_RATE_1 and 127;
  t.PITCH_EG_RATE_2 := aPar.PITCH_EG_RATE_2 and 127;
  t.PITCH_EG_RATE_3 := aPar.PITCH_EG_RATE_3 and 127;
  t.PITCH_EG_RATE_4 := aPar.PITCH_EG_RATE_4 and 127;
  t.PITCH_EG_LEVEL_1 := aPar.PITCH_EG_LEVEL_1 and 127;
  t.PITCH_EG_LEVEL_2 := aPar.PITCH_EG_LEVEL_2 and 127;
  t.PITCH_EG_LEVEL_3 := aPar.PITCH_EG_LEVEL_3 and 127;
  t.PITCH_EG_LEVEL_4 := aPar.PITCH_EG_LEVEL_4 and 127;
  t.ALGORITHM := aPar.ALGORITHM and 31;
  t.OSCILLATOR_SYNC := (aPar.OSCSYNC_FEEDBACK shr 3) and 1;
  t.FEEDBACK := aPar.OSCSYNC_FEEDBACK and 7;
  t.LFO_SPEED := aPar.LFO_SPEED and 127;
  t.LFO_DELAY := aPar.LFO_DELAY and 127;
  t.LFO_PITCH_MOD_DEPTH := aPar.LFO_PITCH_MOD_DEPTH and 127;
  t.LFO_AMP_MOD_DEPTH := aPar.LFO_AMP_MOD_DEPTH and 127;
  t.PITCH_MOD_SENSITIVITY := (aPar.PMS_WAVE_SYNC shr 4) and 7;
  t.LFO_WAVEFORM := (aPar.PMS_WAVE_SYNC shr 1) and 7;
  t.LFO_SYNC := aPar.PMS_WAVE_SYNC and 1;
  t.TRANSPOSE := aPar.TRANSPOSE and 63;
  t.VOICE_NAME_CHAR_1 := aPar.VOICE_NAME_CHAR_1 and 127;
  t.VOICE_NAME_CHAR_2 := aPar.VOICE_NAME_CHAR_2 and 127;
  t.VOICE_NAME_CHAR_3 := aPar.VOICE_NAME_CHAR_3 and 127;
  t.VOICE_NAME_CHAR_4 := aPar.VOICE_NAME_CHAR_4 and 127;
  t.VOICE_NAME_CHAR_5 := aPar.VOICE_NAME_CHAR_5 and 127;
  t.VOICE_NAME_CHAR_6 := aPar.VOICE_NAME_CHAR_6 and 127;
  t.VOICE_NAME_CHAR_7 := aPar.VOICE_NAME_CHAR_7 and 127;
  t.VOICE_NAME_CHAR_8 := aPar.VOICE_NAME_CHAR_8 and 127;
  t.VOICE_NAME_CHAR_9 := aPar.VOICE_NAME_CHAR_9 and 127;
  t.VOICE_NAME_CHAR_10 := aPar.VOICE_NAME_CHAR_10 and 127;
  t.OPERATOR_ON_OFF := 63; //just set to all OP=on; not part of VMEM
  Result := t;
end;

function TDX7VoiceContainer.Load_VMEM_FromStream(var aStream: TMemoryStream; Position: integer): boolean;
var
  i: integer;
begin
  Result := False;
  if (Position + 127) <= aStream.Size then
    aStream.Position := Position
  else
    Exit;
  try
    for i := 0 to 127 do
      FDX7_VMEM_Params.params[i] := aStream.ReadByte and 127;

    FDX7_VCED_Params := VMEMtoVCED(FDX7_VMEM_Params);
    Result := True;
  except
    Result := False;
  end;
end;

function TDX7VoiceContainer.Load_VCED_FromStream(var aStream: TMemoryStream; Position: integer): boolean;
var
  i: integer;
begin
  Result := False;
  if (Position + 155) <= aStream.Size then
    aStream.Position := Position
  else
    Exit;
  try
    for i := 0 to 155 do
      FDX7_VCED_Params.params[i] := aStream.ReadByte and 127;

    FDX7_VMEM_Params := VCEDtoVMEM(FDX7_VCED_Params);
    Result := True;
  except
    Result := False;
  end;
end;

procedure TDX7VoiceContainer.InitVoice;
begin
  GetDefinedValues(DX7, fInit, FDX7_VCED_Params.params);
  FDX7_VMEM_Params := VCEDtoVMEM(FDX7_VCED_Params);
end;

function TDX7VoiceContainer.CheckMinMax(var slReport: TStringList): boolean;
var
  arMin: array [0..155] of byte;
  arMax: array [0..155] of byte;
  i: integer;
begin
  //normalize - set the values inside the limits
  GetDefinedValues(DX7, fMin, arMin);
  GetDefinedValues(DX7, fMax, arMax);
  Result := True;
  for i := 0 to 155 do
  begin
    if (FDX7_VCED_Params.params[i] < arMin[i]) or
      (FDX7_VCED_Params.params[i] > arMax[i]) then
    begin
      Result := False;
      slReport.Add('Parameter ' + DX7_VCED_NAMES[i, 0] + ' has value ' +
        IntToStr(FDX7_VCED_Params.params[i]) + '. Allowed range is [' +
        IntToStr(arMin[i]) + ',' + IntToStr(arMax[i]) + ']');
    end;
  end;
end;

procedure TDX7VoiceContainer.Normalize;
var
  arMin: array [0..155] of byte;
  arMax: array [0..155] of byte;
  i: integer;
begin
  GetDefinedValues(DX7, fMin, arMin);
  GetDefinedValues(DX7, fMax, arMax);
  for i := 0 to 155 do
  begin
    if FDX7_VCED_Params.params[i] < arMin[i] then
      FDX7_VCED_Params.params[i] := arMin[i];
    if FDX7_VCED_Params.params[i] > arMax[i] then
      FDX7_VCED_Params.params[i] := arMax[i];
  end;
  FDX7_VMEM_Params := VCEDtoVMEM(FDX7_VCED_Params);
end;

function TDX7VoiceContainer.Get_VMEM_Params: TDX7_VMEM_Params;
begin
  Result := FDX7_VMEM_Params;
end;

function TDX7VoiceContainer.Set_VMEM_Params(aParams: TDX7_VMEM_Params): boolean;
begin
  FDX7_VMEM_Params := aParams;
  FDX7_VCED_Params := VMEMtoVCED(FDX7_VMEM_Params);
  Result := True;
end;

function TDX7VoiceContainer.Set_VCED_Params(aParams: TDX7_VCED_Params): boolean;
begin
  FDX7_VCED_Params := aParams;
  FDX7_VMEM_Params := VCEDtoVMEM(FDX7_VCED_Params);
  Result := True;
end;

function TDX7VoiceContainer.Get_VCED_Params: TDX7_VCED_Params;
begin
  Result := FDX7_VCED_Params;
end;

function TDX7VoiceContainer.GetVoiceName: string;
var
  s: string;
begin
  s := '';
  s := s + Printable(chr(FDX7_VMEM_Params.VOICE_NAME_CHAR_1));
  s := s + Printable(chr(FDX7_VMEM_Params.VOICE_NAME_CHAR_2));
  s := s + Printable(chr(FDX7_VMEM_Params.VOICE_NAME_CHAR_3));
  s := s + Printable(chr(FDX7_VMEM_Params.VOICE_NAME_CHAR_4));
  s := s + Printable(chr(FDX7_VMEM_Params.VOICE_NAME_CHAR_5));
  s := s + Printable(chr(FDX7_VMEM_Params.VOICE_NAME_CHAR_6));
  s := s + Printable(chr(FDX7_VMEM_Params.VOICE_NAME_CHAR_7));
  s := s + Printable(chr(FDX7_VMEM_Params.VOICE_NAME_CHAR_8));
  s := s + Printable(chr(FDX7_VMEM_Params.VOICE_NAME_CHAR_9));
  s := s + Printable(chr(FDX7_VMEM_Params.VOICE_NAME_CHAR_10));
  Result := s;
end;

procedure TDX7VoiceContainer.SetVoiceName(aName: string);
begin
  while Length(aName) < 10 do aName := aName + ' ';
  FDX7_VMEM_Params.VOICE_NAME_CHAR_1 := Ord(aName[1]);
  FDX7_VMEM_Params.VOICE_NAME_CHAR_2 := Ord(aName[2]);
  FDX7_VMEM_Params.VOICE_NAME_CHAR_3 := Ord(aName[3]);
  FDX7_VMEM_Params.VOICE_NAME_CHAR_4 := Ord(aName[4]);
  FDX7_VMEM_Params.VOICE_NAME_CHAR_5 := Ord(aName[5]);
  FDX7_VMEM_Params.VOICE_NAME_CHAR_6 := Ord(aName[6]);
  FDX7_VMEM_Params.VOICE_NAME_CHAR_7 := Ord(aName[7]);
  FDX7_VMEM_Params.VOICE_NAME_CHAR_8 := Ord(aName[8]);
  FDX7_VMEM_Params.VOICE_NAME_CHAR_9 := Ord(aName[9]);
  FDX7_VMEM_Params.VOICE_NAME_CHAR_10 := Ord(aName[10]);
end;

function TDX7VoiceContainer.Save_VMEM_ToStream(var aStream: TMemoryStream): boolean;
var
  i: integer;
begin
  //dont clear the stream here or else bulk dump won't work
  if Assigned(aStream) then
  begin
    for i := 0 to 127 do
      aStream.WriteByte(FDX7_VMEM_Params.params[i]);
    Result := True;
  end
  else
    Result := False;
end;

function TDX7VoiceContainer.Save_VCED_ToStream(var aStream: TMemoryStream): boolean;
var
  i: integer;
begin
  if Assigned(aStream) then
  begin
    aStream.Clear;
    for i := 0 to 155 do
      aStream.WriteByte(FDX7_VCED_Params.params[i]);
    Result := True;
  end
  else
    Result := False;
end;

function TDX7VoiceContainer.Add_VCED_ToStream(var aStream: TMemoryStream): boolean;
var
  i: integer;
begin
  if Assigned(aStream) then
  begin
    for i := 0 to 154 do     // OP on/off is not a part of the VCED SysEx
      aStream.WriteByte(FDX7_VCED_Params.params[i]);
    Result := True;
  end
  else
    Result := False;
end;

{$IFNDEF CMDLINE}
function TDX7VoiceContainer.CalculateHash: string;
var
  aStream: TMemoryStream;
  i: integer;
begin
  //do not take Transpose (144) and VoiceName (145-155) into calculation
  aStream := TMemoryStream.Create;
  for i := 0 to 143 do
    aStream.WriteByte(FDX7_VCED_Params.params[i]);
  //aStream.WriteByte(FDX7_VCED_Params.params[155]);
  aStream.Position := 0;
  Result := THashFactory.TCrypto.CreateSHA2_256().ComputeStream(aStream).ToString();
  aStream.Free;
end;

{$ENDIF}

function TDX7VoiceContainer.GetChecksumPart: integer;
var
  checksum: integer;
  i: integer;
  tmpStream: TMemoryStream;
begin
  checksum := 0;
  tmpStream := TMemoryStream.Create;
  Save_VMEM_ToStream(tmpStream);
  tmpStream.Position := 0;
  for i := 0 to tmpStream.Size - 1 do
    checksum := checksum + tmpStream.ReadByte;
  Result := checksum;
  tmpStream.Free;
end;

function TDX7VoiceContainer.GetChecksum: integer;
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

function TDX7VoiceContainer.GetVCEDChecksum: byte;
var
  checksum: integer;
  i: integer;
  tmpStream: TMemoryStream;
begin
  checksum := 0;
  tmpStream := TMemoryStream.Create;
  Save_VCED_ToStream(tmpStream);
  tmpStream.Position := 0;
  for i := 0 to 154 do
    checksum := checksum + tmpStream.ReadByte;
  Result := ((not (checksum and 255)) and 127) + 1;
  tmpStream.Free;
end;

procedure TDX7VoiceContainer.SysExVoiceToStream(aCh: integer; var aStream: TMemoryStream);
var
  FCh: byte;
begin
  FCh := aCh - 1;
  aStream.Clear;
  aStream.Position := 0;
  aStream.WriteByte($F0);
  aStream.WriteByte($43);
  aStream.WriteByte($00 + FCh); //MIDI channel
  aStream.WriteByte($00);
  aStream.WriteByte($01);
  aStream.WriteByte($1B);
  Add_VCED_ToStream(aStream);
  aStream.WriteByte(GetVCEDChecksum);
  aStream.WriteByte($F7);
end;

function TDX7VoiceContainer.HasNullInName: boolean;
begin
  Result := False;
  if (FDX7_VMEM_Params.VOICE_NAME_CHAR_1 = 0) or
    (FDX7_VMEM_Params.VOICE_NAME_CHAR_2 = 0) or
    (FDX7_VMEM_Params.VOICE_NAME_CHAR_3 = 0) or
    (FDX7_VMEM_Params.VOICE_NAME_CHAR_4 = 0) or
    (FDX7_VMEM_Params.VOICE_NAME_CHAR_5 = 0) or
    (FDX7_VMEM_Params.VOICE_NAME_CHAR_6 = 0) or
    (FDX7_VMEM_Params.VOICE_NAME_CHAR_7 = 0) or
    (FDX7_VMEM_Params.VOICE_NAME_CHAR_8 = 0) or
    (FDX7_VMEM_Params.VOICE_NAME_CHAR_9 = 0) or
    (FDX7_VMEM_Params.VOICE_NAME_CHAR_10 = 0) then Result := True;
end;

procedure TDX7VoiceContainer.Mk2ToMk1(aPEGR, aAMS1, aAMS2, aAMS3, aAMS4, aAMS5, aAMS6: byte);
var
  FAMS: TAMS = (0,1,2,3,3,3,3,3);
  PEG: integer;
  //FPEGR: TPEGR = (50,32,16,8); // used by DXConvert
  FPEGR: TPEGR = (50,25,6.25,3.125);
  PEGR: single;
begin
  // Pitch EG Level correction
  PEGR := FPEGR[aPEGR];

  PEG := FDX7_VCED_Params.PITCH_EG_LEVEL_1;
  FDX7_VCED_Params.PITCH_EG_LEVEL_1 := byte(floor((PEG - 50) * PEGR/50) + 50);

  PEG := FDX7_VCED_Params.PITCH_EG_LEVEL_2;
  FDX7_VCED_Params.PITCH_EG_LEVEL_2 := byte(floor((PEG - 50) * PEGR/50) + 50);

  PEG := FDX7_VCED_Params.PITCH_EG_LEVEL_3;
  FDX7_VCED_Params.PITCH_EG_LEVEL_3 := byte(floor((PEG - 50) * PEGR/50) + 50);

  PEG := FDX7_VCED_Params.PITCH_EG_LEVEL_4;
  FDX7_VCED_Params.PITCH_EG_LEVEL_4 := byte(floor((PEG - 50) * PEGR/50) + 50);

  // Amplitude Modulation Sensitivity correction
  if aAMS1 <> 0 then FDX7_VCED_Params.OP1_AMP_MOD_SENSITIVITY := FAMS[aAMS1];
  if aAMS2 <> 0 then FDX7_VCED_Params.OP2_AMP_MOD_SENSITIVITY := FAMS[aAMS2];
  if aAMS3 <> 0 then FDX7_VCED_Params.OP3_AMP_MOD_SENSITIVITY := FAMS[aAMS3];
  if aAMS4 <> 0 then FDX7_VCED_Params.OP4_AMP_MOD_SENSITIVITY := FAMS[aAMS4];
  if aAMS5 <> 0 then FDX7_VCED_Params.OP5_AMP_MOD_SENSITIVITY := FAMS[aAMS5];
  if aAMS6 <> 0 then FDX7_VCED_Params.OP6_AMP_MOD_SENSITIVITY := FAMS[aAMS6];

  FDX7_VMEM_Params := VCEDtoVMEM(FDX7_VCED_Params);
end;


procedure TDX7VoiceContainer.Mk2ToMk1(aPEGR, aAMS1, aAMS2, aAMS3, aAMS4, aAMS5, aAMS6: byte; aAMS_table: TAMS; aPEGR_table: TPEGR); overload;
var
  PEG: integer;
  PEGR: single;
begin
  // Pitch EG Level correction
  PEGR := aPEGR_table[aPEGR];

  PEG := FDX7_VCED_Params.PITCH_EG_LEVEL_1;
  FDX7_VCED_Params.PITCH_EG_LEVEL_1 := byte(floor((PEG - 50) * PEGR/50) + 50);

  PEG := FDX7_VCED_Params.PITCH_EG_LEVEL_2;
  FDX7_VCED_Params.PITCH_EG_LEVEL_2 := byte(floor((PEG - 50) * PEGR/50) + 50);

  PEG := FDX7_VCED_Params.PITCH_EG_LEVEL_3;
  FDX7_VCED_Params.PITCH_EG_LEVEL_3 := byte(floor((PEG - 50) * PEGR/50) + 50);

  PEG := FDX7_VCED_Params.PITCH_EG_LEVEL_4;
  FDX7_VCED_Params.PITCH_EG_LEVEL_4 := byte(floor((PEG - 50) * PEGR/50) + 50);

  // Amplitude Modulation Sensitivity correction
  if aAMS1 <> 0 then FDX7_VCED_Params.OP1_AMP_MOD_SENSITIVITY := aAMS_table[aAMS1];
  if aAMS2 <> 0 then FDX7_VCED_Params.OP2_AMP_MOD_SENSITIVITY := aAMS_table[aAMS2];
  if aAMS3 <> 0 then FDX7_VCED_Params.OP3_AMP_MOD_SENSITIVITY := aAMS_table[aAMS3];
  if aAMS4 <> 0 then FDX7_VCED_Params.OP4_AMP_MOD_SENSITIVITY := aAMS_table[aAMS4];
  if aAMS5 <> 0 then FDX7_VCED_Params.OP5_AMP_MOD_SENSITIVITY := aAMS_table[aAMS5];
  if aAMS6 <> 0 then FDX7_VCED_Params.OP6_AMP_MOD_SENSITIVITY := aAMS_table[aAMS6];

  FDX7_VMEM_Params := VCEDtoVMEM(FDX7_VCED_Params);
end;

end.
