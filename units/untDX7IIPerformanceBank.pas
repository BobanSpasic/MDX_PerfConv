{
 *****************************************************************************
  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************

 Author: Boban Spasic

 Unit description:
 Class implementing DX7II Performance Bank and related functions.
}

unit untDX7IIPerformanceBank;

{$mode ObjFPC}{$H+}


interface

uses
  Classes, SysUtils, TypInfo, untDX7IIPerformance;

type
  TDX7II_PCED_PerfBankDump = array [1..32] of TDX7II_PCED_Dump;

type
  TDX7IIPerfBankContainer = class(TPersistent)
  private
    FDX7IIPerfBankParams: array [1..32] of TDX7IIPerformanceContainer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadPerfBankFromStream(var aStream: TMemoryStream; Position: integer);
    function GetPerformance(aFunctionNr: integer;
      var FDX7IIPerformance: TDX7IIPerformanceContainer): boolean;
    function GetPerformanceName(aNr: integer): string;
  end;

implementation

constructor TDX7IIPerfBankContainer.Create;
var
  i: integer;
begin
  inherited;
  for i := 1 to 32 do
  begin
    FDX7IIPerfBankParams[i] := TDX7IIPerformanceContainer.Create;
    FDX7IIPerfBankParams[i].InitPerformance;
  end;
end;

destructor TDX7IIPerfBankContainer.Destroy;
var
  i: integer;
begin
  for i := 32 downto 1 do
    if Assigned(FDX7IIPerfBankParams[i]) then
      FDX7IIPerfBankParams[i].Destroy;
  inherited;
end;

function TDX7IIPerfBankContainer.GetPerformance(aFunctionNr: integer;
  var FDX7IIPerformance: TDX7IIPerformanceContainer): boolean;
begin
  if (aFunctionNr > 0) and (aFunctionNr < 33) then
  begin
    if Assigned(FDX7IIPerfBankParams[aFunctionNr]) then
    begin
      FDX7IIPerformance.Set_PCED_Params(
        FDX7IIPerfBankParams[aFunctionNr].Get_PCED_Params);
      Result := True;
    end
    else
      Result := False;
  end
  else
    Result := False;
end;

procedure TDX7IIPerfBankContainer.LoadPerfBankFromStream(var aStream: TMemoryStream;
  Position: integer);
var
  j: integer;
begin
  if (Position < aStream.Size) and ((aStream.Size - Position) > 1632) then   //????
    aStream.Position := Position
  else
    Exit;
  try
    for  j := 1 to 32 do
    begin
      if assigned(FDX7IIPerfBankParams[j]) then
        FDX7IIPerfBankParams[j].Load_PCED_FromStream(aStream, aStream.Position);
    end;
  except

  end;
end;

function TDX7IIPerfBankContainer.GetPerformanceName(aNr: integer): string;
begin
  if (aNr > 0) and (aNr < 33) then
    Result := FDX7IIPerfBankParams[aNr].GetPerformanceName
  else
    Result := '';
end;

end.
