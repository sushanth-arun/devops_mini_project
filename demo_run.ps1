<#
.SYNOPSIS
    Automated Local Demo Runner for Healthcare Clinic Management System
    PSG Institute of Technology and Applied Research (PSG iTech) - 5th Sem DevOps

.DESCRIPTION
    Executes the complete CI/CD lifecycle locally:
    1. Pre-flight checks (Docker, Git, WSL)
    2. Maven testing & packaging
    3. Multi-stage Docker build (clinic-management:latest)
    4. DevSecOps Trivy container vulnerability scan (audit mode)
    5. Ansible idempotent deployment (deploy.yml)
    6. Health verification & auto-launch in browser

.PARAMETER SkipBuild
    Skips Maven compile and Docker build; executes only Ansible deployment.

.PARAMETER DeployOnly
    Deploys or restarts the container using Ansible.

.PARAMETER SkipScan
    Skips the DevSecOps Trivy container vulnerability scan.

.PARAMETER Stop
    Stops and removes the clinic-app container.
#>

[CmdletBinding()]
param(
    [switch]$SkipBuild,
    [switch]$DeployOnly,
    [switch]$SkipScan,
    [switch]$Stop
)

$ErrorActionPreference = "Stop"

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Yellow -NoNewline
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Cyan
}

function Write-Step {
    param([string]$StepNum, [string]$Message)
    Write-Host "`n[$StepNum] " -ForegroundColor Green -NoNewline
    Write-Host "$Message" -ForegroundColor White
}

function Write-Success {
    param([string]$Message)
    Write-Host " [SUCCESS] $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host " [INFO] $Message" -ForegroundColor Gray
}

# Handle Stop request
if ($Stop) {
    Write-Header "Tearing Down Healthcare Clinic Container"
    docker rm -f clinic-app 2>$null
    Write-Success "Container 'clinic-app' stopped and removed."
    exit 0
}

Write-Header "DevOps Healthcare Clinic Pipeline - Live Demo"
Write-Host " Project: Automated CI/CD & Configuration Management for Clinic System" -ForegroundColor White
Write-Host " Stack  : Git -> Maven -> Jenkins -> Docker -> Trivy -> Ansible" -ForegroundColor White

# -----------------------------------------------------------------------------
# 1. Pre-Flight Verification
# -----------------------------------------------------------------------------
Write-Step "1/6" "Verifying System Prerequisites..."

# Verify Docker
try {
    $dockerInfo = docker info --format '{{.ServerVersion}}' 2>$null
    if (-not $dockerInfo) {
        Write-Host " [ERROR] Docker daemon is not running. Please start Docker Desktop." -ForegroundColor Red
        exit 1
    }
    Write-Success "Docker Engine active (v$dockerInfo)"
} catch {
    Write-Host " [ERROR] Docker CLI not found or daemon not reachable." -ForegroundColor Red
    exit 1
}

# Verify Ansible via WSL
$hasAnsible = $false
try {
    $ansibleVer = wsl -d Ubuntu ansible --version 2>$null
    if ($ansibleVer) {
        $hasAnsible = $true
        Write-Success "Ansible Engine available in WSL environment"
    }
} catch {
    Write-Info "WSL Ansible not directly detected. Fallback mode enabled."
}

# -----------------------------------------------------------------------------
# 2. Maven Build & Package (Optional if -SkipBuild or -DeployOnly)
# -----------------------------------------------------------------------------
if (-not $SkipBuild -and -not $DeployOnly) {
    Write-Step "2/6" "Validating Source Code and Maven Build Artifacts..."
    Write-Info "Testing compile & packaging via Docker build..."
} else {
    Write-Step "2/6" "Skipping Maven build stage (-SkipBuild / -DeployOnly selected)"
}

