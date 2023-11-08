{
 *****************************************************************************
  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************

 Author: Boban Spasic

 Unit description:
 A couple of functions and procedures for general use in other units
}

unit untUtils;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, StrUtils;

procedure FindSYX(Directory: string; var sl: TStringList);
procedure FindSYXRecursive(Directory: string; var sl: TStringList);
procedure FindPERF(Directory: string; var sl: TStringList);
procedure FindVCED_SYX(Directory: string; var sl: TStringList);
procedure Unused(const A1);
procedure Unused(const A1, A2);
procedure Unused(const A1, A2, A3);
function SameArrays(var a1, a2: array of byte): boolean;
function PosBytes(aBytes: array of byte; aStream: TStream;
  aFromPos: integer = 0): integer;
function GetValidFileName(aFileName: string): string;
function ExtractFileNameWithoutExt(const AFilename: string): string;
function Printable(c: char): char;

implementation

operator in (const AByte: byte; const AArray: array of byte): boolean; inline;
var
  Item: byte;
begin
  for Item in AArray do
    if Item = AByte then
      Exit(True);

  Result := False;
end;

function ExtractFileNameWithoutExt(const AFilename: string): string;
var
  p: integer;
begin
  //from LazFileUtils
  Result := AFilename;
  p := length(Result);
  while (p > 0) do
  begin
    case Result[p] of
      PathDelim: exit;
      {$ifdef windows}
      '/': if ('/' in AllowDirectorySeparators) then exit;
      {$endif}
      '.': exit(copy(Result, 1, p - 1));
    end;
    Dec(p);
  end;
end;

procedure FindSYX(Directory: string; var sl: TStringList);
var
  sr: TSearchRec;
begin
  if FindFirst(Directory + '*.syx', faAnyFile, sr) = 0 then
    repeat
      sl.Add(ExtractFileName(sr.Name));
    until FindNext(sr) <> 0;
  FindClose(sr);
end;

procedure FindSYXRecursive(Directory: string; var sl: TStringList);
var
  sr: TSearchRec;
begin
  if FindFirst(IncludeTrailingBackSlash(Directory) + '*', faAnyFile, sr) = 0 then
  begin
    try
      repeat
        if SameText(ExtractFileExt(sr.Name), '.syx') then
          sl.Add(IncludeTrailingBackSlash(Directory) + sr.Name)
        else
        if (sr.Name <> '.') and (sr.Name <> '..') then
          FindSYXRecursive(IncludeTrailingBackSlash(Directory) + sr.Name, sl);
      until FindNext(sr) <> 0;
    finally
      FindClose(sr);
    end;
  end;
end;

procedure FindPERF(Directory: string; var sl: TStringList);
var
  sr: TSearchRec;
begin
  if FindFirst(Directory + '*.ini', faAnyFile, sr) = 0 then
    repeat
      sl.Add(ExtractFileName(sr.Name));
    until FindNext(sr) <> 0;
  FindClose(sr);
end;

procedure FindVCED_SYX(Directory: string; var sl: TStringList);
var
  sr: TSearchRec;
begin
  if FindFirst(Directory + '*.syx', faAnyFile, sr) = 0 then
    repeat
      if sr.Size = 163 then
        sl.Add(ExtractFileName(sr.Name));
    until FindNext(sr) <> 0;
  FindClose(sr);
end;

{$PUSH}{$HINTS OFF}
procedure Unused(const A1);
begin
end;

procedure Unused(const A1, A2);
begin
end;

procedure Unused(const A1, A2, A3);
begin
end;

{$POP}

function SameArrays(var a1, a2: array of byte): boolean;
var
  i: integer;
begin
  i := Low(a1);
  while (i <= High(a1)) and (a1[i] = a2[i]) do
    Inc(i);
  Result := i > High(a1);
end;

function PosBytes(aBytes: array of byte; aStream: TStream;
  aFromPos: integer = 0): integer;
var
  i, j: integer;
  arrLen: integer;
begin
  Result := -1;
  arrLen := Length(aBytes);
  if arrLen = 0 then Exit;
  if arrLen >= aStream.Size then Exit;
  if (aFromPos + arrLen) > aStream.Size then Exit;
  aStream.Position := aFromPos;
  while aStream.Position <= (aStream.Size - arrLen) do
  begin
    i := aStream.Position;
    if aStream.ReadByte = aBytes[0] then
    begin
      Result := i;
      if arrLen = 1 then Exit;
      for j := 1 to High(aBytes) do
      begin
        if Result <> -1 then
          if aStream.ReadByte = aBytes[j] then
          begin
            Result := i;
          end
          else
          begin
            Result := -1;
            //Exit;
          end;
        //Exit;
      end;
      if Result <> -1 then Exit
      else
      begin
        Inc(i);
        if i < aStream.Size then
          aStream.Position := i;
      end;
    end;
  end;
end;

function GetValidFileName(aFileName: string): string;
var
  FFile, FExt: string;
  FFileWithExt: string;
  FWinReservedNames: array [1..22] of
  string = ('CON', 'PRN', 'AUX', 'NUL', 'COM1', 'COM2', 'COM3', 'COM4',
    'COM5', 'COM6', 'COM7', 'COM8', 'COM9', 'LPT1', 'LPT2', 'LPT3',
    'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9');
  //% is not illegal, but it will prevent batch processing
  FWinIllegalChars: array [1..11] of
  char = ('<', '>', ':', '"', '\', '/', '?', '|', '*', '=', '%');
  i: integer;
begin
  FFile := ExtractFileNameWithoutExt(aFileName);
  FExt := ExtractFileExt(aFileName);

  if UpperCase(FExt) in FWinReservedNames then FExt := 'InvalidExtension';
  if UpperCase(FFile) in FWinReservedNames then FFile := 'InvalidName';

  for i := 1 to 11 do
    FFile := ReplaceStr(FFile, FWinIllegalChars[i], '(' +
      IntToHex(Ord(FWinIllegalChars[i])) + ')');

  for i := 1 to 11 do
    FExt := ReplaceStr(FExt, FWinIllegalChars[i], '(' +
      IntToHex(Ord(FWinIllegalChars[i])) + ')');

  for i := 1 to Length(FFile) do
    if (Ord(FFile[i]) < 32) then FFile[i] := '_';

  // do not allow dot or space at the end of the name (inkl. extension)
  FFileWithExt := Trim(FFile) + Trim(FExt);
  if FFileWithExt[Length(FFileWithExt)] = ' ' then
    SetLength(FFileWithExt, Length(FFileWithExt) - 1);
  if FFileWithExt[Length(FFileWithExt)] = '.' then
    SetLength(FFileWithExt, Length(FFileWithExt) - 1);

  Result := FFileWithExt;
end;

function Printable(c: char): char;
begin
  if (Ord(c) > 31) and (Ord(c) < 127) then Result := c
  else
    Result := #32;
end;

end.
