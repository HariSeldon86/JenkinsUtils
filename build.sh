#!/usr/bin/env bash

# Exit on error
set -e

MODE="update"
COMPOSE_FILE="docker-compose.yml"

# Parse arguments
for arg in "$@"; do
    if [ "$arg" == "--clean" ]; then
        MODE="clean"
    elif [ "$arg" == "--update" ]; then
        MODE="update"
    elif [ "$arg" == "--tailscale" ]; then
        COMPOSE_FILE="docker-compose.tailscale.yml"
    fi
done

echo "Mode: $MODE"
echo "Compose file: $COMPOSE_FILE"


if [ "$MODE" == "clean" ]; then
    echo "[1/5] Stopping Jenkins containers and removing volumes..."
    docker compose -f "docker-compose.yml" down -v
    docker compose -f "docker-compose.tailscale.yml" down -v

    echo "[2/5] Cleaning up directories..."
    # Ensure folder permissions are correct to delete it:
    # sudo chown -R $USER:$USER jenkins_home
    rm -rf jenkins_home
    rm -rf tailscale_state
else
    echo "[1-2/5] Skipping clean steps (incremental update)."
fi

echo "[3/5] Generating Jenkins JCasC configuration..."
# Run the python generator
uv sync --locked
uv run generate-jenkins-config.py

echo "[4/5] Check env file is available"
if [ ! -f .env ]; then
    echo ".env file not found. Please copy .env.example to .env and fill in the values."
    exit 1
fi

echo "[5/5] Rebuilding and starting Jenkins (detached)..."
# --build ensures changes in Dockerfile or plugins.txt are applied
docker compose -f "$COMPOSE_FILE" up --build -d

echo ""
echo "Setup complete!" 
echo "Jenkins is starting up (Mode: $MODE, Compose: $COMPOSE_FILE)..."
echo "Check the logs for any errors: docker compose -f $COMPOSE_FILE logs -f"
echo "Plugins are being installed in the background."
if [ "$COMPOSE_FILE" == "docker-compose.tailscale.yml" ]; then
    echo "Access Jenkins at: http://jenkins-utils:8080 (via Tailscale) or http://localhost:8080"
else
    echo "Access Jenkins at: http://localhost:8080"
fi

