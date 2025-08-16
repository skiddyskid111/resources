@echo off
set WEBHOOK_URL=https://discord.com/api/webhooks/1406275854169804891/ajy1l1F8b6tVNEV0_zB_SMQumHG82o54uOavEq-_HQE4Yyp7cu39OtF7IxVNLTQfqeRV
set MESSAGE=Hello

curl -H "Content-Type: application/json" -X POST -d "{\"content\":\"%MESSAGE%\"}" %WEBHOOK_URL%
pause
