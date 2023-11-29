unit untRenumber;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, untUtils;

procedure Renumber(aDir: string; aNumber: integer);

implementation

procedure Renumber(aDir: string; aNumber: integer);
var
  sl: TStringList;
  newName: string;
  newNumber: integer;
  i: integer;
begin
  newName := '';
  newNumber := aNumber;
  aDir := IncludeTrailingPathDelimiter(aDir);
  sl := TStringList.Create;
  FindPERF(aDir, sl);
  for i := 0 to (sl.Count - 1) do
  begin
    newName := Format('%.6d', [i + newNumber]) + copy(sl[i], 7, Length(sl[i]) - 6);
    RenameFile(aDir + sl[i], aDir + newName);
  end;
  WriteLn('Done! Re-numbered ' + IntToStr(sl.Count) + ' files');
  sl.Free;
end;

end.
