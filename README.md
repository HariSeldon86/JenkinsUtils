# JenkinsUtils

A Jenkins Orchestration utility designed to automate the deployment and configuration of a Jenkins instance using **Jenkins Configuration as Code (JCasC)** and **Job DSL**.

## Project Scope

The goal of this project is to provide a "Jenkins-in-a-Box" experience where the entire setup—from plugin installation to job creation—is automated and version-controlled.

- **Infrastructure as Code**: Uses Docker Compose to manage the Jenkins environment.
- **Dynamic Job Generation**: A Python-based generator (`generate-jenkins-config.py`) reads `applications.yaml` to automatically create Jenkins jobs for specified GitHub repositories.
- **Plugin Management**: Pre-installs a curated set of plugins defined in `plugins.txt`.
- **Security & Persistence**: Configured for persistent storage and Docker-out-of-Docker (DooD) capabilities.

## Build Scripts

The project includes cross-platform build scripts (`build.bat` for Windows and `build.sh` for Linux/macOS) to streamline the setup process.

### What the build scripts do:
1. **Clean Environment**: Stops existing Jenkins containers and removes volumes to ensures a fresh start.
2. **Directory Cleanup**: Wipes the `jenkins_home` directory.
3. **Configuration Generation**: 
   - Uses `uv sync` to manage Python dependencies.
   - Runs `generate-jenkins-config.py` to convert `applications.yaml` into Jenkins Configuration as Code (`jenkins_casc.yml`).
4. **Rebuild & Launch**: 
   - Builds the custom Docker image (applying any `plugins.txt` changes).
   - Starts Jenkins in detached mode.
5. **Monitoring**: Provides a shortcut command to monitor startup logs.

## Setup Instructions

### Prerequisites

- Docker and Docker Compose
- Python 3.12
- `uv` (Python version manager)
- `.env` file (copy `.env.example` to `.env` and fill in the values)

### 1. Run the Build Script

**On Windows:**
```cmd
build.bat
```

**On Linux/macOS:**
```bash
chmod +x build.sh
./build.sh
```

### 2. Follow the Logs
Since Jenkins is started in detached mode, you should monitor the logs to see the plugin installation progress and wait for Jenkins to be fully ready:
```bash
docker-compose logs -f
```

### 3. Access Jenkins
Once initialized, open your browser: [http://localhost:8080](http://localhost:8080)

## Useful Commands

### Stop Jenkins:
```bash
docker-compose down
```

### Remove everything (including volumes):
```bash
docker-compose down -v
```

### Rebuild after Dockerfile or Plugin changes:
```bash
docker-compose up -d --build
```
