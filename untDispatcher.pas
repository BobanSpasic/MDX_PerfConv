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

procedure DispatchCheck(ABank: string; ANumber: integer; AVerbose: boolean; AOutput, ASettings: string);  //TX7 and DX7II
procedure DispatchCheck(ABankA, ABankB: string; ANumber: integer; AVerbose: boolean; AOutput, ASettings: string); overload; //DX7II big dump
procedure DispatchCheck(ABankA, ABankB, APerf: string; ANumber: integer; AVerbose: boolean; AOutput, ASettings: string); overload; //DX7II with Performance
procedure DispatchCheck(ABankA1, ABankB1, ABankA2, ABankB2, APerf: string; ANumber: integer; AVerbose: boolean; AOutput, ASettings: string); overload; //DX1 and DX5

implementation

procedure DispatchCheck(ABank: string; ANumber: integer; AVerbose: boolean; AOutput, ASettings: string);
var
  msBank: TMemoryStream;
  ms: MemSet;
begin
  msBank := TMemoryStream.Create;
  msBank.LoadFromFile(ABank);
  ms := ContainsDX_SixOP_MemSet(msBank);

  if (VMEM in ms) and (AMEM in ms) and not ((PMEM in ms) or (LMPMEM in ms) or (D_VMEM in ms) or (D_AMEM in ms)) then
  begin
    if msBank.Size >= 5232 then
    begin
      WriteLn('It is a DX7II bank with supplement');
      if AVerbose then WriteLn('Using ConvertDX7IItoMDX with one stream');
      ConvertDX7IItoMDX(msBank, AOutput, ANumber, AVerbose, ASettings);
    end;
  end;
  if (VMEM in ms) and (AMEM in ms) and (D_VMEM in ms) and (D_AMEM in ms) and not ((PMEM in ms) or (LMPMEM in ms)) then
  begin
    if msBank.Size >= 5232 then
    begin
      WriteLn('It is a multiple DX7II bank with supplement');
      if AVerbose then WriteLn('Using ConvertMultiDX7IItoMDX with one stream');
      ConvertMultiDX7IItoMDX(msBank, AOutput, ANumber, AVerbose, ASettings);
    end;
  end;
  if (VMEM in ms) and (PMEM in ms) and not ((AMEM in ms) or (LMPMEM in ms)) then
  begin
    if msBank.Size >= 8192 then
    begin
      WriteLn('It is a TX7 bank with function');
      if AVerbose then WriteLn('Using ConvertTX7toMDX with one stream');
      ConvertTX7toMDX(msBank, AOutput, ANumber, AVerbose);
    end;
  end;
  if (VMEM in ms) and (LMPMEM in ms) and (AMEM in ms) then
  begin
    if msBank.Size >= 12128 then
    begin
      WriteLn('It is a DX7II All dump');
      if AVerbose then WriteLn('Using ConvertBigDX7IItoMDX with one stream');
      ConvertBigDX7IItoMDX(msBank, AOutput, ANumber, AVerbose, ASettings);
    end;
  end;
  if (VMEM in ms) and (LMPMEM in ms) and not (AMEM in ms) then
  begin
    if (msBank.Size >= 9858) and (msBank.Size <= 18108) then
    begin
      WriteLn('It is a INCOMPLETE DX7II All dump');
      WriteLn('Do not expect wonders from this conversion');
      if AVerbose then WriteLn('Using ConvertBigDX7IItoMDX with one stream');
      ConvertBigDX7IItoMDX(msBank, AOutput, ANumber, AVerbose, ASettings);
    end;
  end;
  if (VMEM in ms) and (PMEM802 in ms) and (AMEM in ms) then
  begin
    if msBank.Size >= 16828 then
    begin
      WriteLn('It is a TX802 All dump');
      if AVerbose then WriteLn('Using ConvertTX802ToMDX with one stream');
      ConvertTX802ToMDX(msBank, AOutput, ANumber, AVerbose, ASettings);
    end;
  end;
  msBank.Free;
end;

procedure DispatchCheck(ABankA, ABankB: string; ANumber: integer; AVerbose: boolean; AOutput, ASettings: string); overload;
var
  msBankA: TMemoryStream;
  msBankB: TMemoryStream;
  msAll: TMemoryStream;
  msA: MemSet;
  msB: MemSet;
begin
  msBankA := TMemoryStream.Create;
  msBankA.LoadFromFile(ABankA);
  msBankB := TMemoryStream.Create;
  msBankB.LoadFromFile(ABankB);
  msAll := TMemoryStream.Create;
  msAll.CopyFrom(msBankA, msBankA.Size);
  msAll.CopyFrom(msBankB, msBankB.Size);

  msA := ContainsDX_SixOP_MemSet(msBankA);
  msB := ContainsDX_SixOP_MemSet(msBankB);

  if (VMEM in msA) and (LMPMEM in msA) and (AMEM in msA) and (VMEM in msB) and (LMPMEM in msB) and (AMEM in msB) then
  begin
    WriteLn('It is a DX7II set');
    WriteLn('Be sure to use Internal as Bank A1 and Cartridge as Bank B1 files');
    if AVerbose then WriteLn('Using Convert2BigDX7IItoMDX with two streams');
    Convert2BigDX7IItoMDX(msBankA, msBankB, AOutput, ANumber, AVerbose, ASettings);
  end;

  if (VMEM in msA) and (AMEM in msA) and (LMPMEM in msB) and not ((VMEM in msB) or (AMEM in msB) or (LMPMEM in msA)) then
  begin
    //VMEM+AMEM in one file, PMEM in other file
    WriteLn('It is a DX7II set');
    if AVerbose then WriteLn('Using ConvertBigDX7IItoMDX with one stream');
    ConvertBigDX7IItoMDX(msAll, AOutput, ANumber, AVerbose, ASettings);
  end;

  if (VMEM in msA) and (AMEM in msA) and (PMEM802 in msB) then
  begin
    //VMEM+AMEM in one file, PMEM in other file
    WriteLn('It is a TX802 set');
    if AVerbose then WriteLn('Using ConvertTX802ToMDX with one stream');
    ConvertTX802ToMDX(msAll, ABankB, ANumber, AVerbose, ASettings);
  end;

  msBankA.Free;
  msBankB.Free;
  msAll.Free;
