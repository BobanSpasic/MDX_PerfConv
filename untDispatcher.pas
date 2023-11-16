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
  Classes, SysUtils, TypInfo, untdxutils, untConverter;

procedure DispatchCheck(ABank: string; ANumber: integer);  //TX7 and DX7II
procedure DispatchCheck(ABankA, ABankB: string; ANumber: integer); overload; //DX7II big dump
procedure DispatchCheck(ABankA, ABankB, APerf: string; ANumber: integer); overload; //DX7II with Performance
procedure DispatchCheck(ABankA1, ABankB1, ABankA2, ABankB2, APerf: string; ANumber: integer); overload; //DX1 and DX5

implementation

procedure DispatchCheck(ABank: string; ANumber: integer);
var
  msBank: TMemoryStream;
  ms: MemSet;
begin
  msBank := TMemoryStream.Create;
  msBank.LoadFromFile(ABank);
  ms := ContainsDX_SixOP_MemSet(msBank);

  if (VMEM in ms) and (AMEM in ms) and not((PMEM in ms) or (LMPMEM in ms)) then
  begin
    WriteLn('It is a DX7II bank with supplement');
    ConvertDX7IItoMDX(ABank, ANumber);
  end;
  if (VMEM in ms) and (PMEM in ms) and not ((AMEM in ms) or (LMPMEM in ms)) then
  begin
    WriteLn('It is a TX7 bank with function');
    ConvertTX7toMDX(ABank, ANumber);
  end;
  if (VMEM in ms) and (LMPMEM in ms) and (AMEM in ms) then
  begin
    WriteLn('It is a DX7II "big" dump');
    ConvertBigDX7IItoMDX(ABank, ANumber);
  end;
  if (VMEM in ms) and (PMEM802 in ms) and (AMEM in ms) then
  begin
    WriteLn('It is a TX802 "big" dump');
    //ConvertTX7toMDX(ABank);
  end;
  msBank.Free;
end;

procedure DispatchCheck(ABankA, ABankB: string; ANumber: integer); overload;
var
  msBankA: TMemoryStream;
  msBankB: TMemoryStream;
  msA: MemSet;
  msB: MemSet;
begin
  msBankA := TMemoryStream.Create;
  msBankA.LoadFromFile(ABankA);
  msBankB := TMemoryStream.Create;
  msBankB.LoadFromFile(ABankB);

  msA := ContainsDX_SixOP_MemSet(msBankA);
  msB := ContainsDX_SixOP_MemSet(msBankB);

  if (VMEM in msA) and (LMPMEM in msA) and (AMEM in msA) and (VMEM in msB) and (LMPMEM in msB) and (AMEM in msB) then
  begin
    WriteLn('It is a DX7II "big" dump');
    Convert2BigDX7IItoMDX(ABankA, ABankB, ANumber);
  end;

  msBankA.Free;
  msBankB.Free;
end;

procedure DispatchCheck(ABankA, ABankB, APerf: string; ANumber: integer);
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
    ConvertDX7IItoMDX(ABankA, ABankB, APerf, ANumber);
  end;

  if (VMEM in msA) and (VMEM in msB) and (LMPMEM in msP) then
  begin
    WriteLn('It is a INCOMPLETE DX7II performance set without AMEM data');
    WriteLn('Do not expect wonders from this conversion');
    ConvertDX7IItoMDX(ABankA, ABankB, APerf, ANumber);
  end;

  msBankA.Free;
  msBankB.Free;
  msPerf.Free;
end;

procedure DispatchCheck(ABankA1, ABankB1, ABankA2, ABankB2, APerf: string; ANumber: integer);
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
    ConvertDX5toMDX(ABankA1, ABankB1, ABankA2, ABankB2, APerf, ANumber);
  end;

  if (VMEM in msA1) and (VMEM in msB1) and (VMEM in msA2) and (VMEM in msA2)
    and (AMEM in msA1) and (AMEM in msB1) and (AMEM in msA2) and (AMEM in msA2) and (PMEM802 in msP) then
  begin
    WriteLn('It is a TX802 performance set');
    ConvertTX802ToMDX(ABankA1, ABankA2, ABankB1, ABankB2, APerf, ANumber);
  end;
  
  if (VMEM in msA1) and (VMEM in msB1) and (VMEM in msA2) and (VMEM in msA2)
    and not((AMEM in msA1) and (AMEM in msB1) and (AMEM in msA2) and (AMEM in msA2)) and (PMEM802 in msP) then
  begin
    WriteLn('It is a INCOMPLETE TX802 performance set without AMEM data');
    WriteLn('Do not expect wonders from this conversion');
    ConvertTX802ToMDX(ABankA1, ABankA2, ABankB1, ABankB2, APerf, ANumber);
  end;

  msBankA1.Free;
  msBankB1.Free;
  msBankA2.Free;
  msBankB2.Free;
  msPerf.Free;
end;

end.
