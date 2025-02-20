#!/bin/bash

# Check if Docker is installed
if ! command -v docker &> /dev/null
then
    echo "Docker not found, please install Docker Desktop for Mac"
    exit 1
fi

# Create project directory
# echo "Creating project directory 'platform_pipeline'..."
# mkdir -p platform_pipeline
# cd platform_pipeline

# Create docker-compose.yml
echo "Creating docker-compose.yml file..."
cat <<EOF > docker-compose.yml
version: '3.7'

services:
  # Jenkins for CI/CD
  jenkins:
    image: jenkins/jenkins
    container_name: jenkins
    ports:
      - "8080:8080"
      - "50000:50000"
    volumes:
      - jenkins_home:/var/jenkins_home
    environment:
      - JAVA_OPTS=-Djenkins.install.runSetupWizard=false

  # Prometheus for monitoring
  prometheus:
    image: prom/prometheus
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    restart: always

  # Grafana for visualization
  grafana:
    image: grafana/grafana
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      GF_SECURITY_ADMIN_PASSWORD: "admin" # Change the password in production!
    restart: always
    depends_on:
      - prometheus

  # Vault for secrets management
  vault:
    image: vault:1.13.3
    container_name: vault
    ports:
      - "8200:8200"
    environment:
      VAULT_DEV_ROOT_TOKEN_ID: "root"
    command: "server -dev"
    restart: always

  # Sample Node.js app containerized
  app:
    build: ./app
    container_name: sample_app
    ports:
      - "30001:3000"
    environment:
      - NODE_ENV=development
    depends_on:
      - jenkins

volumes:
  jenkins_home:
    driver: local
EOF

# Create a simple Node.js app directory and files
echo "Creating Node.js app in './app' directory..."
mkdir -p app
cd app

# Create Dockerfile
cat <<EOF > Dockerfile
# Use official Node.js image as base image
FROM node:14

# Set the working directory
WORKDIR /app

# Copy package.json and install dependencies
COPY package.json /app
RUN npm install

# Copy the rest of the application files
COPY . /app

# Expose the port the app will run on
EXPOSE 3000

# Run the app
CMD ["npm", "start"]
EOF

# Create package.json for the Node.js app
cat <<EOF > package.json
{
  "name": "sample-app",
  "version": "1.0.0",
  "description": "Sample Node.js app for platform pipeline",
  "main": "app.js",
  "scripts": {
    "start": "node app.js"
  },
  "dependencies": {
    "express": "^4.17.1"
  }
}
EOF

# Create a simple app.js file
cat <<EOF > app.js
const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.send('Hello, Platform Engineering Pipeline!');
});

app.listen(port, () => {
  console.log(\`Sample app listening at http://localhost:\${port}\`);
});
EOF

cd ..

# Create Prometheus configuration file
echo "Creating Prometheus configuration (prometheus.yml)..."
cat <<EOF > prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'docker'
    static_configs:
      - targets: ['sample_app:3000']
EOF

# Start Docker Compose
echo "Starting Docker Compose..."
docker-compose up -d

echo "Platform Engineering Pipeline setup complete!"

# Instructions
echo ""
echo "Access the following services:"
echo "1. Jenkins: http://localhost:8080"
echo "2. Prometheus: http://localhost:9090"
echo "3. Grafana: http://localhost:3000 (admin/admin)"
echo "4. Vault: http://localhost:8200"
echo "5. Sample App: http://localhost:3000"
echo ""
echo "Use 'docker-compose down' to stop and remove the containers."