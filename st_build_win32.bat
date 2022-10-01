@echo off

set SOURCE_DIRECTORY=%~dp0
if %SOURCE_DIRECTORY:~-1%==\ set SOURCE_DIRECTORY=%SOURCE_DIRECTORY:~0,-1%
echo "Source directory: %SOURCE_DIRECTORY%"

call "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" x86
powershell -ExecutionPolicy Unrestricted "%SOURCE_DIRECTORY%\st_build_windows_common.ps1" 32
