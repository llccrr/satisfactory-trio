@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0pull-shared-save.ps1" %*
exit /b %ERRORLEVEL%
