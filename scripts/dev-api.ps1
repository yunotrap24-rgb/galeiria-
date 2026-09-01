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
$env:GALEIRIA_HOST = '0.0.0.0'
$env:GALEIRIA_PORT = '8765'
& $Python -m uvicorn app.main:app --app-dir $ApiPath --host 0.0.0.0 --port 8765 --reload
