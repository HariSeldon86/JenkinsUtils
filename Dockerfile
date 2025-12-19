FROM jenkins/jenkins:lts

USER root

ARG DOCKER_GID=999


# Install Docker CLI and Compose Plugin
RUN apt-get update && \
    apt-get install -y ca-certificates curl gnupg && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli docker-compose-plugin && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Give Jenkins user access to Docker socket
# Match the GID to your HOST's docker group (usually 999 or 998, check 'getent group docker')
# If the group already exists in the image, we just add jenkins to it
RUN if getent group docker; then \
        usermod -aG docker jenkins; \
    else \
        groupadd -g ${DOCKER_GID} docker && usermod -aG docker jenkins; \
    fi

USER jenkins

# Install common Jenkins plugins

# RUN jenkins-plugin-cli --verbose --plugins "blueocean docker-workflow docker-plugin configuration-as-code job-dsl github-branch-source timestamper pipeline-stage-view ws-cleanup credentials credentials-binding pipeline-utility-steps pipeline-groovy-lib git"

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --verbose --plugin-file /usr/share/jenkins/ref/plugins.txt

# Disable Jenkins setup wizard
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false -Djenkins.model.Jenkins.installStateName=RUNNING"

# Enable JCasC
ENV CASC_JENKINS_CONFIG=/var/jenkins_home/casc_configs/jenkins_casc.yml