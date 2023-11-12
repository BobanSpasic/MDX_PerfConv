# MDX_PerfConv [![Build and Release](../../actions/workflows/build.yml/badge.svg)](../../actions/workflows/build.yml)

MiniDexed performance converter - convert TX7, DX7II, DX5 etc. function and performance banks into MiniDexed format

Usage:
``` MDX_PerfConv.exe -parameters ```

  Parameters (short and long form): 
  
       -h               --help                This help message  
       -i               --info                Information  
       -c               --convert             Convert to MiniDexed INI file  
  
       -a (filename)    --voiceA1=(filename)  Path to voice bank A1  
       -b (filename)    --voiceB1=(filename)  Path to voice bank B1    
       -A (filename)    --voiceA2=(filename)  Path to voice bank A2  
       -B (filename)    --voiceB2=(filename)  Path to voice bank B2  
       -p (filename)    --perf=(filename)     Path to performance file  
       -n (number)      --numbering=(number)  First number for filenames
                                              of the output performances

  Parameters are CASE-SENSITIVE

  Example usage:
  
    Get info from any kind of supported files:
       MDX_PerfConv -i -a VoiceBank.syx

    Get info from max. 5 supported files:
       MDX_PerfConv -i -a VoiceBankA.syx -b VoiceBankB.syx -p Performance.syx

    Convert a TX7 bank (VMEM + PMEM):
       MDX_PerfConv -c -a my_TX7_file.syx

    Convert a DX7II bank (VMEM + AMEM):
       MDX_PerfConv -c -a my_DX7II_file.syx

    Convert a DX7II bank set:
       MDX_PerfConv -c -a DX7II_BankA(1-32).syx -b DX7II_BankB(33-64).syx -p DX7II_Perf.syx

    Convert a DX1/DX5 bank set:
       MDX_PerfConv -c -a DX5_BankA1.syx -b DX5_BankB1.syx -A DX5_BankA2.syx -B DX_BankB2.syx -p DX5_Performance.syx

    Parameters in long form:
       MDX_PerfConv --info --voiceA1=VoiceBank.syx

Not supported: DX7II "big" dumps (12kb)

## About the output files:
- if the input file contains just single voices (e.g. TX7 Function Bank (VMEM+PMEM) or DX7II Voice Bank (VMEM+AMEM)) - the output performance files will contain 8 voices each with MIDI Channels set to 1 to 8. So, you will get 4 performance.ini files from one bank file  
- if the input files are combining more than one voice (DX5 performance, DX7II performance) - the output performance file will contain one performance with MIDI Channels set to 1  

## Help needed: 
If you have a DX7II or a DX1/DX5, I would need some help with conversion of some parameters to MiniDexed (Detune, Split points, Pan, Volume etc.)  
If you have a GitHub account, then just open a issue here.  
If you do not have a GitHub account, but you want to help - feel free to contact me spasic[[at]]gmail.com  
