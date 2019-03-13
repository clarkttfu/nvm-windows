@echo off
SET INNOSETUP=%CD%\nvm.iss
SET ORIG=%CD%
REM SET GOPATH=%CD%\src
SET GOBIN=%CD%\bin
REM Support for older architectures
SET GOARCH=386

REM Cleanup existing build if it exists
if exist src\nvm.exe (
  del src\nvm.exe
)

REM Make the executable and add to the binary directory
echo Building nvm.exe
go build src\nvm.go

REM Group the file with the helper binaries
move nvm.exe %GOBIN%

REM Codesign the executable
.\buildtools\signtool.exe sign /debug /tr http://timestamp.digicert.com /td sha256 /fd sha256 /a %GOBIN%\nvm.exe


for /f %%i in ('%GOBIN%\nvm.exe version') do set AppVersion=%%i
echo nvm.exe v%AppVersion% built.

REM Create the distribution folder
SET DIST=%CD%\dist\%AppVersion%

REM Remove old build files if they exist.
if exist %DIST% (
  echo Clearing old build in %DIST%
  rd /s /q "%DIST%"
)

REM Create the distribution directory
mkdir "%DIST%"

REM Create the "no install" zip version
for %%a in (%GOBIN%) do (buildtools\7za -mx=9 -r -x!"%GOBIN%\nodejs.ico" a "%DIST%\nvm-noinstall.zip" "%CD%\LICENSE" "%%a\*")

REM Generate the installer (InnoSetup)
innosetup\iscc %INNOSETUP% /o%DIST%
buildtools\7za -mx=9 -r a "%DIST%\nvm-setup.zip" "%DIST%\nvm-setup.exe"

REM Generate checksums
for %%f in (%DIST%\*.*) do (certutil -hashfile "%%f" MD5 | find /i /v "md5" | find /i /v "certutil" >> "%%f.checksum.txt")

:END

REM Cleanup
del %GOBIN%\nvm.exe

echo NVM for Windows v%AppVersion% build completed.
@echo on
