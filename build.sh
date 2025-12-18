#!/usr/bin/env bash

# Exit on error
set -e

MODE="update"
if [ "$1" == "--clean" ]; then
    MODE="clean"
elif [ "$1" == "--update" ]; then
    MODE="update"
fi

echo "Mode: $MODE"

if [ "$MODE" == "clean" ]; then
    echo "[1/5] Stopping Jenkins containers and removing volumes..."
    docker-compose down -v

    echo "[2/5] Cleaning up jenkins_home directory..."
    rm -rf jenkins_home
    mkdir jenkins_home
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
docker-compose up --build -d

echo ""
echo "Setup complete!" 
echo "Jenkins is starting up (Mode: $MODE)..."
echo "Check the logs for any errors: docker-compose logs -f"
echo "Plugins are being installed in the background."
echo "Access Jenkins at: http://localhost:8080"