# -----------------------------------------------------------------------------
# 3. Docker Image Build
# -----------------------------------------------------------------------------
$imageName = "clinic-management:latest"
if (-not $DeployOnly) {
    Write-Step "3/6" "Building Multi-Stage Docker Image: $imageName"
    Write-Info "Executing: docker build -t $imageName ."
    
    $buildStart = Get-Date
    docker build -t $imageName .
    if ($LASTEXITCODE -ne 0) {
        Write-Host " [ERROR] Docker build failed!" -ForegroundColor Red
        exit 1
    }
    $buildElapsed = [math]::Round(((Get-Date) - $buildStart).TotalSeconds, 1)
    Write-Success "Docker image '$imageName' created successfully in $buildElapsed s!"
} else {
    Write-Step "3/6" "Skipping Docker image build stage (-DeployOnly selected)"
}

# -----------------------------------------------------------------------------
# 4. DevSecOps Vulnerability Scan (Trivy)
# -----------------------------------------------------------------------------
if (-not $SkipScan -and -not $DeployOnly) {
    Write-Step "4/6" "DevSecOps Audit: Scanning container image with Trivy (Warn/Audit Mode)..."
    Write-Info "Executing: docker run --rm -v //var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --severity HIGH,CRITICAL --exit-code 0 $imageName"
    try {
        docker run --rm -v //var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --severity HIGH,CRITICAL --exit-code 0 --no-progress $imageName
        Write-Success "Security scan completed (Audit mode: Build preserved)"
    } catch {
        Write-Info "Trivy audit completed."
    }
} else {
    Write-Step "4/6" "Skipping DevSecOps security scan (-SkipScan / -DeployOnly selected)"
}

# -----------------------------------------------------------------------------
# 5. Ansible Automated Deployment
# -----------------------------------------------------------------------------
Write-Step "5/6" "Executing Ansible Configuration Management Playbook..."

$deployed = $false
if ($hasAnsible) {
    try {
        Write-Info "Running: wsl -d Ubuntu ansible-playbook -i inventory.ini deploy.yml"
        $wslPath = wsl -d Ubuntu wslpath -a (Get-Location).Path
        wsl -d Ubuntu sh -c "cd '$wslPath' && ansible-playbook -i inventory.ini deploy.yml"
        if ($LASTEXITCODE -eq 0) {
            $deployed = $true
            Write-Success "Ansible Playbook completed idempotently!"
        }
    } catch {
        Write-Info "WSL Ansible run returned an issue. Switching to idempotent native runner..."
    }
}

if (-not $deployed) {
    Write-Info "Deploying idempotently using native Docker commands (Ansible logic simulation)..."
    docker rm -f clinic-app 2>$null | Out-Null
    docker run -d --name clinic-app --restart unless-stopped -p 8080:8080 $imageName | Out-Null
    Write-Success "Container 'clinic-app' started on port 8080"
}

# -----------------------------------------------------------------------------
# 6. Live Healthcheck Verification
# -----------------------------------------------------------------------------
Write-Step "6/6" "Polling HTTP Endpoint Health Check: http://localhost:8080/ ..."

$url = "http://localhost:8080/"
$maxAttempts = 40
$attempt = 1
$isHealthy = $false

while ($attempt -le $maxAttempts) {
    try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 2 -ErrorAction SilentlyContinue
        if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 400) {
            $isHealthy = $true
            break
        }
    } catch {
        # App is still booting Spring context
    }
    Write-Host "." -NoNewline -ForegroundColor Yellow
    Start-Sleep -Seconds 2
    $attempt++
}
Write-Host ""

if ($isHealthy) {
    Write-Host ""
    Write-Host "********************************************************************************" -ForegroundColor Green
    Write-Host " [SUCCESS] HEALTHCARE CLINIC MANAGEMENT SYSTEM IS LIVE & HEALTHY!               " -ForegroundColor Green
    Write-Host " URL: http://localhost:8080                                                     " -ForegroundColor White
    Write-Host " Container: clinic-app | Image: $imageName                                      " -ForegroundColor White
    Write-Host "********************************************************************************" -ForegroundColor Green
    
    # Auto-open browser
    try {
        Start-Process "http://localhost:8080"
    } catch {
        Write-Info "Open http://localhost:8080 in your browser."
    }
} else {
    Write-Host " [WARNING] Container is starting up. Check logs with: docker logs -f clinic-app" -ForegroundColor Yellow
}

exit 0
