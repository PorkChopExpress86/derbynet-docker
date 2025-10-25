# Helper: create .env from example (if missing) and start docker compose
Set-StrictMode -Version Latest
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir
if (-not (Test-Path .env)) {
    Copy-Item .env.example .env
    Write-Host "Created .env from .env.example. Edit .env to set passwords or ports if you want." -ForegroundColor Yellow
}

Write-Host "Starting DerbyNet stack (docker compose up -d)..." -ForegroundColor Cyan
docker compose up -d

Write-Host "Current containers:" -ForegroundColor Cyan
docker compose ps

# Try to read HTTP_PORT from .env
$port = 8050
if (Test-Path .env) {
    foreach ($line in Get-Content .env) {
        if ($line -match '^[ \t]*HTTP_PORT[ \t]*=[ \t]*(\d+)') { $port = $Matches[1]; break }
    }
}

Write-Host "Opening DerbyNet in your default browser: http://localhost:$port" -ForegroundColor Green
Start-Process "http://localhost:$port"
