#!/bin/bash
# ==============================================================================
# All-In-One DevOps Demo Script for Healthcare Clinic Management System
# Executes: Java 17 Setup -> Maven Package -> Docker Build -> Ansible Deploy
# ==============================================================================

set -e

echo -e "\n\033[1;36m====================================================================\033[0m"
echo -e "\033[1;33m  🚀 EXECUTING COMPLETE END-TO-END DEVOPS CI/CD PIPELINE           \033[0m"
echo -e "\033[1;36m====================================================================\033[0m"

# 1. Environment Setup
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

echo -e "\n\033[1;32m[1/3] Building & Packaging Spring Boot Application (Maven CI)...\033[0m"
./mvnw package -DskipTests

echo -e "\n\033[1;32m[2/3] Building Multi-Stage Minimal Docker Image (187 MB Alpine)...\033[0m"
docker build -t clinic-management:latest .

echo -e "\n\033[1;32m[3/3] Deploying Idempotently via Ansible Playbook (CD Stage)...\033[0m"
ansible-playbook -i inventory.ini deploy.yml

echo -e "\n\033[1;32m====================================================================\033[0m"
echo -e "\033[1;32m  🎉 DEMO PIPELINE COMPLETE! APPLICATION IS LIVE & HEALTHY!         \033[0m"
echo -e "\033[1;37m  👉 Open in Chrome: http://localhost:8080                         \033[0m"
echo -e "\033[1;32m====================================================================\033[0m\n"

