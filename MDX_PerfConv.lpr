{
 *****************************************************************************
  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************

 Author: Boban Spasic

 Program description:
 Convertor for performance files from Yamaha TX7, DX1, DX5, TX802, DX7II to MiniDexed
}

program MDX_PerfConv;

{$mode objfpc}{$H+}

uses
 {$DEFINE CMDLINE}
 {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes,
  SysUtils,
  CustApp,
  untDispatcher,
  untConverter,
  untDXUtils;

type

  { TMDX_PerfConv }

  TMDX_PerfConv = class(TCustomApplication)
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
  end;

  { TMDX_PerfConv }

  procedure TMDX_PerfConv.DoRun;
  var
    ErrorMsg: string;
    fVoiceA1: string;
    fVoiceB1: string;
    fVoiceA2: string;
    fVoiceB2: string;
    iNumbering: integer;
    fPerf: string;
    slReport: TStringList;
    msInputFile: TMemoryStream;
    i: integer;
    iStartPos: integer;
    bVerbose: boolean;
  begin
    fVoiceA1 := '';
    fVoiceB1 := '';
    fVoiceA2 := '';
    fVoiceB2 := '';
    fPerf := '';
    bVerbose := False;
    // quick check parameters
    CaseSensitiveOptions := True;
    ErrorMsg := CheckOptions('hica:b:A:B:p:n:v',
      'help info convert voiceA1: voiceB1: voiceA2: voiceB2: perf: numbering: verbose');

    if ErrorMsg <> '' then
    begin
      WriteHelp;
      ShowException(Exception.Create(ErrorMsg));
      Terminate;
      Exit;
    end;

    if (ParamCount = 0) or HasOption('h', 'help') then
    begin
      WriteHelp;
      Terminate;
      Exit;
    end;

    if HasOption('v', 'verbose') then bVerbose := True;

    if HasOption('n', 'numbering') then
      iNumbering := (StrToIntDef(GetOptionValue('n', 'numbering'), 1) -1) else iNumbering := 0;
    //The convert functions are already adding 1 for the first number

    if HasOption('a', 'voicea1') then
    begin
      fVoiceA1 := GetOptionValue('a', 'voiceA1');
      fVoiceA1 := ExpandFileName(fVoiceA1);
    end;

    if HasOption('b', 'voiceb1') then
    begin
      fVoiceB1 := GetOptionValue('b', 'voiceB1');
      fVoiceB1 := ExpandFileName(fVoiceB1);
    end;

    if HasOption('A', 'voicea2') then
    begin
      fVoiceA2 := GetOptionValue('A', 'voiceA2');
      fVoiceA2 := ExpandFileName(fVoiceA2);
    end;

    if HasOption('B', 'voiceb2') then
    begin
      fVoiceB2 := GetOptionValue('B', 'voiceB2');
      fVoiceB2 := ExpandFileName(fVoiceB2);
    end;

    if HasOption('p', 'perf') then
    begin
      fPerf := GetOptionValue('p', 'perf');
      fPerf := ExpandFileName(fPerf);
    end;

    if HasOption('i', 'info') then
    begin
      if (not FileExists(fVoiceA1)) and (not FileExists(fVoiceB1)) and
        (not FileExists(fVoiceA2)) and (not FileExists(fVoiceB2)) and
        (not FileExists(fPerf)) then
      begin
        WriteLn('Please specify at least one of the parameters -a, -b -A, -B or -p');
        Terminate;
        Exit;
      end
      else
      begin
        if FileExists(fVoiceA1) then
        begin
          slReport := TStringList.Create;
          msInputFile := TMemoryStream.Create;
          msInputFile.LoadFromFile(fVoiceA1);
          iStartPos := 0;

          if ContainsDX_SixOP_Data(msInputFile, iStartPos, slReport) then
          begin
            for i := 0 to slReport.Count - 1 do
              WriteLn(slReport[i]);
          end
          else
          begin
            for i := 0 to slReport.Count - 1 do
              WriteLn(slReport[i]);
          end;

          msInputFile.Free;
          slReport.Free;
        end;
        if FileExists(fVoiceB1) then
        begin
          slReport := TStringList.Create;
          msInputFile := TMemoryStream.Create;
          msInputFile.LoadFromFile(fVoiceB1);
          iStartPos := 0;

          if ContainsDX_SixOP_Data(msInputFile, iStartPos, slReport) then
          begin
            for i := 0 to slReport.Count - 1 do
              WriteLn(slReport[i]);
          end
          else
          begin
            for i := 0 to slReport.Count - 1 do
              WriteLn(slReport[i]);
          end;

          msInputFile.Free;
          slReport.Free;
        end;
        if FileExists(fVoiceA2) then
        begin
          slReport := TStringList.Create;
          msInputFile := TMemoryStream.Create;
          msInputFile.LoadFromFile(fVoiceA2);
          iStartPos := 0;

          if ContainsDX_SixOP_Data(msInputFile, iStartPos, slReport) then
          begin
            for i := 0 to slReport.Count - 1 do
              WriteLn(slReport[i]);
          end
          else
          begin
            for i := 0 to slReport.Count - 1 do
              WriteLn(slReport[i]);
          end;

          msInputFile.Free;
          slReport.Free;
        end;
        if FileExists(fVoiceB2) then
        begin
          slReport := TStringList.Create;
          msInputFile := TMemoryStream.Create;
          msInputFile.LoadFromFile(fVoiceB2);
          iStartPos := 0;

          if ContainsDX_SixOP_Data(msInputFile, iStartPos, slReport) then
          begin
            for i := 0 to slReport.Count - 1 do
              WriteLn(slReport[i]);
          end
          else
          begin
            for i := 0 to slReport.Count - 1 do
              WriteLn(slReport[i]);
          end;

          msInputFile.Free;
          slReport.Free;
        end;
        if FileExists(fPerf) then
        begin
          slReport := TStringList.Create;
          msInputFile := TMemoryStream.Create;
          msInputFile.LoadFromFile(fPerf);
          iStartPos := 0;

          if ContainsDX_SixOP_Data(msInputFile, iStartPos, slReport) then
          begin
            for i := 0 to slReport.Count - 1 do
              WriteLn(slReport[i]);
          end
          else
          begin
            for i := 0 to slReport.Count - 1 do
              WriteLn(slReport[i]);
          end;

          msInputFile.Free;
          slReport.Free;
        end;
      end;
    end;

    if HasOption('c', 'convert') then
    begin
      if (not FileExists(fVoiceA1)) and (not FileExists(fVoiceB1)) and
        (not FileExists(fVoiceA2)) and (not FileExists(fVoiceB2)) and
        (not FileExists(fPerf)) then
      begin
        WriteLn('Please specify the parameters -a or -a, -b, -A, -B  and -p');
        Terminate;
        Exit;
      end
      else
      begin
        if FileExists(fVoiceA1) and FileExists(fVoiceB1) and
          FileExists(fVoiceA2) and FileExists(fVoiceB2) and FileExists(fPerf) then
        begin
          DispatchCheck(fVoiceA1, fVoiceB1, fVoiceA2, fVoiceB2, fPerf, iNumbering, bVerbose);
        end
        else
        if FileExists(fVoiceA1) and FileExists(fVoiceB1) and FileExists(fPerf) then
        begin
          DispatchCheck(fVoiceA1, fVoiceB1, fPerf, iNumbering, bVerbose);
        end
        else
        if FileExists(fVoiceA1) and FileExists(fVoiceB1) then
        begin
          DispatchCheck(fVoiceA1, fVoiceB1, iNumbering, bVerbose);
        end
        else
        if FileExists(fVoiceA1) then
        begin
          DispatchCheck(fVoiceA1, iNumbering, bVerbose);
        end;
      end;
    end;

    Terminate;
  end;

  constructor TMDX_PerfConv.Create(TheOwner: TComponent);
  begin
    inherited Create(TheOwner);
    StopOnException := True;
  end;

  destructor TMDX_PerfConv.Destroy;
  begin
    inherited Destroy;
  end;

  procedure TMDX_PerfConv.WriteHelp;
  begin
    writeln('');
    writeln('');
    writeln('MDX_PerfConv 1.0 - Performance converter from TX7, DX7II, DX1 and DX5 to MiniDexed');
    writeln('Author: Boban Spasic');
    writeln('https://github.com/BobanSpasic/MDX_PerfConv');
    writeln('');
    writeln('Usage: ', ExtractFileName(ExeName), ' -parameters');
    writeln('  Parameters (short and long form):');
    writeln('       -h               --help                This help message');
    writeln('       -i               --info                Information');
    writeln('       -c               --convert             Convert to MiniDexed INI file');
    writeln('       -v               --verbose             more info while converting');
    writeln('');
    writeln('       -a (filename)    --voiceA1=(filename)  Path to voice bank A1');
    writeln('       -b (filename)    --voiceB1=(filename)  Path to voice bank B1');
    writeln('       -A (filename)    --voiceA2=(filename)  Path to voice bank A2');
    writeln('       -B (filename)    --voiceB2=(filename)  Path to voice bank B2');
    writeln('       -p (filename)    --perf=(filename)     Path to performance file');
    writeln('       -n (number)      --numbering=(number)  First number for filenames');
    writeln('                                              of the output performances');
    writeLn('');
    writeLn('  Parameters are CASE-SENSITIVE');
    writeLn('');
    writeln('  Example usage:');
    writeln('    Get info from any kind of supported files:');
    writeln('       MDX_PerfConv -i -a VoiceBank.syx');
    writeln('');
    writeln('    Get info from max. 5 supported files:');
    writeln('       MDX_PerfConv -i -a VoiceBankA.syx -b VoiceBankB.syx -p Performance.syx');
    writeln('');
    writeln('    Convert a TX7 bank (VMEM+PMEM):');
    writeln('       MDX_PerfConv -c -a my_TX7_file.syx');
    writeln('');
    writeln('    Convert a DX7II bank (VMEM+AMEM):');
    writeln('       MDX_PerfConv -c -a my_DX7II_file.syx');
    writeln('');
    writeln('    Convert a DX7II bank set:');
    writeln('       MDX_PerfConv -c -a DX7II_BankA(1-32).syx -b DX7II_BankB(33-64).syx -p DX7II_Perf.syx');
    writeln('');
    writeln('    Convert a DX1/DX5 bank set:');
    writeln('       MDX_PerfConv -c -a DX5_BankA1.syx -b DX5_BankB1.syx -A DX5_BankA2.syx -B DX_BankB2.syx -p DX5_Performance.syx');
    writeln('');
    writeln('    Parameters in long form:');
    writeln('       MDX_PerfConv --info --voiceA1=VoiceBank.syx');
    writeLn('');
    writeLn('');
  end;

var
  Application: TMDX_PerfConv;

{$R *.res}

begin
  Application := TMDX_PerfConv.Create(nil);
  Application.Title := 'MDX_PerfConv';
  Application.Run;
  Application.Free;
end.
