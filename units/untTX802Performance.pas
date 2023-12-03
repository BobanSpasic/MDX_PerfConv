{
 *****************************************************************************
  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************

 Author: Boban Spasic

 Unit description:
 Class implementing TX802 Performance Data and related functions for one Performance.
}

unit untTX802Performance;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, untUtils, untParConst;

type
  TTX802_PCED_Dump = array [0..115] of byte;
  TTX802_PMEM_Dump = array [0..83] of byte;

type
  TTX802_PCED_Params = packed record
    case boolean of
      True: (params: TTX802_PCED_Dump);
      False: (
        VoiceChannelOffset1: byte;        // 0-7   if voice is linked( "<--" on the display )
        VoiceChannelOffset2: byte;        // 0-7   then here will be the number of the voice
        VoiceChannelOffset3: byte;        // 0-7   to which it is linked (zero based)
        VoiceChannelOffset4: byte;        // 0-7   if not linked, here is own number
        VoiceChannelOffset5: byte;        // 0-7
        VoiceChannelOffset6: byte;        // 0-7
        VoiceChannelOffset7: byte;        // 0-7
        VoiceChannelOffset8: byte;        // 0-7
        RXChannel1: byte;                 // 0-15  16-Omni
        RXChannel2: byte;                 // 0-15
        RXChannel3: byte;                 // 0-15
        RXChannel4: byte;                 // 0-15
        RXChannel5: byte;                 // 0-15
        RXChannel6: byte;                 // 0-15
        RXChannel7: byte;                 // 0-15
        RXChannel8: byte;                 // 0-15
        VoiceNumber1: byte;               // 0-255 two bytes  0-63 INT; 64-127 CART; 128-191 PresetA; 192-255 PresetB
        VoiceNumber2: byte;               // 0-255
        VoiceNumber3: byte;               // 0-255
        VoiceNumber4: byte;               // 0-255
        VoiceNumber5: byte;               // 0-255
        VoiceNumber6: byte;               // 0-255
        VoiceNumber7: byte;               // 0-255
        VoiceNumber8: byte;               // 0-255
        Detune1: byte;                    // 0-14  7-center
        Detune2: byte;                    // 0-14
        Detune3: byte;                    // 0-14
        Detune4: byte;                    // 0-14
        Detune5: byte;                    // 0-14
        Detune6: byte;                    // 0-14
        Detune7: byte;                    // 0-14
        Detune8: byte;                    // 0-14
        OutputVolume1: byte;              // 0-99
        OutputVolume2: byte;              // 0-99
        OutputVolume3: byte;              // 0-99
        OutputVolume4: byte;              // 0-99
        OutputVolume5: byte;              // 0-99
        OutputVolume6: byte;              // 0-99
        OutputVolume7: byte;              // 0-99
        OutputVolume8: byte;              // 0-99
        OutputAssign1: byte;              // 0-3   0=off; 1=I; 2=II; 3=I+II;
        OutputAssign2: byte;              // 0-3
        OutputAssign3: byte;              // 0-3
        OutputAssign4: byte;              // 0-3
        OutputAssign5: byte;              // 0-3
        OutputAssign6: byte;              // 0-3
        OutputAssign7: byte;              // 0-3
        OutputAssign8: byte;              // 0-3
        NoteLimitLow1: byte;              // 0-127 C-2-G8
        NoteLimitLow2: byte;              // 0-127
        NoteLimitLow3: byte;              // 0-127
        NoteLimitLow4: byte;              // 0-127
        NoteLimitLow5: byte;              // 0-127
        NoteLimitLow6: byte;              // 0-127
        NoteLimitLow7: byte;              // 0-127
        NoteLimitLow8: byte;              // 0-127
        NoteLimitHigh1: byte;             // 0-127 C-2-G8
        NoteLimitHigh2: byte;             // 0-127
        NoteLimitHigh3: byte;             // 0-127
        NoteLimitHigh4: byte;             // 0-127
        NoteLimitHigh5: byte;             // 0-127
        NoteLimitHigh6: byte;             // 0-127
        NoteLimitHigh7: byte;             // 0-127
        NoteLimitHigh8: byte;             // 0-127
        NoteShift1: byte;                 // 0-48  24=center
        NoteShift2: byte;                 // 0-48
        NoteShift3: byte;                 // 0-48
        NoteShift4: byte;                 // 0-48
        NoteShift5: byte;                 // 0-48
        NoteShift6: byte;                 // 0-48
        NoteShift7: byte;                 // 0-48
        NoteShift8: byte;                 // 0-48
        EGForcedDamp1: byte;              // 0-1
        EGForcedDamp2: byte;              // 0-1
        EGForcedDamp3: byte;              // 0-1
        EGForcedDamp4: byte;              // 0-1
        EGForcedDamp5: byte;              // 0-1
        EGForcedDamp6: byte;              // 0-1
        EGForcedDamp7: byte;              // 0-1
        EGForcedDamp8: byte;              // 0-1
        KeyAssignGroup1: byte;            // 0-1
        KeyAssignGroup2: byte;            // 0-1
        KeyAssignGroup3: byte;            // 0-1
        KeyAssignGroup4: byte;            // 0-1
        KeyAssignGroup5: byte;            // 0-1
        KeyAssignGroup6: byte;            // 0-1
        KeyAssignGroup7: byte;            // 0-1
        KeyAssignGroup8: byte;            // 0-1
        MicroTuningTable1: byte;          // 0-255 two bytes
        MicroTuningTable2: byte;          // 0-255
        MicroTuningTable3: byte;          // 0-255
        MicroTuningTable4: byte;          // 0-255
        MicroTuningTable5: byte;          // 0-255
        MicroTuningTable6: byte;          // 0-255
        MicroTuningTable7: byte;          // 0-255
        MicroTuningTable8: byte;          // 0-255
        PerfName01: byte;                 //       ASCII
        PerfName02: byte;                 //       ASCII
        PerfName03: byte;                 //       ASCII
        PerfName04: byte;                 //       ASCII
        PerfName05: byte;                 //       ASCII
        PerfName06: byte;                 //       ASCII
        PerfName07: byte;                 //       ASCII
        PerfName08: byte;                 //       ASCII
        PerfName09: byte;                 //       ASCII
        PerfName10: byte;                 //       ASCII
        PerfName11: byte;                 //       ASCII
        PerfName12: byte;                 //       ASCII
        PerfName13: byte;                 //       ASCII
        PerfName14: byte;                 //       ASCII
        PerfName15: byte;                 //       ASCII
        PerfName16: byte;                 //       ASCII
        PerfName17: byte;                 //       ASCII
        PerfName18: byte;                 //       ASCII
        PerfName19: byte;                 //       ASCII
        PerfName20: byte;                 //       ASCII
      )
  end;

  TTX802_PMEM_Params = packed record
      case boolean of
        True: (params: TTX802_PMEM_Dump);
        False: (
          VCHOFS_RXCH1: byte;               //        |    VCHOFS    |           RXCH         |
          VCHOFS_RXCH2: byte;               //        |    |    |    |    |    |    |    |    |
          VCHOFS_RXCH3: byte;               //
          VCHOFS_RXCH4: byte;               //
          VCHOFS_RXCH5: byte;               //
          VCHOFS_RXCH6: byte;               //
          VCHOFS_RXCH7: byte;               //
          VCHOFS_RXCH8: byte;               //
          VoiceNumber1: byte;               // 0-255 two bytes  0-63 INT; 64-127 CART; 128-191 PresetA; 192-255 PresetB
          VoiceNumber2: byte;               // 0-255
          VoiceNumber3: byte;               // 0-255
          VoiceNumber4: byte;               // 0-255
          VoiceNumber5: byte;               // 0-255
          VoiceNumber6: byte;               // 0-255
          VoiceNumber7: byte;               // 0-255
          VoiceNumber8: byte;               // 0-255
          MicroTuningTable1: byte;          // 0-255 two bytes
          MicroTuningTable2: byte;          // 0-255
          MicroTuningTable3: byte;          // 0-255
          MicroTuningTable4: byte;          // 0-255
          MicroTuningTable5: byte;          // 0-255
          MicroTuningTable6: byte;          // 0-255
          MicroTuningTable7: byte;          // 0-255
          MicroTuningTable8: byte;          // 0-255
          OutputVolume1: byte;              // 0-99
          OutputVolume2: byte;              // 0-99
          OutputVolume3: byte;              // 0-99
          OutputVolume4: byte;              // 0-99
          OutputVolume5: byte;              // 0-99
          OutputVolume6: byte;              // 0-99
          OutputVolume7: byte;              // 0-99
          OutputVolume8: byte;              // 0-99
          Detune_KASG_Outch1: byte;         //        |    |    |    |    |    |    |    |
          Detune_KASG_Outch2: byte;         //        |       Detune      |KASG|OutChAssg|  not like in the Yamaha manual
          Detune_KASG_Outch3: byte;         //
          Detune_KASG_Outch4: byte;         //
          Detune_KASG_Outch5: byte;         //
          Detune_KASG_Outch6: byte;         //
          Detune_KASG_Outch7: byte;         //
          Detune_KASG_Outch8: byte;         //
          NoteLimitLow1: byte;              // 0-127 C2-G8
          NoteLimitLow2: byte;              // 0-127
          NoteLimitLow3: byte;              // 0-127
          NoteLimitLow4: byte;              // 0-127
          NoteLimitLow5: byte;              // 0-127
          NoteLimitLow6: byte;              // 0-127
          NoteLimitLow7: byte;              // 0-127
          NoteLimitLow8: byte;              // 0-127
          NoteLimitHigh1: byte;             // 0-127 C2-G8
          NoteLimitHigh2: byte;             // 0-127
          NoteLimitHigh3: byte;             // 0-127
          NoteLimitHigh4: byte;             // 0-127
          NoteLimitHigh5: byte;             // 0-127
          NoteLimitHigh6: byte;             // 0-127
          NoteLimitHigh7: byte;             // 0-127
          NoteLimitHigh8: byte;             // 0-127
          FDAMP_NoteShift1: byte;           //        | -  |FDMP|        NoteShift       |
          FDAMP_NoteShift2: byte;           //
          FDAMP_NoteShift3: byte;           //
          FDAMP_NoteShift4: byte;           //
          FDAMP_NoteShift5: byte;           //
          FDAMP_NoteShift6: byte;           //
          FDAMP_NoteShift7: byte;           //
          FDAMP_NoteShift8: byte;           //
          PerfName01: byte;                 //       ASCII
          PerfName02: byte;                 //       ASCII
          PerfName03: byte;                 //       ASCII
          PerfName04: byte;                 //       ASCII
          PerfName05: byte;                 //       ASCII
          PerfName06: byte;                 //       ASCII
          PerfName07: byte;                 //       ASCII
          PerfName08: byte;                 //       ASCII
          PerfName09: byte;                 //       ASCII
          PerfName10: byte;                 //       ASCII
          PerfName11: byte;                 //       ASCII
          PerfName12: byte;                 //       ASCII
          PerfName13: byte;                 //       ASCII
          PerfName14: byte;                 //       ASCII
          PerfName15: byte;                 //       ASCII
          PerfName16: byte;                 //       ASCII
          PerfName17: byte;                 //       ASCII
          PerfName18: byte;                 //       ASCII
          PerfName19: byte;                 //       ASCII
          PerfName20: byte;                 //       ASCII
        )
    end;

