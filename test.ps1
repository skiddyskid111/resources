$WebhookUrl = "https://discord.com/api/webhooks/1406275854169804891/ajy1l1F8b6tVNEV0_zB_SMQumHG82o54uOavEq-_HQE4Yyp7cu39OtF7IxVNLTQfqeRV"
$Message = "Hello"

$Payload = @{
    content = $Message
} | ConvertTo-Json

Invoke-RestMethod -Uri $WebhookUrl -Method Post -ContentType "application/json" -Body $Payload
