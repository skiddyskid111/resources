[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$webhook = 'https://discord.com/api/webhooks/1433909453215895633/65nCYDENhbIopI5vyqig-GbrPkTJVsdBh-PLhnPawm0OrPGV0T_48Brv4pBLePmsVBLZ'

$send = {
    param($msg)
    $body = @{ content = $msg } | ConvertTo-Json
    try {
        Invoke-RestMethod -Uri $using:webhook -Method Post -Body $body -ContentType 'application/json'
    } catch {}
}

$thread = [powershell]::Create().AddScript({
    while ($true) {
        & $using:send 'hello2'
        Start-Sleep -Seconds 1
    }
})
$thread.Start()

while ($true) {
    & $send 'hello'
    Start-Sleep -Milliseconds 500
}
