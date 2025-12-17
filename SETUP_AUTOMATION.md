# Jenkins Setup Automation

This repo now supports **automated Jenkins pipeline job creation** using Jenkins Configuration as Code (JCasC).

## Quick Start

### 1. Add Applications

Edit `applications.conf` and add your GitHub repositories:

```
my-app|HariSeldon86|my-app
backend-service|HariSeldon86|backend-service
```

Format: `application_name|github_owner|github_repo`

### 2. Generate Configuration

Run the configuration generator:

```bash
python3 generate-jenkins-config.py
```

This creates the job definitions in `jenkins_casc.yml`.

### 3. Set GitHub Credentials

Before restarting Jenkins, you need to provide GitHub credentials. Edit `jenkins_casc.yml` and uncomment the credentials section:

```yaml
credentials:
  system:
    domainCredentials:
      - credentials:
          - usernamePassword:
              scope: GLOBAL
              id: "github-credentials"
              username: "YOUR_GITHUB_USERNAME"
              password: "YOUR_GITHUB_TOKEN"  # Use Personal Access Token, not password
              description: "GitHub Token"
```

**Better approach: Use environment variables**

```yaml
credentials:
  system:
    domainCredentials:
      - credentials:
          - usernamePassword:
              scope: GLOBAL
              id: "github-credentials"
              username: "${GITHUB_USERNAME}"
              password: "${GITHUB_TOKEN}"
              description: "GitHub Token"
```

Then set in `.env`:
```
GITHUB_USERNAME=your_username
GITHUB_TOKEN=your_github_personal_access_token
```

### 4. Restart Jenkins

```bash
docker-compose restart jenkins
```

Jenkins will automatically load the configuration and create all the jobs.

## Workflow

1. **Add new app** → Edit `applications.conf`
2. **Generate config** → Run `python3 generate-jenkins-config.py`
3. **Restart Jenkins** → `docker-compose restart jenkins`
4. **Jenkins creates jobs** → Automatically sets up multibranch pipelines
5. **GitHub webhooks trigger** → Pushes to your repos trigger builds

## What Each Application Needs

Each application repository needs:

1. **Dockerfile** - How to build the application
2. **Jenkinsfile** - The pipeline definition

### Example Jenkinsfile

```groovy
pipeline {
    agent any
    
    stages {
        stage('Build') {
            steps {
                sh 'docker build -t myapp:${BUILD_NUMBER} .'
            }
        }
        stage('Test') {
            steps {
                sh 'docker run --rm myapp:${BUILD_NUMBER} npm test'
            }
        }
        stage('Push') {
            steps {
                // Optional: push to registry
                sh 'docker tag myapp:${BUILD_NUMBER} myapp:latest'
            }
        }
    }
}
```

## Benefits

✅ Automatic job creation  
✅ No manual Jenkins UI configuration  
✅ Infrastructure as code  
✅ Easy to add/remove applications  
✅ Reproducible setup  
✅ Version controlled pipelines  

## Troubleshooting

**Jobs not appearing after restart?**
- Check Jenkins logs: `docker-compose logs jenkins`
- Verify GitHub credentials are set
- Run: `docker-compose exec jenkins cat /var/jenkins_home/casc_configs/jenkins_casc.yml`

**GitHub webhooks not triggering builds?**
- Ensure `github-credentials` are correctly configured
- Check webhook delivery in GitHub repo settings
- Look at Jenkins logs for webhook errors
