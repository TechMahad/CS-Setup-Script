REM silent install script
@echo off

FOR /F "tokens=*" %%i in ('is64.exe') do SET is64=%%i    
REM echo NNN%is64%NNN
if "%is64%"=="64    " goto SIXFO
cd ZBRN/Win32
goto SKIP
:SIXFO
cd ZBRN/Win64
:SKIP   

cmd /C "preinstall.bat"
goto EOF


:ERROR
:EOF
echo preinstall complete
exit