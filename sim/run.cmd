@echo off
cd /d "%~dp0.."
if "%~1"=="" goto usage
iverilog -y rtl -I rtl -o sim\tb_%1.vvp rtl\%1.v tb\tb_%1.v
if errorlevel 1 exit /b 1
rem Waiver: hide only the harmless warning about hex files shorter than the memory
vvp sim\tb_%1.vvp 2>&1 | findstr /v /c:"Not enough words in the file for the requested range"
exit /b 0
:usage
echo Usage: sim\run.cmd module_name
echo Example: sim\run.cmd mux2
exit /b 1
