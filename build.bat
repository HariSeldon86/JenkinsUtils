@echo off
echo [1/5] Stopping Jenkins containers (including volumes)...
docker-compose down -v

echo [2/5] Cleaning up jenkins_home directory...
if exist jenkins_home (
    rmdir /s /q jenkins_home
)
mkdir jenkins_home

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
docker-compose up --build -d

echo.
echo Setup complete! 
echo Jenkins is starting up...
echo Check the logs for any errors >> docker-compose logs -f
echo Plugins are being installed in the background.
echo Access Jenkins at: http://localhost:8080