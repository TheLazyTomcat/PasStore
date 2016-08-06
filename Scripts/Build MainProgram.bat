@echo off

pushd .

cd ..\MainProgram\Delphi
dcc32.exe -Q -B PasStore.dpr

cd ..\Lazarus
lazbuild -B --bm=Release_win_x86 PasStore.lpi
lazbuild -B --bm=Release_win_x64 PasStore.lpi
lazbuild -B --bm=Debug_win_x86 PasStore.lpi
lazbuild -B --bm=Debug_win_x64 PasStore.lpi

popd