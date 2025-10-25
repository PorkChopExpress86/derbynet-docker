#!/usr/bin/env bash
# Helper: create .env from example (if missing) and start docker compose
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir"

if [[ ! -f .env ]]; then
    cp .env.example .env
    printf 'Created .env from .env.example. Edit .env to set passwords or ports if you want.\n'
fi

printf 'Starting DerbyNet stack (docker compose up -d)...\n'
docker compose up -d

printf 'Current containers:\n'
docker compose ps

port=8050
if [[ -f .env ]]; then
    if port_line=$(grep -E '^[[:space:]]*HTTP_PORT[[:space:]]*=' .env | tail -n 1); then
        if [[ $port_line =~ ([0-9]+) ]]; then
            port="${BASH_REMATCH[1]}"
        fi
    fi
fi

url="http://localhost:${port}"
if command -v xdg-open >/dev/null 2>&1; then
    printf 'Opening DerbyNet in your default browser: %s\n' "$url"
    xdg-open "$url" >/dev/null 2>&1 &
elif command -v open >/dev/null 2>&1; then
    printf 'Opening DerbyNet in your default browser: %s\n' "$url"
    open "$url"
else
    printf 'DerbyNet is available at: %s\n' "$url"
fi
