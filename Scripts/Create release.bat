@echo off

if exist ..\Release rd ..\Release /s /q

mkdir ..\Release

copy ..\MainProgram\Delphi\Release\win_x86\PasStore.exe "..\Release\PasStore[D32].exe"

copy ..\MainProgram\Lazarus\Release\win_x86\PasStore.exe "..\Release\PasStore[L32].exe"

copy ..\MainProgram\Lazarus\Release\win_x64\PasStore.exe "..\Release\PasStore[L64].exe"