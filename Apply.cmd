@echo off
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Patch.ps1" -Mode Apply
if errorlevel 1 echo Patch failed. Read the error above. Try Run as administrator if access was denied.
pause
