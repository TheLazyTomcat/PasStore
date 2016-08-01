@echo off

pushd .

cd ..\MainProgram\Delphi
dcc32.exe -Q -B PasStore.dpr

popd