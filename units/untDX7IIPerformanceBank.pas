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
    function GetPerformance(aPerfNr: integer; var FDX7IIPerformance: TDX7IIPerformanceContainer): boolean;
    function SetPerformance(aPerfNr: integer; var FDX7IIPerformance: TDX7IIPerformanceContainer): boolean;
    function GetPerformanceName(aNr: integer): string;
    function GetChecksum: integer;
    procedure AppendSysExPerformanceBankToStream(aCh: integer; var aStream: TMemoryStream);
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

function TDX7IIPerfBankContainer.GetPerformance(aPerfNr: integer; var FDX7IIPerformance: TDX7IIPerformanceContainer): boolean;
begin
  if (aPerfNr > 0) and (aPerfNr < 33) then
  begin
    if Assigned(FDX7IIPerfBankParams[aPerfNr]) then
    begin
      FDX7IIPerformance.Set_PCED_Params(
        FDX7IIPerfBankParams[aPerfNr].Get_PCED_Params);
      Result := True;
    end
    else
      Result := False;
  end
  else
    Result := False;
end;

function TDX7IIPerfBankContainer.SetPerformance(aPerfNr: integer; var FDX7IIPerformance: TDX7IIPerformanceContainer): boolean;
begin
  if (aPerfNr > 0) and (aPerfNr < 33) then
  begin
    FDX7IIPerfBankParams[aPerfNr].Set_PCED_Params(FDX7IIPerformance.Get_PCED_Params);
    Result := True;
  end
  else
    Result := False;
end;

procedure TDX7IIPerfBankContainer.LoadPerfBankFromStream(var aStream: TMemoryStream; Position: integer);
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

procedure TDX7IIPerfBankContainer.AppendSysExPerformanceBankToStream(aCh: integer; var aStream: TMemoryStream);
var
  i: integer;
  FCh: byte;
begin
  //LM__8973PM
  // F0 43 00 7E 0C 6A 4C 4D 20 20 38 39 37 33 50 4D
  FCh := aCh - 1;
  aStream.WriteByte($F0);
  aStream.WriteByte($43);
  aStream.WriteByte($00 + FCh);
  aStream.WriteByte($7E);
  aStream.WriteByte($0C);
  aStream.WriteByte($6A);
  aStream.WriteByte($4C);
  aStream.WriteByte($4D);
  aStream.WriteByte($20);
  aStream.WriteByte($20);
  aStream.WriteByte($38);
  aStream.WriteByte($39);
  aStream.WriteByte($37);
  aStream.WriteByte($33);
  aStream.WriteByte($50);
  aStream.WriteByte($4D);
  for i := 1 to 32 do
    FDX7IIPerfBankParams[i].Save_PCED_ToStream(aStream);
  aStream.WriteByte(GetChecksum);
  aStream.WriteByte($F7);
end;

function TDX7IIPerfBankContainer.GetPerformanceName(aNr: integer): string;
begin
  if (aNr > 0) and (aNr < 33) then
    Result := FDX7IIPerfBankParams[aNr].GetPerformanceName
  else
    Result := '';
end;

function TDX7IIPerfBankContainer.GetChecksum: integer;
var
  i: integer;
  checksum: integer;
begin
  checksum := $4C + $4D + $20 + $20 + $38 + $39 + $37 + $33 + $50 + $4D;
  try
    for i := 1 to 32 do
      checksum := checksum + FDX7IIPerfBankParams[i].GetChecksumPart;
    Result := ((not (checksum and 255)) and 127) + 1;
  except
    on e: Exception do Result := 0;
  end;
end;

end.
