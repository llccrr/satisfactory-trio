@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0init-first-time.ps1" %*
exit /b %ERRORLEVEL%
