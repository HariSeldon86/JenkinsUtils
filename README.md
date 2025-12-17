# JenkinsUtils

## Setup Instructions

### 1. Start Jenkins

```bash
docker-compose up -d
```

This will:

* Build the custom Jenkins image with Docker CLI and Docker Compose
* Start Jenkins on port 8080
* Create a persistent volume for Jenkins data
* Give Jenkins access to Docker


### 2. Get Initial Admin Password

```bash
docker-compose exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

### 3. Access Jenkins
Open your browser: [http://localhost:8080](http://localhost:8080)


## Useful Commands

### View logs:

```bash
docker-compose logs -f jenkins
```

### Stop Jenkins:

```bash
docker-compose down
```

### Restart Jenkins:

```bash
docker-compose restart
```

### Rebuild after Dockerfile changes:

```bash
docker-compose up -d --build
```

### Remove everything (including volume):

```bash
docker-compose down -v
```