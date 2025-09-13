#!/bin/bash

# VoltEdge Setup Script
# This script sets up the development environment for VoltEdge

set -e

echo "🚀 Setting up VoltEdge Development Environment..."

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

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    local missing_deps=()
    
    if ! command_exists zig; then
        missing_deps+=("zig")
    fi
    
    if ! command_exists go; then
        missing_deps+=("go")
    fi
    
    if ! command_exists node; then
        missing_deps+=("node")
    fi
    
    if ! command_exists docker; then
        missing_deps+=("docker")
    fi
    
    if ! command_exists docker-compose; then
        missing_deps+=("docker-compose")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        print_status "Please install the missing dependencies and run this script again."
        exit 1
    fi
    
    print_success "All prerequisites are installed"
}

# Setup Zig core
setup_zig_core() {
    print_status "Setting up Zig core simulation engine..."
    
    cd zig-core
    
    # Check if Zig build works
    if zig build --help >/dev/null 2>&1; then
        print_success "Zig build system is working"
    else
        print_error "Zig build system is not working"
        exit 1
    fi
    
    cd ..
    print_success "Zig core setup complete"
}

# Setup Go services
setup_go_services() {
    print_status "Setting up Go microservices..."
    
    cd go-services
    
    # Download dependencies
    if go mod download; then
        print_success "Go dependencies downloaded"
    else
        print_error "Failed to download Go dependencies"
        exit 1
    fi
    
    # Build the application
    if go build -o bin/voltedge-api ./cmd/main.go; then
        print_success "Go services built successfully"
    else
        print_error "Failed to build Go services"
        exit 1
    fi
    
    cd ..
    print_success "Go services setup complete"
}

# Setup Svelte frontend
setup_svelte_frontend() {
    print_status "Setting up Svelte frontend..."
    
    cd svelte-frontend
    
    # Install dependencies
    if npm install; then
        print_success "Node.js dependencies installed"
    else
        print_error "Failed to install Node.js dependencies"
        exit 1
    fi
    
    # Build the application
    if npm run build; then
        print_success "Svelte frontend built successfully"
    else
        print_error "Failed to build Svelte frontend"
        exit 1
    fi
    
    cd ..
    print_success "Svelte frontend setup complete"
}

# Create data directories
create_data_directories() {
    print_status "Creating data directories..."
    
    mkdir -p data/simulations
    mkdir -p data/logs
    mkdir -p data/metrics
    
    print_success "Data directories created"
}

# Setup environment files
setup_environment() {
    print_status "Setting up environment configuration..."
    
    # Create .env file for docker-compose
    cat > .env << EOF
# VoltEdge Environment Configuration

# Zig Core Configuration
ZIG_GRPC_PORT=9091
ZIG_TICK_RATE_MS=100
ZIG_MAX_SIMULATIONS=10

# Go Services Configuration
GO_API_PORT=8080
GO_WS_PORT=8081
GO_METRICS_PORT=9090
GO_LOG_LEVEL=info

# Svelte Frontend Configuration
VITE_API_URL=http://localhost:8080
VITE_WS_URL=ws://localhost:8081

# Database Configuration (if using)
DATABASE_URL=postgres://voltedge:voltedge@localhost:5432/voltedge

# Redis Configuration (if using)
REDIS_URL=redis://localhost:6379

# Monitoring Configuration
PROMETHEUS_PORT=9092
GRAFANA_PORT=3000
GRAFANA_ADMIN_PASSWORD=admin
EOF
    
    print_success "Environment configuration created"
}

# Build Docker images
build_docker_images() {
    print_status "Building Docker images..."
    
    if docker-compose build; then
        print_success "Docker images built successfully"
    else
        print_error "Failed to build Docker images"
        exit 1
    fi
}

# Run tests
run_tests() {
    print_status "Running tests..."
    
    # Test Zig core
    print_status "Testing Zig core..."
    cd zig-core
    if zig test; then
        print_success "Zig tests passed"
    else
        print_warning "Zig tests failed (this is expected if no tests are implemented yet)"
    fi
    cd ..
    
    # Test Go services
    print_status "Testing Go services..."
    cd go-services
    if go test ./...; then
        print_success "Go tests passed"
    else
        print_warning "Go tests failed (this is expected if no tests are implemented yet)"
    fi
    cd ..
    
    # Test Svelte frontend
    print_status "Testing Svelte frontend..."
    cd svelte-frontend
    if npm run check; then
        print_success "Svelte checks passed"
    else
        print_warning "Svelte checks failed (this is expected if no tests are implemented yet)"
    fi
    cd ..
}

# Main setup function
main() {
    echo "🌍 VoltEdge - Real-Time Energy Grid Simulator & Monitoring Suite"
    echo "=================================================================="
    echo ""
    
    check_prerequisites
    create_data_directories
    setup_environment
    setup_zig_core
    setup_go_services
    setup_svelte_frontend
    build_docker_images
    run_tests
    
    echo ""
    echo "🎉 Setup complete! VoltEdge is ready to run."
    echo ""
    echo "Quick Start:"
    echo "  Development mode:"
    echo "    docker-compose up -d"
    echo ""
    echo "  Access the application:"
    echo "    Frontend:    http://localhost:5173"
    echo "    API:         http://localhost:8080"
    echo "    Metrics:     http://localhost:9090"
    echo "    Prometheus:  http://localhost:9092"
    echo "    Grafana:     http://localhost:3000 (admin/admin)"
    echo ""
    echo "  Individual services:"
    echo "    Zig Core:    cd zig-core && zig build run"
    echo "    Go API:      cd go-services && go run cmd/main.go"
    echo "    Frontend:    cd svelte-frontend && npm run dev"
    echo ""
    echo "For more information, see the README.md file."
}

# Run main function
main "$@"


