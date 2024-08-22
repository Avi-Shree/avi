#!/bin/bash
set -e

# Update package list and install dependencies
apt-get update -y
apt-get install -y docker.io curl

# Start and enable Docker service
systemctl start docker
systemctl enable docker

# Install Docker Compose
DOCKER_COMPOSE_VERSION="${DOCKER_COMPOSE_VERSION}"
DOCKER_COMPOSE_URL="https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)"
curl -L "$DOCKER_COMPOSE_URL" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Verify Docker Compose installation
if ! [ -x "$(command -v docker-compose)" ]; then
  echo "Docker Compose installation failed." | tee -a /home/ubuntu/setup.log
  exit 1
fi

# Create Docker Compose configuration for SonarQube
cat <<EOF > /home/ubuntu/docker-compose.yml
version: '3'
services:
  sonarqube:
    image: sonarqube:latest
    container_name: sonarqube
    ports:
      - "9000:9000"
    volumes:
      - sonarqube_conf:/opt/sonarqube/conf
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_logs:/opt/sonarqube/logs
    networks:
      - sonarnet

volumes:
  sonarqube_conf:
  sonarqube_data:
  sonarqube_logs:

networks:
  sonarnet:
EOF

# Change to the user's home directory and start SonarQube
cd /home/ubuntu
docker-compose up -d

# Check if SonarQube is running
docker ps | tee -a /home/ubuntu/setup.log