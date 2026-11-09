# Run once in an ADMIN PowerShell on the gaming PC, from the folder holding gpustat.ps1:
#   powershell -ExecutionPolicy Bypass -File .\setup-gpustat.ps1
$ErrorActionPreference = 'Stop'
$LaptopIP = '<LAPTOP_TAILSCALE_IP>'   # agent laptop's Tailscale IP: the only allowed client
if ($LaptopIP -like '<*') { throw 'Set $LaptopIP to the agent laptop''s Tailscale IP first.' }
$Dir = 'C:\ProgramData\yoolbot'

# 1. Install the reporter where normal users can't edit it
New-Item -ItemType Directory -Force -Path $Dir | Out-Null
Copy-Item -Force (Join-Path $PSScriptRoot 'gpustat.ps1') "$Dir\gpustat.ps1"
icacls $Dir /inheritance:r /grant:r "Administrators:(OI)(CI)F" "SYSTEM:(OI)(CI)F" "Users:(OI)(CI)RX" | Out-Null

# 2. Firewall: port 11435 from the laptop only
Get-NetFirewallRule -DisplayName 'YOOLBOT gpustat' -ErrorAction SilentlyContinue | Remove-NetFirewallRule
New-NetFirewallRule -DisplayName 'YOOLBOT gpustat' -Direction Inbound -Protocol TCP -LocalPort 11435 `
    -RemoteAddress $LaptopIP -Action Allow -Profile Any | Out-Null

# 3. Run at logon as you (not admin, not SYSTEM), hidden, restart if it dies
$a = New-ScheduledTaskAction -Execute 'powershell.exe' `
     -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$Dir\gpustat.ps1`""
$t = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
$s = New-ScheduledTaskSettingsSet -ExecutionTimeLimit ([TimeSpan]::Zero) -RestartCount 999 `
     -RestartInterval (New-TimeSpan -Minutes 1) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
$p = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited
Register-ScheduledTask -TaskName 'YOOLBOT gpustat' -Action $a -Trigger $t -Settings $s -Principal $p -Force | Out-Null
Start-ScheduledTask -TaskName 'YOOLBOT gpustat'
Start-Sleep 3
Get-NetTCPConnection -LocalPort 11435 -State Listen -ErrorAction SilentlyContinue |
    Select-Object LocalAddress, LocalPort, State
Write-Host "Done. Next: allow laptop -> gpu-pc tcp:11435 in your Tailscale grants."
