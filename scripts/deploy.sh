#!/bin/bash

# VoltEdge Production Deployment Script
set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENVIRONMENT="${1:-staging}"
REGISTRY="${REGISTRY:-ghcr.io}"
IMAGE_NAME="${IMAGE_NAME:-voltedge}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed"
        exit 1
    fi
    
    if ! command -v curl &> /dev/null; then
        log_error "curl is not installed"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Load environment configuration
load_environment() {
    log_info "Loading environment configuration for $ENVIRONMENT..."
    
    ENV_FILE="$PROJECT_ROOT/.env.$ENVIRONMENT"
    if [[ -f "$ENV_FILE" ]]; then
        export $(grep -v '^#' "$ENV_FILE" | xargs)
        log_success "Loaded environment variables from $ENV_FILE"
    else
        log_warning "Environment file $ENV_FILE not found, using defaults"
    fi
    
    # Set default values
    export COCKROACH_PASSWORD="${COCKROACH_PASSWORD:-$(openssl rand -base64 32)}"
    export GRAFANA_PASSWORD="${GRAFANA_PASSWORD:-$(openssl rand -base64 16)}"
    export REGISTRY="$REGISTRY"
    export IMAGE_NAME="$IMAGE_NAME"
}

# Pull latest images
pull_images() {
    log_info "Pulling latest images..."
    
    # Create .env file for docker-compose
    cat > "$PROJECT_ROOT/.env" << EOF
REGISTRY=$REGISTRY
IMAGE_NAME=$IMAGE_NAME
COCKROACH_PASSWORD=$COCKROACH_PASSWORD
GRAFANA_PASSWORD=$GRAFANA_PASSWORD
EOF
    
    if [[ "$ENVIRONMENT" == "production" ]]; then
        docker-compose -f docker-compose.prod.yml pull
    else
        docker-compose pull
    fi
    
    log_success "Images pulled successfully"
}

# Run health checks
health_check() {
    log_info "Running health checks..."
    
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        log_info "Health check attempt $attempt/$max_attempts"
        
        # Check CockroachDB
        if curl -f http://localhost:8080 &> /dev/null; then
            log_success "CockroachDB is healthy"
        else
            log_warning "CockroachDB health check failed"
        fi
        
        # Check API Gateway
        if curl -f http://localhost:8080/health &> /dev/null; then
            log_success "API Gateway is healthy"
        else
            log_warning "API Gateway health check failed"
        fi
        
        # Check Frontend
        if curl -f http://localhost:3000 &> /dev/null; then
            log_success "Frontend is healthy"
        else
            log_warning "Frontend health check failed"
        fi
        
        # Check Prometheus
        if curl -f http://localhost:9090/-/healthy &> /dev/null; then
            log_success "Prometheus is healthy"
        else
            log_warning "Prometheus health check failed"
        fi
        
        # Check Grafana
        if curl -f http://localhost:3001/api/health &> /dev/null; then
            log_success "Grafana is healthy"
        else
            log_warning "Grafana health check failed"
        fi
        
        sleep 10
        ((attempt++))
    done
}

# Deploy the application
deploy() {
    log_info "Deploying VoltEdge to $ENVIRONMENT environment..."
    
    cd "$PROJECT_ROOT"
    
    # Stop existing containers
    log_info "Stopping existing containers..."
    if [[ "$ENVIRONMENT" == "production" ]]; then
        docker-compose -f docker-compose.prod.yml down
    else
        docker-compose down
    fi
    
    # Start services
    log_info "Starting services..."
    if [[ "$ENVIRONMENT" == "production" ]]; then
        docker-compose -f docker-compose.prod.yml up -d
    else
        docker-compose up -d
    fi
    
    log_success "Deployment completed"
}

# Run database migrations
run_migrations() {
    log_info "Running database migrations..."
    
    # Wait for database to be ready
    log_info "Waiting for database to be ready..."
    sleep 30
    
    # Run migrations through API
    if curl -f -X POST http://localhost:8080/api/v1/migrate &> /dev/null; then
        log_success "Database migrations completed"
    else
        log_warning "Database migrations may have failed"
    fi
}

# Show deployment status
show_status() {
    log_info "Deployment Status:"
    echo ""
    
    if [[ "$ENVIRONMENT" == "production" ]]; then
        docker-compose -f docker-compose.prod.yml ps
    else
        docker-compose ps
    fi
    
    echo ""
    log_info "Service URLs:"
    echo "  Frontend:    http://localhost:3000"
    echo "  API:         http://localhost:8080"
    echo "  CockroachDB: http://localhost:8080 (Admin UI)"
    echo "  Prometheus:  http://localhost:9090"
    echo "  Grafana:     http://localhost:3001"
    echo ""
    echo "Default credentials:"
    echo "  Grafana: admin / $GRAFANA_PASSWORD"
    echo "  CockroachDB: voltedge / $COCKROACH_PASSWORD"
}

# Cleanup function
cleanup() {
    log_info "Cleaning up..."
    rm -f "$PROJECT_ROOT/.env"
}

# Main deployment flow
main() {
    log_info "Starting VoltEdge deployment to $ENVIRONMENT environment"
    
    # Set up cleanup trap
    trap cleanup EXIT
    
    check_prerequisites
    load_environment
    pull_images
    deploy
    run_migrations
    
    log_info "Waiting for services to start..."
    sleep 60
    
    health_check
    show_status
    
    log_success "VoltEdge deployment to $ENVIRONMENT completed successfully!"
}

# Script usage
usage() {
    echo "Usage: $0 [environment]"
    echo ""
    echo "Environments:"
    echo "  staging     Deploy to staging (default)"
    echo "  production  Deploy to production"
    echo ""
    echo "Environment variables:"
    echo "  REGISTRY     Container registry (default: ghcr.io)"
    echo "  IMAGE_NAME   Image name prefix (default: voltedge)"
    echo ""
    echo "Examples:"
    echo "  $0 staging"
    echo "  REGISTRY=docker.io IMAGE_NAME=myorg/voltedge $0 production"
}

# Handle script arguments
if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

# Run main function
main