type
  TTX802PerformanceContainer = class(TPersistent)
  private
    FTX802_PCED_Params: TTX802_PCED_Params;
    FTX802_PMEM_Params: TTX802_PMEM_Params;
  public
    function Load_PMEM_FromStream(var aStream: TMemoryStream;
      Position: integer): boolean;
    function Get_PCED_Params: TTX802_PCED_Params;
    function Get_PMEM_Params: TTX802_PMEM_Params;
    function Set_PMEM_Params(aParams: TTX802_PMEM_Params): boolean;
    function GetPerformanceName: string;
    function Save_Perf_ToStream(var aStream: TMemoryStream): boolean;
  end;

function PMEMtoPCED(aPar: TTX802_PMEM_Params): TTX802_PCED_Params;

implementation

function PMEMtoPCED(aPar: TTX802_PMEM_Params): TTX802_PCED_Params;
var
  t: TTX802_PCED_Params;
begin
  t.VoiceChannelOffset1 := (aPar.VCHOFS_RXCH1 shr 5) and 7;
  t.VoiceChannelOffset2 := (aPar.VCHOFS_RXCH2 shr 5) and 7;
  t.VoiceChannelOffset3 := (aPar.VCHOFS_RXCH3 shr 5) and 7;
  t.VoiceChannelOffset4 := (aPar.VCHOFS_RXCH4 shr 5) and 7;
  t.VoiceChannelOffset5 := (aPar.VCHOFS_RXCH5 shr 5) and 7;
  t.VoiceChannelOffset6 := (aPar.VCHOFS_RXCH6 shr 5) and 7;
  t.VoiceChannelOffset7 := (aPar.VCHOFS_RXCH7 shr 5) and 7;
  t.VoiceChannelOffset8 := (aPar.VCHOFS_RXCH8 shr 5) and 7;
  t.RXChannel1 := aPar.VCHOFS_RXCH1 and 31;
  t.RXChannel2 := aPar.VCHOFS_RXCH2 and 31;
  t.RXChannel3 := aPar.VCHOFS_RXCH3 and 31;
  t.RXChannel4 := aPar.VCHOFS_RXCH4 and 31;
  t.RXChannel5 := aPar.VCHOFS_RXCH5 and 31;
  t.RXChannel6 := aPar.VCHOFS_RXCH6 and 31;
  t.RXChannel7 := aPar.VCHOFS_RXCH7 and 31;
  t.RXChannel8 := aPar.VCHOFS_RXCH8 and 31;
  t.VoiceNumber1:= aPar.VoiceNumber1;
  t.VoiceNumber2:= aPar.VoiceNumber2;
  t.VoiceNumber3:= aPar.VoiceNumber3;
  t.VoiceNumber4:= aPar.VoiceNumber4;
  t.VoiceNumber5:= aPar.VoiceNumber5;
  t.VoiceNumber6:= aPar.VoiceNumber6;
  t.VoiceNumber7:= aPar.VoiceNumber7;
  t.VoiceNumber8:= aPar.VoiceNumber8;
  t.Detune1 := (aPar.Detune_KASG_Outch1 shr 3) and 15;
  t.Detune2 := (aPar.Detune_KASG_Outch2 shr 3) and 15;
  t.Detune3 := (aPar.Detune_KASG_Outch3 shr 3) and 15;
  t.Detune4 := (aPar.Detune_KASG_Outch4 shr 3) and 15;
  t.Detune5 := (aPar.Detune_KASG_Outch5 shr 3) and 15;
  t.Detune6 := (aPar.Detune_KASG_Outch6 shr 3) and 15;
  t.Detune7 := (aPar.Detune_KASG_Outch7 shr 3) and 15;
  t.Detune8 := (aPar.Detune_KASG_Outch8 shr 3) and 15;
  t.KeyAssignGroup1 := (aPar.Detune_KASG_Outch1 shr 2) and 1;
  t.KeyAssignGroup2 := (aPar.Detune_KASG_Outch2 shr 2) and 1;
  t.KeyAssignGroup3 := (aPar.Detune_KASG_Outch3 shr 2) and 1;
  t.KeyAssignGroup4 := (aPar.Detune_KASG_Outch4 shr 2) and 1;
  t.KeyAssignGroup5 := (aPar.Detune_KASG_Outch5 shr 2) and 1;
  t.KeyAssignGroup6 := (aPar.Detune_KASG_Outch6 shr 2) and 1;
  t.KeyAssignGroup7 := (aPar.Detune_KASG_Outch7 shr 2) and 1;
  t.KeyAssignGroup8 := (aPar.Detune_KASG_Outch8 shr 2) and 1;
  t.OutputVolume1 := aPar.OutputVolume1 and 127;
  t.OutputVolume2 := aPar.OutputVolume2 and 127;
  t.OutputVolume3 := aPar.OutputVolume3 and 127;
  t.OutputVolume4 := aPar.OutputVolume4 and 127;
  t.OutputVolume5 := aPar.OutputVolume5 and 127;
  t.OutputVolume6 := aPar.OutputVolume6 and 127;
  t.OutputVolume7 := aPar.OutputVolume7 and 127;
  t.OutputVolume8 := aPar.OutputVolume8 and 127;
  t.OutputAssign1 := aPar.Detune_KASG_Outch1 and 3;
  t.OutputAssign2 := aPar.Detune_KASG_Outch2 and 3;
  t.OutputAssign3 := aPar.Detune_KASG_Outch3 and 3;
  t.OutputAssign4 := aPar.Detune_KASG_Outch4 and 3;
  t.OutputAssign5 := aPar.Detune_KASG_Outch5 and 3;
  t.OutputAssign6 := aPar.Detune_KASG_Outch6 and 3;
  t.OutputAssign7 := aPar.Detune_KASG_Outch7 and 3;
  t.OutputAssign8 := aPar.Detune_KASG_Outch8 and 3;
  t.NoteLimitLow1 := aPar.NoteLimitLow1 and 127;
  t.NoteLimitLow2 := aPar.NoteLimitLow2 and 127;
  t.NoteLimitLow3 := aPar.NoteLimitLow3 and 127;
  t.NoteLimitLow4 := aPar.NoteLimitLow4 and 127;
  t.NoteLimitLow5 := aPar.NoteLimitLow5 and 127;
  t.NoteLimitLow6 := aPar.NoteLimitLow6 and 127;
  t.NoteLimitLow7 := aPar.NoteLimitLow7 and 127;
  t.NoteLimitLow8 := aPar.NoteLimitLow8 and 127;
  t.NoteLimitHigh1 := aPar.NoteLimitHigh1 and 127;
  t.NoteLimitHigh2 := aPar.NoteLimitHigh2 and 127;
  t.NoteLimitHigh3 := aPar.NoteLimitHigh3 and 127;
  t.NoteLimitHigh4 := aPar.NoteLimitHigh4 and 127;
  t.NoteLimitHigh5 := aPar.NoteLimitHigh5 and 127;
  t.NoteLimitHigh6 := aPar.NoteLimitHigh6 and 127;
  t.NoteLimitHigh7 := aPar.NoteLimitHigh7 and 127;
  t.NoteLimitHigh8 := aPar.NoteLimitHigh8 and 127;
  t.NoteShift1 := aPar.FDAMP_NoteShift1 and 63;
  t.NoteShift2 := aPar.FDAMP_NoteShift2 and 63;
  t.NoteShift3 := aPar.FDAMP_NoteShift3 and 63;
  t.NoteShift4 := aPar.FDAMP_NoteShift4 and 63;
  t.NoteShift5 := aPar.FDAMP_NoteShift5 and 63;
  t.NoteShift6 := aPar.FDAMP_NoteShift6 and 63;
  t.NoteShift7 := aPar.FDAMP_NoteShift7 and 63;
  t.NoteShift8 := aPar.FDAMP_NoteShift8 and 63;
  t.EGForcedDamp1 := (aPar.FDAMP_NoteShift1 shr 5) and 1;
  t.EGForcedDamp2 := (aPar.FDAMP_NoteShift2 shr 5) and 1;
  t.EGForcedDamp3 := (aPar.FDAMP_NoteShift3 shr 5) and 1;
  t.EGForcedDamp4 := (aPar.FDAMP_NoteShift4 shr 5) and 1;
  t.EGForcedDamp5 := (aPar.FDAMP_NoteShift5 shr 5) and 1;
  t.EGForcedDamp6 := (aPar.FDAMP_NoteShift6 shr 5) and 1;
  t.EGForcedDamp7 := (aPar.FDAMP_NoteShift7 shr 5) and 1;
  t.EGForcedDamp8 := (aPar.FDAMP_NoteShift8 shr 5) and 1;
  t.MicroTuningTable1 := aPar.MicroTuningTable1;
  t.MicroTuningTable2 := aPar.MicroTuningTable2;
  t.MicroTuningTable3 := aPar.MicroTuningTable3;
  t.MicroTuningTable4 := aPar.MicroTuningTable4;
  t.MicroTuningTable5 := aPar.MicroTuningTable5;
  t.MicroTuningTable6 := aPar.MicroTuningTable6;
  t.MicroTuningTable7 := aPar.MicroTuningTable7;
  t.MicroTuningTable8 := aPar.MicroTuningTable8;
  t.PerfName01 := aPar.PerfName01;
  t.PerfName02 := aPar.PerfName02;
  t.PerfName03 := aPar.PerfName03;
  t.PerfName04 := aPar.PerfName04;
  t.PerfName05 := aPar.PerfName05;
  t.PerfName06 := aPar.PerfName06;
  t.PerfName07 := aPar.PerfName07;
  t.PerfName08 := aPar.PerfName08;
  t.PerfName09 := aPar.PerfName09;
  t.PerfName10 := aPar.PerfName10;
  t.PerfName11 := aPar.PerfName11;
  t.PerfName12 := aPar.PerfName12;
  t.PerfName13 := aPar.PerfName13;
  t.PerfName14 := aPar.PerfName14;
  t.PerfName15 := aPar.PerfName15;
  t.PerfName16 := aPar.PerfName16;
  t.PerfName17 := aPar.PerfName17;
  t.PerfName18 := aPar.PerfName18;
  t.PerfName19 := aPar.PerfName19;
  t.PerfName20 := aPar.PerfName20;
  Result := t;
