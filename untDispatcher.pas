{
 *****************************************************************************
  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************

 Author: Boban Spasic

 Unit description:
 Decide the conversion to be done depending on the input files
}

unit untDispatcher;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, untdxutils, untConverter;

procedure DispatchCheck(ABank: string);  //TX7 and DX7II
procedure DispatchCheck(ABankA, ABankB, APerf: string); overload; //DX7II with Performance
procedure DispatchCheck(ABankA1, ABankB1, ABankA2, ABankB2, APerf: string); overload; //DX1 and DX5

implementation

procedure DispatchCheck(ABank: string);
var
  msBank: TMemoryStream;
  ms: MemSet;
begin
  msBank := TMemoryStream.Create;
  msBank.LoadFromFile(ABank);
  ms := ContainsDX_SixOP_MemSet(msBank);
  if (VMEM in ms) and (AMEM in ms) then
  begin
    WriteLn('It is a DX7II bank with supplement');
    ConvertDX7IItoMDX(ABank);
  end;
  if (VMEM in ms) and (PMEM in ms) then
  begin
    WriteLn('It is a TX7 bank with function');
    ConvertTX7toMDX(ABank);
  end;
  msBank.Free;
end;

procedure DispatchCheck(ABankA, ABankB, APerf: string);
var
  msBankA: TMemoryStream;
  msBankB: TMemoryStream;
  msPerf: TMemoryStream;
  msA: MemSet;
  msB: MemSet;
  msP: MemSet;
begin
  msBankA := TMemoryStream.Create;
  msBankA.LoadFromFile(ABankA);
  msBankB := TMemoryStream.Create;
  msBankB.LoadFromFile(ABankB);
  msPerf := TMemoryStream.Create;
  msPerf.LoadFromFile(APerf);

  msA := ContainsDX_SixOP_MemSet(msBankA);
  msB := ContainsDX_SixOP_MemSet(msBankB);
  msP := ContainsDX_SixOP_MemSet(msPerf);

  if (VMEM in msA) and (VMEM in msB) and (AMEM in msA) and (AMEM in msB) and
    (LMPMEM in msP) then
  begin
    WriteLn('It is a DX7II performance set');
    ConvertDX7IItoMDX(ABankA, ABankB, APerf);
  end;

  msBankA.Free;
  msBankB.Free;
  msPerf.Free;
end;

procedure DispatchCheck(ABankA1, ABankB1, ABankA2, ABankB2, APerf: string);
var
  msBankA1: TMemoryStream;
  msBankB1: TMemoryStream;
  msBankA2: TMemoryStream;
  msBankB2: TMemoryStream;
  msPerf: TMemoryStream;
  msA1: MemSet;
  msB1: MemSet;
  msA2: MemSet;
  msB2: MemSet;
  msP: MemSet;
begin
  msBankA1 := TMemoryStream.Create;
  msBankA1.LoadFromFile(ABankA1);
  msBankB1 := TMemoryStream.Create;
  msBankB1.LoadFromFile(ABankB1);
  msBankA2 := TMemoryStream.Create;
  msBankA2.LoadFromFile(ABankA2);
  msBankB2 := TMemoryStream.Create;
  msBankB2.LoadFromFile(ABankB2);
  msPerf := TMemoryStream.Create;
  msPerf.LoadFromFile(APerf);

  msA1 := ContainsDX_SixOP_MemSet(msBankA1);
  msB1 := ContainsDX_SixOP_MemSet(msBankB1);
  msA2 := ContainsDX_SixOP_MemSet(msBankA1);
  msB2 := ContainsDX_SixOP_MemSet(msBankB1);
  msP := ContainsDX_SixOP_MemSet(msPerf);

  if (VMEM in msA1) and (VMEM in msB1) and (VMEM in msA2) and
    (VMEM in msB2) and (PMEM in msP) then
  begin
    WriteLn('It is a DX5 performance set');
    ConvertDX5toMDX(ABankA1, ABankB1, ABankA2, ABankB2, APerf);
  end;

  msBankA1.Free;
  msBankB1.Free;
  msBankA2.Free;
  msBankB2.Free;
  msPerf.Free;
end;

end.
