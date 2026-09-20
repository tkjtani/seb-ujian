# install.ps1
$ErrorActionPreference = "Stop"

# 1. Validasi Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Wajib dijalankan sebagai Administrator (Run as Administrator)!"
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 2. URL Sumber (GitHub)
$sebInstallerUrl = "https://github.com/SafeExamBrowser/seb-win-refactoring/releases/download/v3.7.1/SEB_3.7.1.663_SetupBundle.exe"
$sebConfigUrl    = "https://raw.githubusercontent.com/tkjtani/seb-ujian/refs/heads/main/SebClientSettings.seb"

$tmp    = "$env:TEMP\seb-deploy"
$cfgDir = "C:\ProgramData\SEB"
New-Item -ItemType Directory -Force -Path $tmp, $cfgDir | Out-Null

# Fungsi download yang stabil untuk file besar (menggunakan curl bawaan Windows atau WebClient)
function Download-FileSafe ($url, $outputPath) {
    if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
        & curl.exe -f -L -s -S --retry 3 -o $outputPath $url
    } else {
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent", "Mozilla/5.0")
        $wc.DownloadFile($url, $outputPath)
    }
}

# 3. Download Installer & Konfigurasi
Write-Host "[1/4] Mengunduh SEB Installer (~180 MB, mohon tunggu)..." -ForegroundColor Cyan
Download-FileSafe $sebInstallerUrl "$tmp\SEB_Setup.exe"

Write-Host "[2/4] Mengunduh File Konfigurasi Ujian..." -ForegroundColor Cyan
Download-FileSafe $sebConfigUrl "$cfgDir\SebClientSettings.seb"

# 4. Instalasi Hening (Silent Install)
Write-Host "[3/4] Menginstal Safe Exam Browser di latar belakang..." -ForegroundColor Cyan
$process = Start-Process -FilePath "$tmp\SEB_Setup.exe" -ArgumentList "/install /quiet /norestart" -Wait -PassThru

# 5. Buat Shortcut di Desktop Semua Siswa
Write-Host "[4/4] Membuat Shortcut di Desktop..." -ForegroundColor Cyan
$sebExe = "C:\Program Files\SafeExamBrowser\SafeExamBrowser.exe"
if (-not (Test-Path $sebExe)) {
    $sebExe = "C:\Program Files (x86)\SafeExamBrowser\SafeExamBrowser.exe"
}

$lnk = (New-Object -ComObject WScript.Shell).CreateShortcut("C:\Users\Public\Desktop\Ujian CBT.lnk")
$lnk.TargetPath = $sebExe
$lnk.Arguments  = "`"$cfgDir\SebClientSettings.seb`""
$lnk.Save()

# Bersihkan file temporary installer
Remove-Item $tmp -Recurse -Force
Write-Host "SUKSES: SEB dan konfigurasi berhasil dipasang!" -ForegroundColor Green
