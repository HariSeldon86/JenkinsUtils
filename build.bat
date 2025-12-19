@echo off
set "MODE=update"
set "COMPOSE_FILE=docker-compose.yml"

REM Parse arguments
:parse_args
if "%~1"=="" goto end_parse
if "%~1"=="--clean" set "MODE=clean"
if "%~1"=="--update" set "MODE=update"
if "%~1"=="--tailscale" set "COMPOSE_FILE=docker-compose.tailscale.yml"
shift
goto parse_args
:end_parse

echo Mode: %MODE%
echo Compose file: %COMPOSE_FILE%


if "%MODE%"=="clean" (
    echo [1/5] Stopping Jenkins containers and removing volumes...
    docker compose -f docker-compose.yml down -v
    docker compose -f docker-compose.tailscale.yml down -v

    echo [2/5] Cleaning up directories...
    if exist jenkins_home (
        rmdir /s /q jenkins_home
    )
    if exist tailscale_state (
        rmdir /s /q tailscale_state
    )
) else (
    echo [1-2/5] Skipping clean steps ^(incremental update^).
)

echo [3/5] Generating Jenkins JCasC configuration...
:: Run the python generator
uv sync --locked
uv run generate-jenkins-config.py

echo [4/5] Check env file is available
if not exist .env (
    echo .env file not found. Please copy .env.example to .env and fill in the values.
    exit /b 1
)

echo [5/5] Rebuilding and starting Jenkins (detached)...
:: --build ensures changes in Dockerfile or plugins.txt are applied
docker compose -f %COMPOSE_FILE% up --build -d

echo.
echo Setup complete! 
echo Jenkins is starting up (Mode: %MODE%, Compose: %COMPOSE_FILE%)...
echo Check the logs for any errors: docker compose -f %COMPOSE_FILE% logs -f
echo Plugins are being installed in the background.
if "%COMPOSE_FILE%"=="docker-compose.tailscale.yml" (
    echo Access Jenkins at: http://jenkins-utils:8080 ^(via Tailscale^) or http://localhost:8080
) else (
    echo Access Jenkins at: http://localhost:8080
)
