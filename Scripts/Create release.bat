@echo off

if exist ..\Release rd ..\Release /s /q

mkdir ..\Release

copy ..\MainProgram\Delphi\Release\win_x86\PasStore.exe "..\Release\PasStore.exe"