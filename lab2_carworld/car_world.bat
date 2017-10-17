pushd "%~dp0"

pushd "de1-soc_car_world_system"
%QUARTUS_ROOTDIR%\bin64\quartus_pgm -c "DE-SoC [USB-1]" -m jtag -o P;DE1_SoC_Computer.sof@2
popd

pushd jtag_uart
start cmd /C %QUARTUS_ROOTDIR%\sopc_builder\bin\system-console.exe --script=jtag_server_sysconsole.tcl
@echo Waiting for SystemConsole to start. You can skip waiting once it has started.
popd
timeout 15

pushd carworld
CMD /C win_carw.exe
popd

