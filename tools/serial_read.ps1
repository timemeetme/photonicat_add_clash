param(
    [string]$Port = "COM5",
    [int]$Baud = 1500000,
    [int]$Seconds = 8,
    [string]$SendCmd = ""
)
$sp = New-Object System.IO.Ports.SerialPort($Port, $Baud, [System.IO.Ports.Parity]::None, 8, [System.IO.Ports.StopBits]::One)
$sp.ReadTimeout = 500
$sp.NewLine = "`n"
try {
    $sp.Open()
    if ($SendCmd -ne "") {
        $sp.WriteLine($SendCmd)
        Start-Sleep -Milliseconds 200
    }
    # 敲回车唤醒控制台
    $sp.Write("`r")
    $deadline = (Get-Date).AddSeconds($Seconds)
    $buf = ""
    while ((Get-Date) -lt $deadline) {
        try {
            $chunk = $sp.ReadExisting()
            if ($chunk) { $buf += $chunk }
        } catch {}
        Start-Sleep -Milliseconds 100
    }
    if ($buf.Length -eq 0) { Write-Output "<NO OUTPUT>" }
    else { Write-Output $buf }
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
} finally {
    if ($sp.IsOpen) { $sp.Close() }
}
