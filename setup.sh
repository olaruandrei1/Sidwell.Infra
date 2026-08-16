#!/bin/bash
set -e

GITHUB_USER="${GITHUB_USER:?Set GITHUB_USER before running}"
SIDWELL_HOME=/opt/sidwell

if ! command -v docker &>/dev/null; then
    apt-get update -qq
    apt-get install -y docker.io docker-compose-plugin git
    systemctl enable --now docker
fi

mkdir -p "$SIDWELL_HOME"

clone_or_pull() {
    local repo=$1 dest=$2
    if [ -d "$dest/.git" ]; then
        git -C "$dest" pull origin main
    else
        git clone "https://github.com/$GITHUB_USER/$repo" "$dest"
    fi
}

clone_or_pull Sidwell.Infra           "$SIDWELL_HOME/infra"
clone_or_pull Sidwell.Core            "$SIDWELL_HOME/core"
clone_or_pull Sidwell.Core.Algorithms "$SIDWELL_HOME/algorithms"
clone_or_pull Sidwell.Backend         "$SIDWELL_HOME/backend"
clone_or_pull Sidwell.Sync                  "$SIDWELL_HOME/sync"
clone_or_pull Sidwell.Sync.YfinanceAdapter  "$SIDWELL_HOME/sync/yfinance"
clone_or_pull Sidwell.Broadcasting    "$SIDWELL_HOME/broadcasting"
clone_or_pull Sidwell.Frontend        "$SIDWELL_HOME/frontend"

if [ ! -f "$SIDWELL_HOME/infra/.env" ]; then
    cp "$SIDWELL_HOME/infra/.env.example" "$SIDWELL_HOME/infra/.env"
    echo "Completeaza $SIDWELL_HOME/infra/.env, apoi ruleaza din nou scriptul."
    exit 0
fi

cd "$SIDWELL_HOME/infra"
docker compose up -d --build
docker image prune -f

echo "Frontend:     https://$(grep '^DOMAIN=' .env | cut -d= -f2)"
echo "Backend API:  https://api.$(grep '^DOMAIN=' .env | cut -d= -f2)/api"
echo "Broadcasting: https://broadcast.$(grep '^DOMAIN=' .env | cut -d= -f2)"
