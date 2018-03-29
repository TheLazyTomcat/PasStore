@echo off

pushd .

cd ..\MainProgram\Delphi
dcc32.exe -Q -B PasStore.dpr

cd ..\Lazarus
lazbuild -B --no-write-project --bm=Release_win_x86 PasStore.lpi
lazbuild -B --no-write-project --bm=Release_win_x64 PasStore.lpi
lazbuild -B --no-write-project --bm=Debug_win_x86 PasStore.lpi
lazbuild -B --no-write-project --bm=Debug_win_x64 PasStore.lpi

popd