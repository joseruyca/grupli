$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

if (-not (Test-Path ".\pubspec.yaml")) {
  throw "No estoy en la carpeta del proyecto Flutter. Falta pubspec.yaml."
}

Get-Command flutter -ErrorAction Stop | Out-Null

if (-not (Test-Path ".\android")) {
  Write-Host "Creando carpeta Android con package com.joseruyca.grupli..." -ForegroundColor Cyan
  flutter create --platforms=android --org com.joseruyca --project-name grupli .
}

$GoogleServicesPath = Join-Path $ProjectRoot "android\app\google-services.json"
$HasGoogleServices = Test-Path $GoogleServicesPath
if ($HasGoogleServices) {
  Write-Host "Leyendo android/app/google-services.json..." -ForegroundColor Cyan
  $json = Get-Content $GoogleServicesPath -Raw | ConvertFrom-Json
  $client = $json.client | Select-Object -First 1
  $apiKey = ($client.api_key | Select-Object -First 1).current_key
  $appId = $client.client_info.mobilesdk_app_id
  $senderId = $json.project_info.project_number
  $projectId = $json.project_info.project_id

  $envPath = Join-Path $ProjectRoot ".env"
  if (-not (Test-Path $envPath)) {
    if (Test-Path ".\.env.example") {
      Copy-Item ".\.env.example" $envPath -Force
    } else {
      New-Item -ItemType File -Path $envPath | Out-Null
    }
  }

  function Set-EnvValue([string]$Path, [string]$Key, [string]$Value) {
    $lines = @()
    if (Test-Path $Path) { $lines = Get-Content $Path }
    $escaped = $Value.Replace('`', '``')
    $found = $false
    $updated = foreach ($line in $lines) {
      if ($line -match "^\s*$([regex]::Escape($Key))\s*=") {
        $found = $true
        "$Key=$escaped"
      } else {
        $line
      }
    }
    if (-not $found) { $updated += "$Key=$escaped" }
    Set-Content -Path $Path -Value $updated -Encoding UTF8
  }

  Set-EnvValue $envPath "FIREBASE_API_KEY" $apiKey
  Set-EnvValue $envPath "FIREBASE_APP_ID" $appId
  Set-EnvValue $envPath "FIREBASE_MESSAGING_SENDER_ID" $senderId
  Set-EnvValue $envPath "FIREBASE_PROJECT_ID" $projectId
  Write-Host "Variables Firebase actualizadas en .env" -ForegroundColor Green
} else {
  Write-Warning "No existe android/app/google-services.json. La APK compilará, pero las push reales no funcionarán hasta añadirlo."
}

$manifestPath = Join-Path $ProjectRoot "android\app\src\main\AndroidManifest.xml"
if (Test-Path $manifestPath) {
  $manifest = Get-Content $manifestPath -Raw
  function Add-ManifestPermission([string]$Xml, [string]$Permission) {
    if ($Xml -match [regex]::Escape($Permission)) { return $Xml }
    return [regex]::Replace($Xml, '<manifest([^>]*)>', {
      param($m)
      "<manifest$($m.Groups[1].Value)>`n    <uses-permission android:name=`"$Permission`" />"
    }, 1)
  }
  $manifest = Add-ManifestPermission $manifest 'android.permission.POST_NOTIFICATIONS'
  $manifest = Add-ManifestPermission $manifest 'android.permission.INTERNET'

  # Invitaciones reales móvil/web: Android App Links + esquema propio.
  if ($manifest -notmatch 'android:host="grupli.vercel.app"') {
    $inviteFilters = @'
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data
                    android:scheme="https"
                    android:host="grupli.vercel.app"
                    android:pathPrefix="/join" />
            </intent-filter>
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data
                    android:scheme="grupli"
                    android:host="join" />
            </intent-filter>
'@
    $manifest = [regex]::Replace($manifest, '(</activity>)', "$inviteFilters`n            `$1", 1)
  }

  if ($manifest -notmatch 'com.google.firebase.messaging.default_notification_channel_id') {
    $meta = @'
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="grupli_general" />
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@mipmap/ic_launcher" />
'@
    $manifest = $manifest -replace '</application>', "$meta`n    </application>"
  }
  Set-Content -Path $manifestPath -Value $manifest -Encoding UTF8
  Write-Host "AndroidManifest preparado para notificaciones." -ForegroundColor Green
}

if ($HasGoogleServices) {
$settingsGradle = Join-Path $ProjectRoot "android\settings.gradle"
$settingsGradleKts = Join-Path $ProjectRoot "android\settings.gradle.kts"
if (Test-Path $settingsGradle) {
  $settings = Get-Content $settingsGradle -Raw
  if ($settings -notmatch 'com.google.gms.google-services') {
    $settings = $settings -replace 'plugins\s*\{', "plugins {`n    id `"com.google.gms.google-services`" version `"4.4.3`" apply false"
    Set-Content -Path $settingsGradle -Value $settings -Encoding UTF8
    Write-Host "settings.gradle preparado con Google Services." -ForegroundColor Green
  }
}
if (Test-Path $settingsGradleKts) {
  $settings = Get-Content $settingsGradleKts -Raw
  if ($settings -notmatch 'com.google.gms.google-services') {
    $settings = $settings -replace 'plugins\s*\{', "plugins {`n    id(`"com.google.gms.google-services`") version `"4.4.3`" apply false"
    Set-Content -Path $settingsGradleKts -Value $settings -Encoding UTF8
    Write-Host "settings.gradle.kts preparado con Google Services." -ForegroundColor Green
  }
}

$appGradle = Join-Path $ProjectRoot "android\app\build.gradle"
$appGradleKts = Join-Path $ProjectRoot "android\app\build.gradle.kts"
if (Test-Path $appGradle) {
  $gradle = Get-Content $appGradle -Raw
  if ($gradle -notmatch 'com.google.gms.google-services') {
    $gradle = $gradle -replace 'plugins\s*\{', "plugins {`n    id `"com.google.gms.google-services`""
    Set-Content -Path $appGradle -Value $gradle -Encoding UTF8
    Write-Host "app/build.gradle preparado con Google Services." -ForegroundColor Green
  }
}
if (Test-Path $appGradleKts) {
  $gradle = Get-Content $appGradleKts -Raw
  if ($gradle -notmatch 'com.google.gms.google-services') {
    $gradle = $gradle -replace 'plugins\s*\{', "plugins {`n    id(`"com.google.gms.google-services`")"
    Set-Content -Path $appGradleKts -Value $gradle -Encoding UTF8
    Write-Host "app/build.gradle.kts preparado con Google Services." -ForegroundColor Green
  }
}

} else {
  Write-Warning "No aplico el plugin Google Services porque falta google-services.json. Cuando lo añadas, vuelve a ejecutar este script."
}

Write-Host "Firebase Android preparado. Ahora puedes ejecutar .\scripts\build_android_debug_apk.ps1" -ForegroundColor Green
