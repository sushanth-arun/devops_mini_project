pipeline {
    agent any

    environment {
        APP_NAME     = 'clinic-app'
        IMAGE_NAME   = 'clinic-management'
        IMAGE_TAG    = 'latest'
        PORT         = '8080'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
    }

    stages {
        stage('Checkout SCM') {
            steps {
                echo '======================================================'
                echo ' STAGE 1: Source Code Management - Checkout SCM       '
                echo '======================================================'
                checkout scm
            }
        }

        stage('Maven Build & Regression Tests') {
            steps {
                echo '======================================================'
                echo ' STAGE 2: Maven Build & Regression Tests (JUnit 5)    '
                echo '======================================================'
                script {
                    if (isUnix()) {
                        sh 'chmod +x mvnw'
                        sh './mvnw clean test'
                    } else {
                        bat 'mvnw.cmd clean test'
                    }
                }
            }
            post {
                always {
                    junit testResults: '**/target/surefire-reports/*.xml', allowEmptyResults: true
                }
            }
        }

        stage('Artifact Packaging') {
            steps {
                echo '======================================================'
                echo ' STAGE 3: Artifact Packaging (Executable Spring Boot) '
                echo '======================================================'
                script {
                    if (isUnix()) {
                        sh './mvnw package -DskipTests'
                    } else {
                        bat 'mvnw.cmd package -DskipTests'
                    }
                }
            }
            post {
                success {
                    archiveArtifacts artifacts: 'target/*.jar', fingerprint: true, allowEmptyArchive: true
                }
            }
        }

        stage('Docker Image Build') {
            steps {
                echo '======================================================'
                echo ' STAGE 4: Docker Multi-Stage Image Build & Tagging    '
                echo '======================================================'
                script {
                    if (isUnix()) {
                        sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
                    } else {
                        bat "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
                    }
                }
            }
        }

        stage('DevSecOps Security Audit (Trivy)') {
            steps {
                echo '======================================================'
                echo ' STAGE 5: DevSecOps Vulnerability Scan with Trivy     '
                echo '======================================================'
                script {
                    // Audit container image for HIGH and CRITICAL vulnerabilities without breaking build (warn/audit mode)
                    if (isUnix()) {
                        sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --severity HIGH,CRITICAL --exit-code 0 --no-progress ${IMAGE_NAME}:${IMAGE_TAG} || true"
                    } else {
                        bat "docker run --rm -v //var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --severity HIGH,CRITICAL --exit-code 0 --no-progress ${IMAGE_NAME}:${IMAGE_TAG} || exit /b 0"
                    }
                }
            }
        }

        stage('Ansible Automated Deployment') {
            steps {
                echo '======================================================'
                echo ' STAGE 6: Ansible Automated Deployment & Healthcheck  '
                echo '======================================================'
                script {
                    if (isUnix()) {
                        sh 'ansible-playbook -i inventory.ini deploy.yml'
                    } else {
                        bat 'wsl -d Ubuntu ansible-playbook -i inventory.ini deploy.yml || powershell -ExecutionPolicy Bypass -File .\\demo_run.ps1 -DeployOnly'
                    }
                }
            }
        }
    }

    post {
        success {
            echo "=========================================================="
            echo " [DEPLOYMENT SUCCESSFUL]"
            echo " Application : Healthcare Clinic Management System"
            echo " Endpoint    : http://localhost:${PORT}"
            echo " Container   : ${APP_NAME}"
            echo " Image       : ${IMAGE_NAME}:${IMAGE_TAG}"
            echo "=========================================================="
        }
        failure {
            echo "=========================================================="
            echo " [PIPELINE FAILED]"
            echo " Check console log output for debugging."
            echo "=========================================================="
        }
    }
}
