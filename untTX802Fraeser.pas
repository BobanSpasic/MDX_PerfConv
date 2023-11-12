{
 *****************************************************************************
  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************

 Author: Boban Spasic

 Unit description:
 This unit is just an experiment. Will be deleted in the future
}
unit untTX802Fraeser;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, untUtils, untDXUtils, untParConst;

procedure ConvertTX802ASCIIToBin(AFile: string);

implementation

procedure ConvertTX802ASCIIToBin(AFile: string);
const
  header: array[0..9] of byte = ($54, $58, $38, $30, $32, $50, $4D, $45, $4D, $5F);
var
  msInputFile: TMemoryStream;
  msPMEMFile: TMemoryStream;
  msPCEDFile: TMemoryStream;
  msSearchPosition: integer;
  msFoundPosition: integer;
  cHighNibble: char;
  cLowNibble: char;
  iHighNibble: byte;
  iLowNibble: byte;
  iOneByte: byte;
  i, j: integer;
  block: array [0..6] of byte = ($50, $45, $52, $46, $5F, $30, $30);
begin
  msInputFile := TMemoryStream.Create;
  msPMEMFile := TMemoryStream.Create;
  msPCEDFile := TMemoryStream.Create;
  msInputFile.LoadFromFile(AFile);

  msSearchPosition := 0;
  msFoundPosition := 0;
  if FindDX_SixOP_MEM(PMEM802, msInputFile, msSearchPosition, msFoundPosition) then
  begin
    msPMEMFile.Clear;
    msPMEMFile.WriteBuffer(header, 10);
    for i := 1 to 64 do
    begin
      msFoundPosition := PosBytes(abLM6Type[9], msInputFile, msSearchPosition) + 10;
      block[5] := 48 + (i div 10);
      block[6] := 48 + (i mod 10);
      msPMEMFile.WriteBuffer(block, 7);
      WriteLn('TX802 PMEM Block found at ' + IntToStr(msFoundPosition));
      for j := 1 to 84 do
      begin
        cHighNibble := char(msInputFile.ReadByte);
        cLowNibble := char(msInputFile.ReadByte);
        iHighNibble := Hex2Dec(cHighNibble);
        iLowNibble := Hex2Dec(cLowNibble);
        iOneByte := (iHighNibble shl 4) + iLowNibble;
        msPMEMFile.WriteByte(iOneByte);
      end;
      msPMEMFile.CopyFrom(msInputFile, 1); //Checksum
      msPMEMFile.WriteByte($F7);
      msSearchPosition := msFoundPosition + 1;
    end;
    msPMEMFile.SaveToFile(AFile + '.pmem');
  end;

  msInputFile.Free;
  msPMEMFile.Free;
  msPCEDFile.Free;
end;

end.
