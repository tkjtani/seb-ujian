# ==============================================================================
# SCRIPT DEPLOYMENT OTOMATIS SAFE EXAM BROWSER & KONFIGURASI CBT
# Repositori : tkjtani/seb-ujian
# ==============================================================================
$ErrorActionPreference = "Stop"

# 1. Pastikan script berjalan dengan hak akses Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Script ini WAJIB dijalankan sebagai Administrator (Run as Administrator)!"
}

# Aktifkan protokol TLS 1.2 untuk koneksi aman
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 2. Definisi URL Resmi & Path
$sebUrl = "https://github.com/SafeExamBrowser/seb-win-refactoring/releases/download/v3.10.2/SEB_3.10.2.920_SetupBundle.exe"
$cfgUrl = "https://raw.githubusercontent.com/tkjtani/seb-ujian/refs/heads/main/SebClientSettings.seb"
$tmp    = "$env:TEMP\seb-deploy"
$cfgDir = "C:\ProgramData\SEB"

# Buat folder kerja
New-Item -ItemType Directory -Force -Path $tmp, $cfgDir | Out-Null

# 3. Unduh Installer SEB (~180 MB)
Write-Host "[1/4] Mengunduh Installer SEB v3.10.2 dari server resmi..." -ForegroundColor Cyan
& curl.exe -f -L -# -o "$tmp\SEB_Setup.exe" $sebUrl

if (-not (Test-Path "$tmp\SEB_Setup.exe") -or (Get-Item "$tmp\SEB_Setup.exe").Length -lt 10000000) {
    throw "Gagal mengunduh file SEB_Setup.exe atau file rusak."
}

# 4. Unduh Konfigurasi Ujian Sekolah
Write-Host "[2/4] Mengunduh File Konfigurasi Ujian (SebClientSettings.seb)..." -ForegroundColor Cyan
& curl.exe -f -L -s -S -o "$cfgDir\SebClientSettings.seb" $cfgUrl

# 5. Instalasi Hening (Silent Install di latar belakang)
Write-Host "[3/4] Menginstal Safe Exam Browser (proses 1-2 menit)..." -ForegroundColor Cyan
$install = Start-Process -FilePath "$tmp\SEB_Setup.exe" -ArgumentList "/install /quiet /norestart" -Wait -PassThru

# 6. Cari lokasi aplikasi & Buat Shortcut di Desktop Semua User
Write-Host "[4/4] Menyiapkan Shortcut Ujian di Desktop..." -ForegroundColor Cyan
$sebExe = "C:\Program Files\SafeExamBrowser\SafeExamBrowser.exe"
if (-not (Test-Path $sebExe)) {
    $sebExe = "C:\Program Files (x86)\SafeExamBrowser\SafeExamBrowser.exe"
}

if (Test-Path $sebExe) {
    $wsh = New-Object -ComObject WScript.Shell
    $lnk = $wsh.CreateShortcut("C:\Users\Public\Desktop\Ujian CBT.lnk")
    $lnk.TargetPath = $sebExe
    $lnk.Arguments  = "`"$cfgDir\SebClientSettings.seb`""
    $lnk.Save()
} else {
    Write-Warning "SafeExamBrowser.exe belum terdeteksi. Silakan restart PC."
}

# Bersihkan temporary installer
Remove-Item $tmp -Recurse -Force
Write-Host "`n========================================================" -ForegroundColor Green
Write-Host " SUKSES: SEB & Konfigurasi Ujian Berhasil Terpasang! " -ForegroundColor Green
Write-Host " Shortcut 'Ujian CBT' siap digunakan di Desktop.       " -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
