# Automated CI/CD Pipeline and Configuration Management for a Healthcare Clinic Management System

[![CI/CD Pipeline](https://github.com/sushanth-arun/devops_mini_project/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/sushanth-arun/devops_mini_project/actions/workflows/ci-cd.yml)
[![Docker Image](https://img.shields.io/badge/docker-multi--stage%20(187MB)-blue.svg?logo=docker)](https://hub.docker.com/)
[![Ansible](https://img.shields.io/badge/ansible-idempotent%20deploy-red.svg?logo=ansible)](https://ansible.com/)
[![DevSecOps](https://img.shields.io/badge/security-trivy%20scanned-brightgreen.svg?logo=aquasec)](https://trivy.dev/)
[![Java](https://img.shields.io/badge/java-17%20(Eclipse%20Temurin)-orange.svg?logo=openjdk)](https://adoptium.net/)
[![Spring Boot](https://img.shields.io/badge/spring%20boot-4.1.0-green.svg?logo=springboot)](https://spring.io/projects/spring-boot)
[![Institution](https://img.shields.io/badge/PSG%20iTech-Anna%20Univ%205th%20Sem-darkblue.svg)](https://www.psgitech.ac.in/)

---

## 🏥 Project Overview

In clinical and healthcare settings, software updates must never cause unexpected service downtime. This mini-project implements a robust, enterprise-grade **Automated CI/CD Pipeline, DevSecOps Security Audit, and Configuration Management Framework** for a Spring Boot **Healthcare Clinic Management System** (Spring PetClinic).

The system automates the complete lifecycle:
1. **Continuous Integration (CI):** Automated checkout, Maven compilation, and JUnit 5 regression testing.
2. **Containerization (Docker):** Highly optimized multi-stage build creating an ultra-lean 187 MB Alpine runtime with non-root security hardening.
3. **DevSecOps (Trivy):** Container vulnerability scanning auditing for HIGH and CRITICAL CVEs without breaking build velocity.
4. **Configuration Management & Continuous Deployment (CD):** Idempotent container lifecycle provisioning via Ansible (`inventory.ini` and `deploy.yml`) with automated HTTP health check verification.
5. **Dual CI/CD Orchestration:** Local automation via Jenkins Declarative Pipeline (`Jenkinsfile`) and cloud mirror via GitHub Actions (`.github/workflows/ci-cd.yml`).

---

## 📐 Architecture & Pipeline Flow

```mermaid
flowchart TD
    subgraph SCM["1. Source Control Management"]
        GitCommit["Developer Commit & Push"] --> GitHub["GitHub Repository\n(sushanth-arun/devops_mini_project)"]
    end

    subgraph CI["2. Continuous Integration & Quality Gates"]
        GitHub -->|Webhook / Polling| Jenkins["Jenkins CI / GitHub Actions"]
        Jenkins --> StepCheckout["Stage 1: Checkout SCM"]
        StepCheckout --> StepTest["Stage 2: Maven Build & Regression Tests\n(JUnit 5, 81 Tests)"]
        StepTest --> StepPackage["Stage 3: Artifact Packaging\n(spring-petclinic.jar)"]
    end

    subgraph DockerBuild["3. Multi-Stage Dockerization"]
        StepPackage --> StepDocker["Stage 4: Docker Multi-Stage Build"]
        subgraph InternalBuild["Dockerfile Stages"]
            B1["Stage 1: Builder\neclipse-temurin:17-jdk\nMaven Wrapper Cache"] --> B2["Stage 2: Runtime\neclipse-temurin:17-jre-alpine\nNon-Root appuser (187 MB)"]
        end
        StepDocker -.-> InternalBuild
    end

    subgraph DevSecOps["4. Security Gate"]
        InternalBuild --> StepTrivy["Stage 5: DevSecOps Vulnerability Scan\n(Trivy: High & Critical Audit)"]
    end

    subgraph CD["5. Configuration Management & Deployment"]
        StepTrivy --> StepAnsible["Stage 6: Ansible Automated Deployment"]
        subgraph AnsiblePlaybook["Ansible Engine (inventory.ini)"]
            Task1["1. Idempotent Container Cleanup\n(docker rm -f clinic-app)"] --> Task2["2. Run Fresh Container\n(Port 8080:8080)"]
            Task2 --> Task3["3. HTTP Health Check Probe\n(ansible.builtin.uri)"]
        end
        StepAnsible -.-> AnsiblePlaybook
    end

    subgraph Target["6. Live Production Environment"]
        AnsiblePlaybook --> Container[("Running Docker Container\n'clinic-app'\nhttp://localhost:8080")]
        Client["Doctors / Patients / Reviewers\nWeb Browser / REST API"] -->|HTTP GET| Container
    end
```

---

## 🧰 Technology Stack

| Layer | Technology | Version | Purpose in Project |
|---|---|---|---|
| **Application** | Spring Boot / Java | 4.1.0 / 17 (Temurin) | Core Healthcare Clinic Microservice (Owners, Vets, Pets, Visits) |
| **Build Automation** | Apache Maven Wrapper | 3.9.x (`mvnw`) | Dependency resolution, compilation, packaging, reproducible builds |
| **Testing** | JUnit 5 & Spring Test | Latest | Automated regression unit tests (81 test cases) |
| **CI Automation (Local)** | Jenkins Declarative Pipeline | 2.580.x | Pipeline as Code (`Jenkinsfile`) with cross-platform `isUnix()` |
| **CI Automation (Cloud)** | GitHub Actions | Workflows v4/v5 | Cloud CI mirror on push/PR (`.github/workflows/ci-cd.yml`) |
| **Containerization** | Docker Multi-Stage | 29.x | Stage 1 (JDK 17) + Stage 2 (Alpine JRE 17), 187 MB footprint |
| **DevSecOps** | Aqua Security Trivy | Latest | Vulnerability audit for HIGH/CRITICAL CVEs |
| **Configuration Mgmt** | Ansible Core | 2.20.x | Idempotent container lifecycle provisioning (`deploy.yml`) |
| **Host OS** | Windows 11 + WSL2 Ubuntu | Linux 6.x | Hybrid cross-platform deployment architecture |

---

## 📋 Repository Structure

```
├── .github/
│   └── workflows/
│       └── ci-cd.yml          # GitHub Actions Cloud CI/CD workflow
├── .mvn/                      # Maven Wrapper binary & configuration
├── src/                       # Healthcare Clinic Application Source Code
├── Dockerfile                 # Optimized multi-stage Docker build file
├── .dockerignore              # Docker build context exclusion rules
├── Jenkinsfile                # 6-Stage Declarative Pipeline as Code
├── inventory.ini              # Ansible inventory pointing to deployment targets
├── deploy.yml                 # Ansible idempotent deployment & healthcheck playbook
├── demo_run.ps1               # One-click PowerShell automated verification script
├── REVIEW_GUIDE.md            # Detailed PSG iTech / Anna University review guide
├── pom.xml                    # Maven Project Object Model & dependencies
└── README.md                  # Project portfolio documentation (this file)
```

---

## ⚡ Quickstart & Live Demo

### Option 1: One-Click Demo Runner (Recommended for Review)
Run the automated PowerShell verification script:

```powershell
# Executes: Pre-flight check -> Docker Build -> Trivy Scan -> Ansible Deploy -> Health Check -> Auto-Launch Browser
.\demo_run.ps1
```

#### Handy Demo Flags:
```powershell
# Fast redeploy (skips build, executes Ansible deployment immediately)
.\demo_run.ps1 -DeployOnly

# Fast build (skips Trivy scan for faster rerun)
.\demo_run.ps1 -SkipScan

# Clean teardown of clinic-app container
.\demo_run.ps1 -Stop
```

---

### Option 2: Step-by-Step Manual Execution

#### 1. Run Maven Regression Tests:
```bash
./mvnw clean test
```

#### 2. Build Multi-Stage Docker Image:
```bash
docker build -t clinic-management:latest .
```

#### 3. Run DevSecOps Vulnerability Scan:
```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image \
  --severity HIGH,CRITICAL \
  --exit-code 0 \
  clinic-management:latest
```

#### 4. Deploy with Ansible:
```bash
ansible-playbook -i inventory.ini deploy.yml
```

---

## 🌐 Live Service Endpoints

Once deployed, the healthcare management system is active at:

| Endpoint | Method | Expected HTTP Status | Description |
|---|---|---|---|
| `http://localhost:8080/` | `GET` | `200 OK` | Healthcare Clinic Web Portal UI |
| `http://localhost:8080/owners` | `GET` | `200 OK` | Patient / Pet Owner Management |
| `http://localhost:8080/vets.html` | `GET` | `200 OK` | Doctor / Veterinarian Directory |
| `http://localhost:8080/actuator/health` | `GET` | `200 OK` | Spring Boot Actuator Health Probe |
| `http://localhost:8081/` | `GET` | `200/403` | Local Jenkins CI/CD Dashboard |

---

## 🔒 DevSecOps & Security Hardening Features

1. **Non-Root Container User:** Application executes under unprivileged system user `appuser:appgroup`, mitigating container breakout vulnerabilities.
2. **Minimal Attack Surface:** Built upon `eclipse-temurin:17-jre-alpine`, omitting shell package managers and compilers in production.
3. **Automated Trivy Scanning:** Continuous vulnerability auditing in both Jenkins (`Jenkinsfile`) and GitHub Actions (`ci-cd.yml`).
4. **Deterministic Layer Caching:** Dependencies and Maven Wrapper are cached in early layers, guaranteeing rapid and reproducible builds.
5. **Graceful Signal Handling:** Uses `exec java $JAVA_OPTS -jar app.jar` in `ENTRYPOINT` to ensure `SIGTERM` signals reach the JVM for clean database connection drain.

---

## 🎓 Academic Review Information

- **Institution:** PSG Institute of Technology and Applied Research (PSG iTech), Neelambur, Coimbatore
- **Affiliated To:** Anna University, Chennai
- **Department:** Computer Science and Engineering / Information Technology
- **Course:** 5th Semester — DevOps Laboratory Mini-Project
- **Repository:** [https://github.com/sushanth-arun/devops_mini_project](https://github.com/sushanth-arun/devops_mini_project)
- **Detailed Viva Q&A Guide:** Refer to [`REVIEW_GUIDE.md`](./REVIEW_GUIDE.md) for top 5 viva questions and answers.
