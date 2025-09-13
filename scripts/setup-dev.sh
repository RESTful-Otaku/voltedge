#!/bin/bash

# VoltEdge Development Setup Script
# This script sets up the complete development environment for VoltEdge

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

# Function to check system requirements
check_requirements() {
    print_status "Checking system requirements..."
    
    local missing_deps=()
    
    # Check for required commands
    if ! command_exists node; then
        missing_deps+=("node")
    fi
    
    if ! command_exists npm; then
        missing_deps+=("npm")
    fi
    
    if ! command_exists go; then
        missing_deps+=("go")
    fi
    
    if ! command_exists zig; then
        missing_deps+=("zig")
    fi
    
    if ! command_exists docker; then
        missing_deps+=("docker")
    fi
    
    if ! command_exists docker-compose; then
        missing_deps+=("docker-compose")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        print_status "Please install the missing dependencies and run this script again."
        exit 1
    fi
    
    print_success "All required dependencies are installed"
}

# Function to setup frontend
setup_frontend() {
    print_status "Setting up Svelte frontend..."
    
    cd svelte-frontend
    
    # Install dependencies
    print_status "Installing frontend dependencies..."
    npm ci
    
    # Run linting
    print_status "Running frontend linting..."
    npm run lint
    
    # Run type checking
    print_status "Running frontend type checking..."
    npm run check
    
    # Run tests
    print_status "Running frontend tests..."
    npm test
    
    cd ..
    print_success "Frontend setup completed"
}

# Function to setup backend
setup_backend() {
    print_status "Setting up Go backend services..."
    
    cd go-services
    
    # Download dependencies
    print_status "Downloading Go dependencies..."
    go mod download
    
    # Run tests
    print_status "Running backend tests..."
    go test ./...
    
    # Build the application
    print_status "Building Go services..."
    go build -o bin/voltedge-api ./cmd/main.go
    
    cd ..
    print_success "Backend setup completed"
}

# Function to setup Zig core
setup_zig_core() {
    print_status "Setting up Zig core engine..."
    
    cd zig-core
    
    # Run tests
    print_status "Running Zig tests..."
    zig build test
    
    # Build the application
    print_status "Building Zig core..."
    zig build -Doptimize=ReleaseFast
    
    cd ..
    print_success "Zig core setup completed"
}

# Function to setup Docker environment
setup_docker() {
    print_status "Setting up Docker environment..."
    
    # Build Docker images
    print_status "Building Docker images..."
    docker-compose build
    
    print_success "Docker environment setup completed"
}

# Function to run all tests
run_tests() {
    print_status "Running comprehensive test suite..."
    
    # Frontend tests
    print_status "Running frontend tests..."
    cd svelte-frontend
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
    
    print_success "All tests completed successfully"
}

# Function to start development environment
start_dev() {
    print_status "Starting development environment..."
    
    # Start all services with Docker Compose
    docker-compose up -d
    
    print_success "Development environment started"
    print_status "Services available at:"
    print_status "  - Frontend: http://localhost:5173"
    print_status "  - API Gateway: http://localhost:8080"
    print_status "  - Metrics: http://localhost:9090"
    print_status "  - Prometheus: http://localhost:9092"
    print_status "  - Grafana: http://localhost:3000"
}

# Function to stop development environment
stop_dev() {
    print_status "Stopping development environment..."
    
    docker-compose down
    
    print_success "Development environment stopped"
}

# Function to clean up
cleanup() {
    print_status "Cleaning up..."
    
    # Stop containers
    docker-compose down -v
    
    # Remove unused images
    docker image prune -f
    
    # Clean node modules
    rm -rf svelte-frontend/node_modules
    rm -rf svelte-frontend/build
    
    # Clean Go build artifacts
    rm -rf go-services/bin
    
    # Clean Zig build artifacts
    rm -rf zig-core/zig-out
    
    print_success "Cleanup completed"
}

# Main function
main() {
    echo "=========================================="
    echo "    VoltEdge Development Setup Script    "
    echo "=========================================="
    echo
    
    case "${1:-setup}" in
        "setup")
            check_requirements
            setup_frontend
            setup_backend
            setup_zig_core
            setup_docker
            print_success "Development environment setup completed successfully!"
            ;;
        "test")
            run_tests
            ;;
        "start")
            start_dev
            ;;
        "stop")
            stop_dev
            ;;
        "clean")
            cleanup
            ;;
        "help")
            echo "Usage: $0 [command]"
            echo
            echo "Commands:"
            echo "  setup  - Set up the complete development environment (default)"
            echo "  test   - Run all tests"
            echo "  start  - Start the development environment"
            echo "  stop   - Stop the development environment"
            echo "  clean  - Clean up build artifacts and containers"
            echo "  help   - Show this help message"
            ;;
        *)
            print_error "Unknown command: $1"
            echo "Use '$0 help' to see available commands"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