end;

function TTX802PerformanceContainer.Load_PMEM_FromStream(var aStream: TMemoryStream;
  Position: integer): boolean;
var
  i: integer;
  cHighNibble: char;
  cLowNibble: char;
  iHighNibble: byte;
  iLowNibble: byte;
  iOneByte: byte;
  iChecksum: byte;
begin
  Result := False;
  if (Position + 168) <= aStream.Size then
    aStream.Position := Position
  else
    Exit;
  try
    for i := 0 to 83 do
      begin
        cHighNibble := char(aStream.ReadByte);
        cLowNibble := char(aStream.ReadByte);
        iHighNibble := Hex2Dec(cHighNibble);
        iLowNibble := Hex2Dec(cLowNibble);
        iOneByte := (iHighNibble shl 4) + iLowNibble;
        FTX802_PMEM_Params.params[i] := iOneByte;
      end;
    iChecksum := aStream.ReadByte;
    FTX802_PCED_Params := PMEMtoPCED(FTX802_PMEM_Params);
    Result := True;
  except
    Result := False;
  end;
end;

function TTX802PerformanceContainer.Get_PCED_Params: TTX802_PCED_Params;
begin
  Result := FTX802_PCED_Params;
end;

function TTX802PerformanceContainer.Get_PMEM_Params: TTX802_PMEM_Params;
begin
  Result := FTX802_PMEM_Params;
