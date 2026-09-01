$ErrorActionPreference = 'Stop'

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw 'Flutter nao foi encontrado no PATH. Instale o Flutter SDK antes de executar este script.'
}

$RepoRoot = Split-Path -Parent $PSScriptRoot

function Bootstrap-FlutterApp {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$Platforms,
        [Parameter(Mandatory = $true)][string]$ProjectName
    )

    $AppPath = Join-Path $RepoRoot $RelativePath
    $PubspecPath = Join-Path $AppPath 'pubspec.yaml'
    $MainPath = Join-Path $AppPath 'lib/main.dart'

    $Pubspec = Get-Content $PubspecPath -Raw
    $Main = Get-Content $MainPath -Raw

    Push-Location $AppPath
    try {
        flutter create . --platforms=$Platforms --project-name=$ProjectName
        Set-Content -Path $PubspecPath -Value $Pubspec -Encoding UTF8
        New-Item -ItemType Directory -Force -Path (Split-Path $MainPath) | Out-Null
        Set-Content -Path $MainPath -Value $Main -Encoding UTF8
        flutter pub get
    }
    finally {
        Pop-Location
    }
}

Write-Host 'Gerando runner Windows...'
Bootstrap-FlutterApp -RelativePath 'apps/desktop' -Platforms 'windows' -ProjectName 'galeiria_desktop'

Write-Host 'Gerando runner Android...'
Bootstrap-FlutterApp -RelativePath 'apps/mobile' -Platforms 'android' -ProjectName 'galeiria_mobile'

$Manifest = Join-Path $RepoRoot 'apps/mobile/android/app/src/main/AndroidManifest.xml'
if (Test-Path $Manifest) {
    $Content = Get-Content $Manifest -Raw
    if ($Content -notmatch 'android.permission.INTERNET') {
        $Content = $Content -replace '(<manifest[^>]*>)', "$1`r`n    <uses-permission android:name=`"android.permission.INTERNET`" />"
    }
    if ($Content -notmatch 'usesCleartextTraffic') {
        $Content = $Content -replace '<application', '<application android:usesCleartextTraffic="true"'
    }
    Set-Content -Path $Manifest -Value $Content -Encoding UTF8
}

Write-Host 'Flutter bootstrap concluido.'
Write-Host 'Desktop: cd apps/desktop; flutter run -d windows'
Write-Host 'Mobile:  cd apps/mobile; flutter run -d android'
