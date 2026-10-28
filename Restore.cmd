@echo off
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Patch.ps1" -Mode Restore
if errorlevel 1 echo Restore failed. Read the error above.
pause
