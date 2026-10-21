$sw = [Diagnostics.Stopwatch]::StartNew()
$log = 'D:\Projects\photonicat\build\usb_monitor.log'
$seen = @{}
Write-Output "MONITOR_START $(Get-Date -Format HH:mm:ss)"
while ($sw.Elapsed.TotalMinutes -lt 180) {
  $devs = Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -like 'USB*' }
  foreach ($d in $devs) {
    if ($d.InstanceId -like '*VID_2207*' -and -not $seen.ContainsKey($d.InstanceId)) {
      $seen[$d.InstanceId] = $true
      $line = "{0} ROCKCHIP {1} [{2}]" -f (Get-Date -Format HH:mm:ss), $d.Status, $d.InstanceId
      Add-Content -Path $log -Value $line
      Write-Output $line
    }
  }
  $rk = $devs | Where-Object { $_.InstanceId -like '*VID_2207*' -and $_.Status -eq 'OK' }
  if ($rk) { Write-Output "ROCKCHIP_READY"; exit 0 }
  Start-Sleep -Seconds 5
}
Write-Output 'TIMEOUT_180MIN'
