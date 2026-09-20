# install.ps1
$ErrorActionPreference = "Stop"

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Wajib dijalankan sebagai Administrator!"
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$sebUrl = "https://github.com/SafeExamBrowser/seb-win-refactoring/releases/download/v3.10.2/SEB_3.10.2.920_SetupBundle.exe"
$cfgUrl = "https://raw.githubusercontent.com/tkjtani/seb-ujian/refs/heads/main/SebClientSettings.seb"
$tmp    = "$env:TEMP\seb-deploy"
$cfgDir = "C:\ProgramData\SEB"

New-Item -ItemType Directory -Force -Path $tmp, $cfgDir | Out-Null

Write-Host "[1/4] Mengunduh SEB 3.10.2 (~180 MB)..." -ForegroundColor Cyan
& curl.exe -f -L -o "$tmp\SEB_Setup.exe" $sebUrl

Write-Host "[2/4] Mengunduh Konfigurasi Ujian..." -ForegroundColor Cyan
& curl.exe -f -L -o "$cfgDir\SebClientSettings.seb" $cfgUrl

Write-Host "[3/4] Menginstal SEB..." -ForegroundColor Cyan
Start-Process -FilePath "$tmp\SEB_Setup.exe" -ArgumentList "/install /quiet /norestart" -Wait

Write-Host "[4/4] Membuat Shortcut Desktop..." -ForegroundColor Cyan
$sebExe = "C:\Program Files\SafeExamBrowser\SafeExamBrowser.exe"
if (-not (Test-Path $sebExe)) { $sebExe = "C:\Program Files (x86)\SafeExamBrowser\SafeExamBrowser.exe" }

$lnk = (New-Object -ComObject WScript.Shell).CreateShortcut("C:\Users\Public\Desktop\Ujian CBT.lnk")
$lnk.TargetPath = $sebExe
$lnk.Arguments  = "`"$cfgDir\SebClientSettings.seb`""
$lnk.Save()

Remove-Item $tmp -Recurse -Force
Write-Host "SUKSES: SEB Berhasil Terpasang!" -ForegroundColor Green
