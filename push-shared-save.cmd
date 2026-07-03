@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0push-shared-save.ps1" %*
exit /b %ERRORLEVEL%
