{
 *****************************************************************************
  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************

 Author: Boban Spasic

 Unit description:
 Class implementing DX7II Performance Data and related functions for one Performance.
}

unit untDX7IIPerformance;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, untUtils;

type
  TDX7II_PCED_Dump = array [0..50] of byte;
//PMEM=PCED for DX7II Performances, no translation

type
  TDX7II_PCED_Params = packed record
    case boolean of
      True: (params: TDX7II_PCED_Dump);
      False: (
        PerformanceLayerMode: byte;       // 0-2   single/dual/split
        VoiceANumber: byte;               // 0-127
        VoiceBNumber: byte;               // 0-127
        MicrotuningTable: byte;           // 0-74
        MicrotuningKey: byte;             // 0-11
        MicrotuningSwitch: byte;          // 0-3   bit0=A; bit1=B
        DualDetune: byte;                 // 0-7
        SplitPoint: byte;                 // 0-127
        EGForcedDampingSwitch: byte;      // 0-1
        SustainFootSwitch: byte;          // 0-3   bit0=A; bit1=B
        FootSwitchAssign: byte;           // 0-3   0=SUS; 1=POR; 2=KHLD; 3=SFT
        FootSwitch: byte;                 // 0-3   bit0=A; bit1=B
        SoftPedalRange: byte;             // 0-7
        NoteShiftRangeA: byte;            // 0-48  single / dual / split(voice A)
        NoteShiftRangeB: byte;            // 0-48  split(voice B)
        VolumeBalance: byte;              // 0-100   -50 to +50
        TotalVolume: byte;                // 0-99
        ContinuousSlider1: byte;          // 0-105
        ContinuousSlider2: byte;          // 0-109
        ContinuousSliderAssign: byte;     // 0-3
        PanMode: byte;                    // 0-3   0:MIX; 1:ON-ON; 2:ON-OFF; 3:OFF-ON
        PanControlRange: byte;            // 0-99
        PanControlAssign: byte;           // 0-2   0:LFO; 1:Velocity; 2:Key
        PanEGRate1: byte;                 // 0-99
        PanEGRate2: byte;                 // 0-99
        PanEGRate3: byte;                 // 0-99
        PanEGRate4: byte;                 // 0-99
        PanEGLevel1: byte;                // 0-99
        PanEGLevel2: byte;                // 0-99
        PanEGLevel3: byte;                // 0-99
        PanEGLevel4: byte;                // 0-99
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
  TDX7IIPerformanceContainer = class(TPersistent)
  private
    FDX7II_PCED_Params: TDX7II_PCED_Params;
  public
    function Load_PCED_FromStream(var aStream: TMemoryStream;
      Position: integer): boolean;
    procedure InitPerformance; //set defaults
    function Get_PCED_Params: TDX7II_PCED_Params;
    function Set_PCED_Params(aParams: TDX7II_PCED_Params): boolean;
    function Save_PCED_ToStream(var aStream: TMemoryStream): boolean;
    function GetPerformanceName: string;
  end;

implementation

function TDX7IIPerformanceContainer.Load_PCED_FromStream(var aStream: TMemoryStream;
  Position: integer): boolean;
var
  i: integer;
begin
  Result := False;
  if (Position + 50) <= aStream.Size then
    aStream.Position := Position
  else
    Exit;
  try
    for i := 0 to 50 do
      FDX7II_PCED_Params.params[i] := aStream.ReadByte;
    Result := True;
  except
    Result := False;
  end;
end;

procedure TDX7IIPerformanceContainer.InitPerformance;
const
  //ToDo - implement it over untParConst
  a: array[0..50] of byte =
    (1, 0, 0, 0, 0, 0, 0, 60, 0, 3, 1, 3, 0, 24, 24, 0, 99, 0, 0, 0, 1, 0, 0, 99, 99, 99, 99, 50,
    50, 50, 50, 73, 78, 73, 84, 32, 80, 69, 82, 70, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32);
begin
  FDX7II_PCED_Params.params := a;
end;

function TDX7IIPerformanceContainer.Get_PCED_Params: TDX7II_PCED_Params;
begin
  Result := FDX7II_PCED_Params;
end;

function TDX7IIPerformanceContainer.Set_PCED_Params(aParams:
  TDX7II_PCED_Params): boolean;
begin
  FDX7II_PCED_Params := aParams;
  Result := True;
end;

function TDX7IIPerformanceContainer.Save_PCED_ToStream(
  var aStream: TMemoryStream): boolean;
var
  i: integer;
begin
  //dont clear the stream here or else bulk dump won't work
  if Assigned(aStream) then
  begin
    for i := 0 to 50 do
      aStream.WriteByte(FDX7II_PCED_Params.params[i]);
    Result := True;
  end
  else
    Result := False;
end;

function TDX7IIPerformanceContainer.GetPerformanceName: string;
var
  s: string;
begin
  s := '';
  s := s + Printable(chr(FDX7II_PCED_Params.PerfName01));
  s := s + Printable(chr(FDX7II_PCED_Params.PerfName02));
  s := s + Printable(chr(FDX7II_PCED_Params.PerfName03));
  s := s + Printable(chr(FDX7II_PCED_Params.PerfName04));
  s := s + Printable(chr(FDX7II_PCED_Params.PerfName05));
  s := s + Printable(chr(FDX7II_PCED_Params.PerfName06));
  s := s + Printable(chr(FDX7II_PCED_Params.PerfName07));
  s := s + Printable(chr(FDX7II_PCED_Params.PerfName08));
  s := s + Printable(chr(FDX7II_PCED_Params.PerfName09));
  s := s + Printable(chr(FDX7II_PCED_Params.PerfName10));
  s := s + Printable(chr(FDX7II_PCED_Params.PerfName11));
  s := s + Printable(chr(FDX7II_PCED_Params.PerfName12));
  s := s + Printable(chr(FDX7II_PCED_Params.PerfName13));
  s := s + Printable(chr(FDX7II_PCED_Params.PerfName14));
  s := s + Printable(chr(FDX7II_PCED_Params.PerfName15));
  s := s + Printable(chr(FDX7II_PCED_Params.PerfName16));
  s := s + Printable(chr(FDX7II_PCED_Params.PerfName17));
  s := s + Printable(chr(FDX7II_PCED_Params.PerfName18));
  s := s + Printable(chr(FDX7II_PCED_Params.PerfName19));
  s := s + Printable(chr(FDX7II_PCED_Params.PerfName20));
  Result := s;
end;

end.
