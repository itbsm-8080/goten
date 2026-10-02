<#
.SYNOPSIS
    Build APK release GOTEN lalu cetak version.json yang siap di-upload.

.DESCRIPTION
    Menambah nomor versi di pubspec.yaml, build dengan release key dari
    android/key.properties, lalu menghitung md5 APK untuk diisi ke version.json.

    Script ini SENGAJA tidak menyentuh server. Upload APK + version.json dilakukan
    manual ke http://103.103.22.7/cutikaryawan/apk/.

.EXAMPLE
    .\scripts\publish.ps1 -Catatan "Perbaikan absensi shift 20"
#>
param(
    [string]$Versi,
    [int]$Kode,
    [string]$Catatan = '',
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$pubspec = Join-Path $root 'pubspec.yaml'
$apk = Join-Path $root 'build\app\outputs\flutter-apk\app-release.apk'
$keytool = 'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe'

if (-not (Test-Path $pubspec)) { throw "pubspec.yaml tidak ditemukan: $pubspec" }
if (-not (Test-Path $apk -PathType Leaf) -and -not $Force) {
    Write-Host 'Build dulu (script ini juga bisa build sendiri, tapi lebih lama).' -ForegroundColor Yellow
}

# --- Status git: lebih aman publish dari tree bersih ---
$dirty = git -C $root status --porcelain
if ($dirty -and -not $Force) {
    Write-Host 'Ada perubahan yang belum di-commit:' -ForegroundColor Yellow
    $dirty | Select-Object -First 10 | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
    throw 'Commit dulu, atau jalankan ulang dengan -Force.'
}

# --- Versi sekarang ---
$pub = Get-Content $pubspec -Raw
if ($pub -notmatch '(?m)^version:\s*(\S+)\+(\d+)') {
    throw 'Baris "version:" tidak ditemukan di pubspec.yaml'
}
$versiLama = $Matches[1]
$kodeLama = [int]$Matches[2]

if (-not $Versi) {
    $Versi = Read-Host "Versi baru (sekarang $versiLama)"
}
if (-not $Kode) {
    $suggest = $kodeLama + 1
    $input = Read-Host "versionCode baru (sekarang $kodeLama, saran $suggest)"
    $Kode = if ($input) { [int]$input } else { $suggest }
}
if ($Kode -le $kodeLama) {
    throw "versionCode harus lebih besar dari $kodeLama (Android menolak APK versi turun)."
}

Write-Host ''
Write-Host "Versi  : $versiLama -> $Versi" -ForegroundColor Cyan
Write-Host "Kode   : $kodeLama -> $Kode" -ForegroundColor Cyan
Write-Host ''

# --- Tulis pubspec ---
$pub = $pub -replace '(?m)^version:\s*\S+\+\d+', "version: $Versi+$Kode"
Set-Content -Path $pubspec -Value $pub -NoNewline -Encoding utf8
Write-Host "pubspec.yaml ditulis: version: $Versi+$Kode" -ForegroundColor Green

# --- Build ---
Write-Host ''
Write-Host 'Build APK release (bisa beberapa menit)...' -ForegroundColor Cyan
$flutter = Join-Path $root '.fvm\flutter_sdk\bin\flutter.bat'
if (-not (Test-Path $flutter)) { $flutter = 'flutter' }

Push-Location $root
try {
    & $flutter build apk --release `
        --dart-define="APP_VERSION_CODE=$Kode" `
        --dart-define="APP_VERSION_NAME=$Versi"
    if ($LASTEXITCODE -ne 0) { throw "Build gagal (exit $LASTEXITCODE)" }
} finally {
    Pop-Location
}

if (-not (Test-Path $apk)) { throw "APK tidak ditemukan setelah build: $apk" }

# --- md5 + ukuran ---
$md5 = (Get-FileHash $apk -Algorithm MD5).Hash.ToLower()
$ukuran = (Get-Item $apk).Length

# --- Certificate, biar Signing key tidak tertukar ---
Write-Host ''
Write-Host '=== Certificate APK ===' -ForegroundColor Cyan
& $keytool -printcert -jarfile $apk 2>&1 |
    Select-String -Pattern 'Owner|SHA1:' |
    ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }

# --- version.json siap upload ---
$baseUrl = ($env:APK_BASE_URL)
if (-not $baseUrl) { $baseUrl = 'http://103.103.22.7/cutikaryawan/apk' }
$namaApk = "goten-release-$Kode.apk"
$catatanJson = if ($Catatan) { $Catatan } else { '' }

$json = @"
{
  "version_code": $Kode,
  "version_name": "$Versi",
  "url": "$baseUrl/$namaApk",
  "md5": "$md5",
  "ukuran": $ukuran,
  "wajib": false,
  "catatan": "$catatanJson"
}
"@

Write-Host ''
Write-Host '=== Upload manual ke server ===' -ForegroundColor Yellow
Write-Host "  1. APK      : $namaApk" -ForegroundColor Gray
Write-Host "  2. MD5      : $md5" -ForegroundColor Gray
Write-Host "  3. Ukuran   : $([math]::Round($ukuran / 1MB, 2)) MB ($ukuran byte)" -ForegroundColor Gray
Write-Host ''
Write-Host '  Tulis version.json berikut ke:' -ForegroundColor Yellow
Write-Host "  $baseUrl/version.json" -ForegroundColor White
Write-Host ''
Write-Host $json -ForegroundColor DarkGray
Write-Host ''
Write-Host "  Posted ke $baseUrl" -ForegroundColor DarkGray