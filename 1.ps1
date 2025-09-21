$webhook = 'https://discord.com/api/webhooks/1418675943748272188/IDqdUzmKu0VHzY9qMz431yaVnH64hvQ6Rnke8aX4BpV8787hEe-Xx08XSjd6gAlB3RcP'
$body = @{ 'content' = 'hi' } | ConvertTo-Json
Invoke-RestMethod -Uri $webhook -Method Post -Body $body -ContentType 'application/json'
