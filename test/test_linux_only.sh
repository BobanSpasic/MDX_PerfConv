wget -q "https://yamahablackboxes.com/patches/dx7ii/voices/dx7iifdvoice32.syx"
wget -q "https://yamahablackboxes.com/patches/dx7ii/voices/dx7iifdvoice64.syx"
wget -q "https://yamahablackboxes.com/patches/dx7ii/performances/dx7iifdperf.syx"
../bin/Linux/MDX_PerfConv --info -a dx7iifdvoice32.syx -b dx7iifdvoice64.syx -p dx7iifdperf.syx
../bin/Linux/MDX_PerfConv -c -a dx7iifdvoice32.syx -b dx7iifdvoice64.syx -p dx7iifdperf.syx
# ls -lh
