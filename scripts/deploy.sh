#!/bin/bash

# VoltEdge Production Deployment Script
# This script handles deployment to various environments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to validate environment
validate_environment() {
    local env=$1
    
    case $env in
        "development"|"staging"|"production")
            return 0
            ;;
        *)
            print_error "Invalid environment: $env"
            print_status "Valid environments: development, staging, production"
            exit 1
            ;;
    esac
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking deployment prerequisites..."
    
    local missing_deps=()
    
    if ! command_exists docker; then
        missing_deps+=("docker")
    fi
    
    if ! command_exists docker-compose; then
        missing_deps+=("docker-compose")
    fi
    
    if ! command_exists git; then
        missing_deps+=("git")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        exit 1
    fi
    
    print_success "All prerequisites are available"
}

# Function to build images
build_images() {
    local env=$1
    
    print_status "Building Docker images for $env environment..."
    
    # Build all images
    docker-compose -f docker-compose.yml build --no-cache
    
    if [ "$env" = "production" ]; then
        docker-compose -f docker-compose.prod.yml build --no-cache
    fi
    
    print_success "Docker images built successfully"
}

# Function to run tests
run_tests() {
    print_status "Running comprehensive test suite..."
    
    # Frontend tests
    print_status "Running frontend tests..."
    cd svelte-frontend
    npm ci
    npm run test:coverage
    cd ..
    
    # Backend tests
    print_status "Running backend tests..."
    cd go-services
    go test -v -race -coverprofile=coverage.out ./...
    cd ..
    
    # Zig tests
    print_status "Running Zig tests..."
    cd zig-core
    zig build test
    cd ..
    
    print_success "All tests passed"
}

# Function to deploy to development
deploy_development() {
    print_status "Deploying to development environment..."
    
    # Stop existing containers
    docker-compose down -v
    
    # Start development environment
    docker-compose up -d
    
    print_success "Development environment deployed"
    print_status "Services available at:"
    print_status "  - Frontend: http://localhost:5173"
    print_status "  - API Gateway: http://localhost:8080"
    print_status "  - Metrics: http://localhost:9090"
}

# Function to deploy to staging
deploy_staging() {
    print_status "Deploying to staging environment..."
    
    # Use production compose file for staging
    docker-compose -f docker-compose.prod.yml up -d
    
    print_success "Staging environment deployed"
    print_status "Services available at:"
    print_status "  - Frontend: http://localhost"
    print_status "  - API Gateway: http://localhost:8080"
    print_status "  - Metrics: http://localhost:9090"
}

# Function to deploy to production
deploy_production() {
    print_status "Deploying to production environment..."
    
    # Check for required environment variables
    if [ -z "$DB_PASSWORD" ]; then
        print_error "DB_PASSWORD environment variable is required for production"
        exit 1
    fi
    
    if [ -z "$JWT_SECRET" ]; then
        print_error "JWT_SECRET environment variable is required for production"
        exit 1
    fi
    
    # Deploy with production configuration
    docker-compose -f docker-compose.prod.yml up -d
    
    print_success "Production environment deployed"
    print_status "Services available at:"
    print_status "  - Frontend: http://localhost"
    print_status "  - API Gateway: http://localhost:8080"
    print_status "  - Metrics: http://localhost:9090"
    print_status "  - Prometheus: http://localhost:9092"
    print_status "  - Grafana: http://localhost:3000"
}

# Function to deploy to GitHub Pages
deploy_github_pages() {
    print_status "Deploying to GitHub Pages..."
    
    # Build frontend for production
    cd svelte-frontend
    npm ci
    npm run build
    
    # Create deployment directory
    mkdir -p ../deploy
    cp -r build/* ../deploy/
    
    cd ..
    
    # Initialize git in deploy directory
    cd deploy
    git init
    git add .
    git commit -m "Deploy VoltEdge to GitHub Pages"
    
    # Add GitHub Pages remote
    git remote add origin https://github.com/$GITHUB_REPOSITORY.git
    git branch -M gh-pages
    git push -f origin gh-pages
    
    cd ..
    rm -rf deploy
    
    print_success "Deployed to GitHub Pages"
    print_status "Application available at: https://$GITHUB_REPOSITORY_OWNER.github.io/$GITHUB_REPOSITORY_NAME"
}

# Function to rollback deployment
rollback() {
    local env=$1
    
    print_status "Rolling back $env deployment..."
    
    if [ "$env" = "production" ]; then
        docker-compose -f docker-compose.prod.yml down
    else
        docker-compose down
    fi
    
    print_success "Rollback completed"
}

# Function to show deployment status
show_status() {
    print_status "Deployment status:"
    
    if [ -f "docker-compose.prod.yml" ]; then
        docker-compose -f docker-compose.prod.yml ps
    else
        docker-compose ps
    fi
}

# Function to show logs
show_logs() {
    local service=$1
    
    if [ -n "$service" ]; then
        docker-compose logs -f "$service"
    else
        docker-compose logs -f
    fi
}

# Function to cleanup
cleanup() {
    print_status "Cleaning up deployment artifacts..."
    
    # Stop all containers
    docker-compose down -v
    docker-compose -f docker-compose.prod.yml down -v
    
    # Remove unused images
    docker image prune -f
    
    # Remove unused volumes
    docker volume prune -f
    
    print_success "Cleanup completed"
}

# Main function
main() {
    echo "=========================================="
    echo "    VoltEdge Deployment Script           "
    echo "=========================================="
    echo
    
    local command=${1:-help}
    local environment=${2:-development}
    
    case $command in
        "deploy")
            validate_environment "$environment"
            check_prerequisites
            run_tests
            build_images "$environment"
            
            case $environment in
                "development")
                    deploy_development
                    ;;
                "staging")
                    deploy_staging
                    ;;
                "production")
                    deploy_production
                    ;;
            esac
            ;;
        "github-pages")
            check_prerequisites
            run_tests
            deploy_github_pages
            ;;
        "rollback")
            validate_environment "$environment"
            rollback "$environment"
            ;;
        "status")
            show_status
            ;;
        "logs")
            show_logs "$2"
            ;;
        "cleanup")
            cleanup
            ;;
        "help")
            echo "Usage: $0 [command] [environment]"
            echo
            echo "Commands:"
            echo "  deploy [env]     - Deploy to specified environment (development|staging|production)"
            echo "  github-pages     - Deploy to GitHub Pages"
            echo "  rollback [env]   - Rollback deployment"
            echo "  status           - Show deployment status"
            echo "  logs [service]   - Show logs for service or all services"
            echo "  cleanup          - Clean up deployment artifacts"
            echo "  help             - Show this help message"
            echo
            echo "Examples:"
            echo "  $0 deploy development"
            echo "  $0 deploy production"
            echo "  $0 github-pages"
            echo "  $0 rollback production"
            echo "  $0 logs api-gateway"
            ;;
        *)
            print_error "Unknown command: $command"
            echo "Use '$0 help' to see available commands"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"