# Photonicat build auto-resume after reboot
# Placed in user Startup folder. Waits for network/Clash/WSL, then launches
# the WSL-side unattended build manager. Removes itself only when manager started.
$ErrorActionPreference = 'Continue'
$log = 'd:\Projects\photonicat\build\auto_resume.log'
function L($m) { Add-Content -Path $log -Value "[$(Get-Date -Format 'MM-dd HH:mm:ss')] $m" }

L '=== auto resume boot ==='

# 1. wait for network up (gateway reachable)
$ok = $false
for ($i = 0; $i -lt 30; $i++) {
    $gw = (Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue | Select-Object -First 1).NextHop
    if ($gw -and (Test-Connection $gw -Count 1 -Quiet -TimeoutSeconds 2)) { $ok = $true; break }
    Start-Sleep -Seconds 10
}
L "network ready=$ok gw=$gw"

# 2. ensure Clash core port 7891 reachable; start FlClash if not
$proxyOk = $false
for ($i = 0; $i -lt 12; $i++) {
    $t = Test-NetConnection 127.0.0.1 -Port 7891 -WarningAction SilentlyContinue
    if ($t.TcpTestSucceeded) { $proxyOk = $true; break }
    if (-not (Get-Process FlClash -ErrorAction SilentlyContinue)) {
        L 'starting FlClash'
        Start-Process 'C:\Program Files\FlClash\FlClash.exe'
    }
    Start-Sleep -Seconds 10
}
L "proxy port 7891 ready=$proxyOk"

# 3. wait for WSL to respond (first boot after reboot may be slow)
$wslOk = $false
for ($i = 0; $i -lt 40; $i++) {
    $job = Start-Job { wsl -l -q 2>&1 | Out-String }
    if (Wait-Job $job -Timeout 30) {
        $out = Receive-Job $job
        if ($out -match 'Ubuntu') { $wslOk = $true; Remove-Job $job; break }
    }
    Remove-Job $job -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 15
}
L "wsl ready=$wslOk"
if (-not $wslOk) {
    L 'FATAL: WSL not responding after reboot - manual attention needed'
    Set-Content 'd:\Projects\photonicat\firmware\BUILD_RESULT.txt' "FAIL: WSL not responding after reboot ($(Get-Date -Format 'F'))"
    return
}

# 4. guard: don't double-start manager
$mgr = wsl -u root -- bash -c "pgrep -f resume_build.sh | head -1" 2>$null
$mgrid = ($mgr | Where-Object { $_ -match '^\d+$' } | Select-Object -First 1)
if ($mgrid) { L "manager already running pid=$mgrid, skip" ; return }

# 5. launch detached build manager inside WSL
wsl -u root -- bash -c "setsid nohup bash /mnt/d/Projects/photonicat/build/resume_build.sh > /root/mgr_stdout.log 2>&1 < /dev/null & sleep 3; pgrep -f resume_build.sh | head -1" 2>$null | Out-Null
Start-Sleep -Seconds 5
$check = wsl -u root -- bash -c "pgrep -f resume_build.sh | head -1" 2>$null
$checkid = ($check | Where-Object { $_ -match '^\d+$' } | Select-Object -First 1)
L "manager launched pid=$checkid"

if ($checkid) {
    # build is in capable hands; remove startup shortcut so it won't run next boot
    Remove-Item "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\auto_resume_build.lnk" -Force -ErrorAction SilentlyContinue
    L 'startup shortcut removed'
} else {
    L 'WARN: manager may not have started, keeping startup shortcut for retry'
}
