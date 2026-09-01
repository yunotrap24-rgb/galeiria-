param(
    [switch]$Lan
)

$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
$ApiPath = Join-Path $RepoRoot 'services/api'
$VenvPath = Join-Path $ApiPath '.venv'
$Python = Join-Path $VenvPath 'Scripts/python.exe'

if (-not (Test-Path $Python)) {
    Write-Host 'Criando ambiente Python do Galeiria...'
    python -m venv $VenvPath
}

& $Python -m pip install -e "$ApiPath[dev]"

$HostAddress = if ($Lan) { '0.0.0.0' } else { '127.0.0.1' }
if ($Lan) {
    Write-Warning 'Modo LAN ativado. Dispositivos remotos precisam do token de pareamento do Galeiria.'
}

$env:GALEIRIA_HOST = $HostAddress
$env:GALEIRIA_PORT = '8765'
& $Python -m uvicorn app.main:app --app-dir $ApiPath --host $HostAddress --port 8765 --reload
