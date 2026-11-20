# Jalankan SEKALI dari folder app (PowerShell):  .\setup_android.ps1
# 1) membuat folder android/ios dll lewat "flutter create", 2) menambah izin internet/lokasi + HTTP lokal.
$ErrorActionPreference = "Stop"
if (-not (Test-Path "android")) {
  flutter create --org id.lindungikita --project-name lindungikita --platforms=android,ios .
}
flutter pub get

$m = "android\app\src\main\AndroidManifest.xml"
$x = Get-Content $m -Raw
if ($x -notmatch "ACCESS_FINE_LOCATION") {
  $perm = @"

    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    <queries>
        <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="https"/></intent>
        <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="tel"/></intent>
        <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="sms"/></intent>
    </queries>
"@
  $x = $x -replace '(<manifest[^>]*>)', ('$1' + $perm)
  $x = $x -replace '<application', '<application android:usesCleartextTraffic="true"'
  $x = $x -replace 'android:label="[^"]*"', 'android:label="LindungiKita"'
  Set-Content $m $x -Encoding UTF8
  Write-Host "AndroidManifest.xml sudah diperbarui."
} else {
  Write-Host "AndroidManifest.xml sudah berisi izin, dilewati."
}
Write-Host "Selesai. Jalankan:  flutter run"
