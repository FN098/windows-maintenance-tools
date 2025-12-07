# ===============================
# Docker WSL Optimizer
#
# %LOCALAPPDATA%\Docker\wsl\disk\docker_data.vhdx を圧縮する
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

# --- Docker Desktop 停止 ---
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

# --- distro リスト取得（UTF-16 対策済） ---
$installedDistros = (wsl -l -q).Trim()

# --- 対象 ---
$targets = @(
    @{ Name="docker-desktop";      Path=$distroPath;     Tar="docker-desktop.tar" },
    @{ Name="docker-desktop-data"; Path=$dataPath;       Tar="docker-desktop-data.tar" }
)

foreach ($t in $targets) {
    $name = $t.Name
    $tar  = $t.Tar
    $path = $t.Path

    if ($installedDistros -contains $name) {
        Write-Host "[*] $name をエクスポート中..."
        wsl --export $name $tar

        Write-Host "[*] $name を登録解除中..."
        wsl --unregister $name
    }
    else {
        Write-Host "[!] $name は存在しないためスキップ" -ForegroundColor Yellow
    }
}

# --- 再インポート ---
foreach ($t in $targets) {
    if (Test-Path $t.Tar) {
        Write-Host "[*] $($t.Name) を再インポート中..."
        wsl --import $t.Name $t.Path $t.Tar
    }
}

Write-Host "[*] 完了しました！" -ForegroundColor Green
pause
