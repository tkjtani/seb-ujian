# install.ps1
$ErrorActionPreference = "Stop"

# 1. Validasi Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Wajib dijalankan sebagai Administrator (Run as Administrator)!"
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 2. URL Resmi SEB Windows (v3.10.2) & Konfigurasi Sekolah
$sebInstallerUrl = "https://github.com/SafeExamBrowser/seb-win-refactoring/releases/download/v3.10.2/SEB_3.10.2.920_SetupBundle.exe"
$sebFallbackUrl  = "https://sourceforge.net/projects/seb/files/seb/SEB_3.10.2/SEB_3.10.2.920_SetupBundle.exe/download"
$sebConfigUrl    = "https://raw.githubusercontent.com/tkjtani/seb-ujian/refs/heads/main/SebClientSettings.seb"

$tmp    = "$env:TEMP\seb-deploy"
$cfgDir = "C:\ProgramData\SEB"
New-Item -ItemType Directory -Force -Path $tmp, $cfgDir | Out-Null

# Fungsi download tangguh (mencoba link utama, jika gagal pakai fallback)
function Download-FileSafe ($primaryUrl, $fallbackUrl, $outputPath) {
    $downloadSuccess = $false

    # Coba URL Utama
    if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
        Write-Host "Mengunduh dari server utama..." -ForegroundColor DarkCyan
        & curl.exe -f -L --retry 2 -o $outputPath $primaryUrl
        if ($LASTEXITCODE -eq 0 -and (Test-Path $outputPath) -and (Get-Item $outputPath).Length -gt 1000000) {
            $downloadSuccess = $true
        }
    }

    # Jika gagal, coba URL Fallback
    if (-not $downloadSuccess -and $fallbackUrl) {
        Write-Host "Server utama gagal, beralih ke mirror cadangan..." -ForegroundColor Yellow
        & curl.exe -f -L --retry 2 -o $outputPath $fallbackUrl
        if ($LASTEXITCODE -eq 0 -and (Test-Path $outputPath) -and (Get-Item $outputPath).Length -gt 1000000) {
            $downloadSuccess = $true
        }
    }

    # Fallback terakhir menggunakan .NET WebClient jika curl bermasalah
    if (-not $downloadSuccess) {
        Write-Host "Mencoba metode WebClient..." -ForegroundColor Yellow
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent", "Mozilla/5.0")
        $target = if ($fallbackUrl) { $fallbackUrl } else { $primaryUrl }
        $wc.DownloadFile($target, $outputPath)
        if ((Test-Path $outputPath) -and (Get-Item $outputPath).Length -gt 1000000) {
            $downloadSuccess = $true
        }
    }

    if (-not $downloadSuccess) {
        throw "Gagal mengunduh file dari semua sumber yang tersedia."
    }
}

# 3. Download Installer & Konfigurasi
Write-Host "[1/4] Mengunduh SEB Installer (~180 MB, mohon tunggu)..." -ForegroundColor Cyan
Download-FileSafe $sebInstallerUrl $sebFallbackUrl "$tmp\SEB_Setup.exe"

Write-Host "[2/4] Mengunduh File Konfigurasi Ujian..." -ForegroundColor Cyan
& curl.exe -f -L -s -S -o "$cfgDir\SebClientSettings.seb" $sebConfigUrl

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
Write-Host "SUKSES: Safe Exam Browser dan konfigurasi ujian berhasil terpasang!" -ForegroundColor Green
