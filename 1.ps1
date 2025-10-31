[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$webhook = 'https://discord.com/api/webhooks/1433909453215895633/65nCYDENhbIopI5vyqig-GbrPkTJVsdBh-PLhnPawm0OrPGV0T_48Brv4pBLePmsVBLZ'
$body = @{ content = 'hello' } | ConvertTo-Json
try {
    Invoke-RestMethod -Uri $webhook -Method Post -Body $body -ContentType 'application/json'
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show('Sent','Success',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
} catch {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show("Failed to send.`n$($_.Exception.Message)","Error",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
}
