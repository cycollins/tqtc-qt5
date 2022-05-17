@echo off
setLocal enableExtensions

rem This is intended to be run from the Visual Studio Command Prompt for the desired Visual Studio version.

if not exist "%QT_BUILD_SWDEV%" (
  echo Please set QT_BUILD_SWDEV to a valid sw-dev directory path; %QT_BUILD_SWDEV% does not exist
  exit /b 1
)

set BUILD_DIRECTORY=%CD%
echo Build directory: %BUILD_DIRECTORY%

set SOURCE_DIRECTORY=%~dp0
if %SOURCE_DIRECTORY:~-1%==\ set SOURCE_DIRECTORY=%SOURCE_DIRECTORY:~0,-1%
echo Source directory: %SOURCE_DIRECTORY%

set /p OPENSSL_VERSION=<"%SOURCE_DIRECTORY%\st_openssl_version.txt"
set argC=0
for %%x in (%*) do set /A argC+=1
if %argC% lss 1 (
  xcopy "%SOURCE_DIRECTORY%\st_openssl_version.txt" "%BUILD_DIRECTORY%\qtbase\" /R /C /Y
  cmake -D WIN32=1 -D X86=1 -D SW_DEV="%QT_BUILD_SWDEV%" -D OPENSSL_VERSION="%OPENSSL_VERSION%" -P "%SOURCE_DIRECTORY%\st_third_party.cmake"
  set SSL_DIRECTORY=%APPDATA%\bacon\thirdparty\openssl\%OPENSSL_VERSION%-win32
) else (
  set SSL_DIRECTORY=%~1
)
echo SSL directory: %SSL_DIRECTORY%

xcopy /y /f /r "%SSL_DIRECTORY%\bin\*.dll" "%BUILD_DIRECTORY%\qtbase\bin\"
echo Copy of SSL libraries into bin complete.

call "%SOURCE_DIRECTORY%\configure" -debug-and-release -force-debug-info -developer-build -opensource -confirm-license -shared -platform win32-msvc2015 -no-feature-bearermanagement -I "%SSL_DIRECTORY%\include" -L "%SSL_DIRECTORY%\lib" -openssl-linked -nomake examples -nomake tests -no-compile-examples -no-icu -mp -opengl dynamic OPENSSL_LIBS="-llibeay32 -lssleay32"

jom
echo Make complete.
