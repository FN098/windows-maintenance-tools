# ===============================
# Docker WSL Reset Script
# 自動管理者昇格＋Docker停止＋WSL再構築
# ===============================

# --- 管理者権限チェック ---
$IsAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    Start-Process powershell "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "[*] 管理者権限で実行中" -ForegroundColor Green

# --- Docker Desktop の強制終了 ---
Write-Host "[*] Docker Desktop を停止中..."
Get-Process "Docker Desktop" -ErrorAction SilentlyContinue | Stop-Process -Force
Get-Process "com.docker.backend" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2

# --- WSL 停止 ---
Write-Host "[*] WSL を停止します..."
wsl --shutdown
Start-Sleep -Seconds 1

# --- パス ---
$distroPath   = "$env:LOCALAPPDATA\Docker\wsl\distro"
$dataPath     = "$env:LOCALAPPDATA\Docker\wsl\data"

# --- 対象ディストロ ---
$distros = @("docker-desktop", "docker-desktop-data")

foreach ($d in $distros) {
    $exists = wsl -l -q | Select-String "^$d$"

    if ($exists) {
        Write-Host "[*] $d をエクスポート中..."
        wsl --export $d "$d.tar"

        Write-Host "[*] $d を登録解除中..."
        wsl --unregister $d
    }
    else {
        Write-Host "[!] $d は存在しないためスキップ" -ForegroundColor Yellow
    }
}

# --- 再インポート ---
if (Test-Path "docker-desktop.tar") {
    Write-Host "[*] docker-desktop を再インポート中..."
    wsl --import docker-desktop "$distroPath" "docker-desktop.tar"
}

if (Test-Path "docker-desktop-data.tar") {
    Write-Host "[*] docker-desktop-data を再インポート中..."
    wsl --import docker-desktop-data "$dataPath" "docker-desktop-data.tar"
}

Write-Host "[*] 完了しました！" -ForegroundColor Green
pause