end;

procedure DispatchCheck(ABankA, ABankB, APerf: string; ANumber: integer; AVerbose: boolean; AOutput, ASettings: string);
var
  msBankA: TMemoryStream;
  msBankB: TMemoryStream;
  msPerf: TMemoryStream;
  msAll: TMemoryStream;
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
  msAll := TMemoryStream.Create;
  msAll.CopyFrom(msBankA, msBankA.Size);
  msAll.CopyFrom(msBankB, msBankB.Size);
  msAll.CopyFrom(msPerf, msPerf.Size);

  msA := ContainsDX_SixOP_MemSet(msBankA);
  msB := ContainsDX_SixOP_MemSet(msBankB);
  msP := ContainsDX_SixOP_MemSet(msPerf);

  if (VMEM in msA) and (VMEM in msB) and (AMEM in msA) and (AMEM in msB) and
    (LMPMEM in msP) then
  begin
    WriteLn('It is a DX7II performance set');
    if AVerbose then WriteLn('Using ConvertBigDX7IItoMDX with one stream');
    ConvertBigDX7IItoMDX(msAll, AOutput, ANumber, AVerbose, ASettings);
  end;

  if (VMEM in msA) and (VMEM in msB) and (LMPMEM in msP) and not ((AMEM in msA) or (AMEM in msB)) then
  begin
    WriteLn('It is a INCOMPLETE DX7II performance set without AMEM data');
    WriteLn('Do not expect wonders from this conversion');
    if AVerbose then WriteLn('Using ConvertBigDX7IItoMDX with one stream');
    ConvertBigDX7IItoMDX(msAll, AOutput, ANumber, AVerbose, ASettings);
  end;

  msBankA.Free;
  msBankB.Free;
  msPerf.Free;
  msAll.Free;
end;

procedure DispatchCheck(ABankA1, ABankB1, ABankA2, ABankB2, APerf: string; ANumber: integer; AVerbose: boolean; AOutput, ASettings: string);
var
  msBankA1: TMemoryStream;
  msBankB1: TMemoryStream;
  msBankA2: TMemoryStream;
  msBankB2: TMemoryStream;
  msPerf: TMemoryStream;
  msAll: TMemoryStream;
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

  msAll := TMemoryStream.Create;
  msAll.CopyFrom(msBankA1, msBankA1.Size);
  msAll.CopyFrom(msBankB1, msBankB1.Size);
  msAll.CopyFrom(msBankA2, msBankA2.Size);
  msAll.CopyFrom(msBankB2, msBankB2.Size);
  msAll.CopyFrom(msPerf, msPerf.Size);

  msA1 := ContainsDX_SixOP_MemSet(msBankA1);
  msB1 := ContainsDX_SixOP_MemSet(msBankB1);
  msA2 := ContainsDX_SixOP_MemSet(msBankA1);
  msB2 := ContainsDX_SixOP_MemSet(msBankB1);
  msP := ContainsDX_SixOP_MemSet(msPerf);

  if (VMEM in msA1) and (VMEM in msB1) and (VMEM in msA2) and
    (VMEM in msB2) and (PMEM in msP) then
  begin
    WriteLn('It is a DX5 performance set');
    if AVerbose then WriteLn('Using ConvertDX5toMDX with one stream');
    ConvertDX5toMDX(msAll, AOutput, ANumber, AVerbose);
  end;

  if (VMEM in msA1) and (VMEM in msB1) and (VMEM in msA2) and (VMEM in msA2) and (AMEM in msA1) and (AMEM in msB1) and (AMEM in msA2) and (AMEM in msA2) and (PMEM802 in msP) then
  begin
    WriteLn('It is a TX802 performance set');
    if AVerbose then WriteLn('Using ConvertTX802ToMDX with one stream');
    ConvertTX802ToMDX(msAll, AOutput, ANumber, AVerbose, ASettings);
  end;

  if (VMEM in msA1) and (VMEM in msB1) and (VMEM in msA2) and (VMEM in msA2) and not ((AMEM in msA1) and (AMEM in msB1) and (AMEM in msA2) and (AMEM in msA2)) and (PMEM802 in msP) then
  begin
    WriteLn('It is a INCOMPLETE TX802 performance set without AMEM data');
    WriteLn('Do not expect wonders from this conversion');
    if AVerbose then WriteLn('Using ConvertTX802ToMDX with one stream');
    ConvertTX802ToMDX(msAll, AOutput, ANumber, AVerbose, ASettings);
  end;

  msBankA1.Free;
  msBankB1.Free;
  msBankA2.Free;
  msBankB2.Free;
  msPerf.Free;
  msAll.Free;
end;

end.
