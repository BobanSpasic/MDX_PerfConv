{
 *****************************************************************************
  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************

 Author: Boban Spasic

 Unit description:
 Class implementing TX802 Performance bank Data and related functions.
}

unit untTX802PerformanceBank;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, untTX802Performance;

type
  TTX802_PMEM_PerfBankDump = array [1..64] of TTX802_PMEM_Dump;

type
  TTX802PerfBankContainer = class(TPersistent)
  private
    FTX802PerfBankParams: array [1..64] of TTX802PerformanceContainer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadPerfBankFromStream(var aStream: TMemoryStream; Position: integer);
    function GetPerformance(aFunctionNr: integer;
      var FTX802Performance: TTX802PerformanceContainer): boolean;
    function SetPerformance(aFunctionNr: integer;
      var FTX802Performance: TTX802PerformanceContainer): boolean;
    function GetPerformanceName(aNr: integer): string;
    procedure AppendSysExPerformanceBankToStream(aCh: integer; var aStream: TMemoryStream);
  end;

implementation

constructor TTX802PerfBankContainer.Create;
var
  i: integer;
begin
  inherited;
  for i := 1 to 64 do
  begin
    FTX802PerfBankParams[i] := TTX802PerformanceContainer.Create;
  end;
end;

destructor TTX802PerfBankContainer.Destroy;
var
  i: integer;
begin
  for i := 64 downto 1 do
    if Assigned(FTX802PerfBankParams[i]) then
      FTX802PerfBankParams[i].Destroy;
  inherited;
end;

function TTX802PerfBankContainer.GetPerformance(aFunctionNr: integer;
  var FTX802Performance: TTX802PerformanceContainer): boolean;
begin
  if (aFunctionNr > 0) and (aFunctionNr < 65) then
  begin
    if Assigned(FTX802PerfBankParams[aFunctionNr]) then
    begin
      FTX802Performance.Set_PMEM_Params(FTX802PerfBankParams[aFunctionNr].Get_PMEM_Params);
      Result := True;
    end
    else
      Result := False;
  end
  else
    Result := False;
end;

function TTX802PerfBankContainer.SetPerformance(aFunctionNr: integer;
  var FTX802Performance: TTX802PerformanceContainer): boolean;
begin
  if (aFunctionNr > 0) and (aFunctionNr < 65) then
  begin
    FTX802PerfBankParams[aFunctionNr].Set_PMEM_Params(FTX802Performance.Get_PMEM_Params);
    Result := True;
  end
  else
    Result := False;
end;

procedure TTX802PerfBankContainer.LoadPerfBankFromStream(var aStream: TMemoryStream;
  Position: integer);
var
  j: integer;
begin
  if (Position < aStream.Size) and ((aStream.Size - Position) > 11572) then   //????
    aStream.Position := Position
  else
    Exit;
  try
    for  j := 1 to 64 do
    begin
      if assigned(FTX802PerfBankParams[j]) then
      begin
        FTX802PerfBankParams[j].Load_PMEM_FromStream(aStream, aStream.Position);
        aStream.Position := aStream.Position + 12;
      end;
    end;
  except

  end;
end;

function TTX802PerfBankContainer.GetPerformanceName(aNr: integer): string;
begin
  if (aNr > 0) and (aNr < 65) then
    Result := FTX802PerfBankParams[aNr].GetPerformanceName
  else
    Result := '';
end;

procedure TTX802PerfBankContainer.AppendSysExPerformanceBankToStream(aCh: integer; var aStream: TMemoryStream);
var
  i: integer;
  FCh: byte;
begin
  FCh := aCh -1;
  aStream.WriteByte($F0);
  aStream.WriteByte($43);
  aStream.WriteByte($00 + FCh);
  aStream.WriteByte($7E);
  for i := 1 to 64 do
    FTX802PerfBankParams[i].Save_Perf_ToStream(aStream);
  aStream.WriteByte($F7);
end;

end.

