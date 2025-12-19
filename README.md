# JenkinsUtils

A Jenkins Orchestration utility designed to automate the deployment and configuration of a Jenkins instance using **Jenkins Configuration as Code (JCasC)** and **Job DSL**.

## Project Scope

The goal of this project is to provide a "Jenkins-in-a-Box" experience where the entire setup—from plugin installation to job creation—is automated and version-controlled.

- **Infrastructure as Code**: Uses Docker Compose to manage the Jenkins environment.
- **Dynamic Job Generation**: A Python-based generator (`generate-jenkins-config.py`) reads `applications.yaml` to automatically create Jenkins jobs for specified GitHub repositories.
- **Plugin Management**: Pre-installs a curated set of plugins defined in `plugins.txt`.
- **Security & Persistence**: Configured for persistent storage and Docker-out-of-Docker (DooD) capabilities.

## Build Scripts

The project includes cross-platform build scripts (`build.bat` for Windows and `build.sh` for Linux/macOS) to streamline the setup process. These scripts support two modes of operation.

### Modes of Operation:

1.  **Update Mode (Default)**: 
    *   **Usage**: `./build.sh` or `./build.sh --update`
    *   **What it does**: Skips destructive cleanup. Re-generates the JCasC configuration from `applications.yaml` and restarts the Jenkins container applying any changes to the Dockerfile, plugins, or configuration. This is the preferred way to apply changes without losing your Jenkins data.
2.  **Clean Mode**:
    *   **Usage**: `./build.sh --clean`
    *   **What it does**: Perfroms a "factory reset". It stops containers, removes volumes, and wipes the `jenkins_home` directory before performing a fresh build and launch.

### What the build scripts do (Summary):
1.  **Environment Check**: Validates that the `.env` file exists.
2.  **Cleanup (Clean Mode Only)**: Stops existing Jenkins containers, removes volumes, and wipes the local `jenkins_home` directory.
3.  **Configuration Generation**: 
    *   Uses `uv sync` to manage Python dependencies.
    *   Runs `generate-jenkins-config.py` to convert `applications.yaml` into Jenkins Configuration as Code (`jenkins_casc.yml`).
4.  **Rebuild & Launch**: 
    *   Builds the custom Docker image (applying any `Dockerfile` or `plugins.txt` changes).
    *   Starts Jenkins in detached mode.

## Setup Instructions

### Prerequisites

- Docker and Docker Compose
- Python 3.12
- `uv` (Python version manager)
- `.env` file (copy `.env.example` to `.env` and fill in the values)
- Docker GID: Ensure the `DOCKER_GID` in `.env` matches your host's docker group ID.

### 0. Configure Docker GID

To allow Jenkins to interact with the Docker socket, the container needs to know the GID of the `docker` group on your host.

**On Linux:**
Run the following command to find the GID:
```bash
getent group docker | cut -d: -f3
```
Or if `getent` is not available:
```bash
ls -ln /var/run/docker.sock | awk '{print $4}'
```
Update `DOCKER_GID` in your `.env` file with this value (usually `999` or `998`).

**On Windows (Docker Desktop):**
If you are using Docker Desktop with the WSL2 backend, the GID is typically `0` (root) or it handles permissions automatically. However, if you encounter permission issues with `/var/run/docker.sock`, you can check the GID from within your WSL2 terminal with the same command as on Linux; alternatively, you can check the GID from within your Windows terminal with:

```powershell
wsl getent group docker
```
Set `DOCKER_GID=0` (or the value found) in your `.env` if needed.

### 1. Run the Build Script

**On Windows:**
```cmd
:: Incremental update (default)
build.bat

:: Fresh start (destructive)
build.bat --clean

:: With Tailscale (for external access)
build.bat --tailscale

:: Clean build with Tailscale
build.bat --clean --tailscale
```

**On Linux/macOS:**
```bash
chmod +x build.sh

# Incremental update (default)
./build.sh

# Fresh start (destructive)
./build.sh --clean

# With Tailscale (for external access)
./build.sh --tailscale

# Clean build with Tailscale
./build.sh --clean --tailscale
```

## External Access with Tailscale

By default, Jenkins is only accessible on `localhost:8080`. To enable secure external access via Tailscale VPN, use the `--tailscale` flag with the build scripts.

### Prerequisites for Tailscale

1. **Tailscale Account**: Sign up at [https://tailscale.com](https://tailscale.com)
2. **Auth Key**: Generate an auth key from [https://login.tailscale.com/admin/settings/keys](https://login.tailscale.com/admin/settings/keys)
   - Recommended: Enable "Reusable" and "Ephemeral" options
3. **Add to .env**: Set `TS_AUTHKEY=<your-auth-key>` in your `.env` file

### Using Tailscale Mode

When you use the `--tailscale` flag, the build scripts will use `docker-compose.tailscale.yml` instead of the default `docker-compose.yml`. This deploys both Jenkins and Tailscale containers, with Jenkins accessible via your Tailscale network.

**Example:**
```bash
# First time setup with Tailscale
./build.sh --clean --tailscale

# Update with Tailscale
./build.sh --tailscale
```

Once running, access Jenkins from any device on your Tailscale network at:
- **Via Tailscale**: `http://jenkins-utils:8080`
- **Locally**: `http://localhost:8080`

### 2. Follow the Logs
Since Jenkins is started in detached mode, you should monitor the logs to see the plugin installation progress and wait for Jenkins to be fully ready:
```bash
docker compose logs -f
```

### 3. Access Jenkins
Once initialized, open your browser: [http://localhost:8080](http://localhost:8080)

## Useful Commands

### Stop Jenkins:
```bash
docker compose down
```

### Remove everything (including volumes):
```bash
docker compose down -v
```

### Rebuild after Dockerfile or Plugin changes:
```bash
docker compose up -d --build
```

## Applications

The `applications.yaml` file is used to define the applications to be built and deployed. The file is structured as follows:

```yaml
applications:
  - name: application_name
    owner: owner_name
    repo: repo_name
    type: multibranch
    scriptPath: jenkins/Jenkinsfile
    branch: main
```

Each application shall be responsible for its own build process, including the build of the Docker image, with the following folder structure:

```bash
application_name/
├── jenkins/
│   ├── Dockerfile
│   └── Jenkinsfile
|   └── ...
├── ...
```

When applications are added to the `applications.yaml` file, the build script will generate a Jenkins job for each application:

```bash
uv run generate-jenkins-config.py
```

This will update the `jenkins_casc.yml` file in the `jenkins_home` directory.

Finally, update the container to apply the changes:
```bash
docker compose up -d --build
```

The whole update process can be run with `build.bat` or `build.sh`.