end;

function TTX802PerformanceContainer.Set_PMEM_Params(aParams: TTX802_PMEM_Params): boolean;
begin
  FTX802_PMEM_Params := aParams;
  FTX802_PCED_Params := PMEMtoPCED(FTX802_PMEM_Params);
  Result := True;
end;

function TTX802PerformanceContainer.GetPerformanceName: string;
var
  s: string;
begin
  s := '';
  s := s + Printable(chr(FTX802_PCED_Params.PerfName01));
  s := s + Printable(chr(FTX802_PCED_Params.PerfName02));
  s := s + Printable(chr(FTX802_PCED_Params.PerfName03));
  s := s + Printable(chr(FTX802_PCED_Params.PerfName04));
  s := s + Printable(chr(FTX802_PCED_Params.PerfName05));
  s := s + Printable(chr(FTX802_PCED_Params.PerfName06));
  s := s + Printable(chr(FTX802_PCED_Params.PerfName07));
  s := s + Printable(chr(FTX802_PCED_Params.PerfName08));
  s := s + Printable(chr(FTX802_PCED_Params.PerfName09));
  s := s + Printable(chr(FTX802_PCED_Params.PerfName10));
  s := s + Printable(chr(FTX802_PCED_Params.PerfName11));
  s := s + Printable(chr(FTX802_PCED_Params.PerfName12));
  s := s + Printable(chr(FTX802_PCED_Params.PerfName13));
  s := s + Printable(chr(FTX802_PCED_Params.PerfName14));
  s := s + Printable(chr(FTX802_PCED_Params.PerfName15));
  s := s + Printable(chr(FTX802_PCED_Params.PerfName16));
  s := s + Printable(chr(FTX802_PCED_Params.PerfName17));
  s := s + Printable(chr(FTX802_PCED_Params.PerfName18));
  s := s + Printable(chr(FTX802_PCED_Params.PerfName19));
  s := s + Printable(chr(FTX802_PCED_Params.PerfName20));
  Result := s;
end;

//   $4C, $4D, $20, $20, $38, $39, $35, $32, $50, $45
function TTX802PerformanceContainer.Save_Perf_ToStream(var aStream: TMemoryStream): boolean;
var
  i: integer;
  sByte: string;
begin
  //dont clear the stream here or else bulk dump won't work
  if Assigned(aStream) then
  begin
    aStream.WriteByte($01);
    aStream.WriteByte($28);
    aStream.WriteByte($4C);
    aStream.WriteByte($4D);
    aStream.WriteByte($20);
    aStream.WriteByte($20);
    aStream.WriteByte($38);
    aStream.WriteByte($39);
    aStream.WriteByte($35);
    aStream.WriteByte($32);
    aStream.WriteByte($50);
    aStream.WriteByte($4D);
    for i := 0 to 83 do
      begin
        sByte := IntToHex(FTX802_PMEM_Params.params[i], 2);
        aStream.WriteByte(Ord(sByte[1]));
        aStream.WriteByte(Ord(sByte[2]));
      end;
    aStream.WriteByte(0); //checksum should go here
    Result := True;
  end
  else
    Result := False;
end;

end.

