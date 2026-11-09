# YOOLBOT GPU reporter: read-only nvidia-smi stats for the hub on the agent laptop.
# Listens ONLY on this PC's Tailscale IP, ignores whatever the client sends,
# and always answers with the same small JSON. No parameters, no commands, no files.
$BindIP = '<PC_TAILSCALE_IP>'  # this PC's Tailscale IP (tailscale ip -4)
if ($BindIP -like '<*') { throw 'Set $BindIP to this PC''s Tailscale IP first.' }
$Port   = 11435
$Smi    = Join-Path $env:SystemRoot 'System32\nvidia-smi.exe'

function Num($s) { $d = 0.0; if ([double]::TryParse(($s -as [string]).Trim(), [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$d)) { $d } else { $null } }

$listener = $null
while (-not $listener) {                       # wait for Tailscale to come up after boot/resume
    try { $l = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Parse($BindIP), $Port); $l.Start(); $listener = $l }
    catch { Start-Sleep -Seconds 15 }
}
while ($true) {
    $c = $listener.AcceptTcpClient()
    try {
        $c.ReceiveTimeout = 2000; $c.SendTimeout = 2000
        $st = $c.GetStream(); $buf = New-Object byte[] 1024
        try { [void]$st.Read($buf, 0, $buf.Length) } catch {}   # request is read and discarded
        $o = [ordered]@{ ts = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds() }
        $q = & $Smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw,power.limit,clocks.sm --format=csv,noheader,nounits 2>$null | Select-Object -First 1
        if ($q) {
            $v = $q -split ','
            $o.util = Num $v[0]; $o.vram_used_mb = Num $v[1]; $o.vram_total_mb = Num $v[2]
            $o.temp_c = Num $v[3]; $o.power_w = Num $v[4]; $o.power_cap_w = Num $v[5]; $o.sm_mhz = Num $v[6]
        }
        $body = [Text.Encoding]::UTF8.GetBytes(($o | ConvertTo-Json -Compress))
        $hdr  = [Text.Encoding]::ASCII.GetBytes("HTTP/1.1 200 OK`r`nContent-Type: application/json`r`nContent-Length: $($body.Length)`r`nConnection: close`r`n`r`n")
        $st.Write($hdr, 0, $hdr.Length); $st.Write($body, 0, $body.Length)
    } catch {} finally { $c.Close() }
}
