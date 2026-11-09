# Park the mouse pointer in the bottom-right corner so the hub's cursor:none kicks in.
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
foreach ($i in 1..3) {
    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point(9999, 9999)
    Start-Sleep -Milliseconds 300
    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point(9998, 9998)
}
