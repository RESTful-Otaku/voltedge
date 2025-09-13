# VoltEdge - Real-Time Energy Grid Simulator & Monitoring Suite

A comprehensive distributed energy grid simulation platform demonstrating:

- **Zig** → Low-level, high-performance power grid simulation engine
- **Go** → Microservices orchestration, observability, and developer tooling  
- **Svelte** → Modern real-time dashboard with grid visualization and analytics

## 🎯 Project Overview

VoltEdge simulates real-time energy grid dynamics including power generation, consumption, load-balancing, and fault tolerance scenarios. The system demonstrates the full stack from hardware-close performance systems to SaaS-style orchestration and user-facing analytics.

## 🏗️ Architecture

```
┌───────────────────────────┐
│         Frontend          │
│  (Svelte + Vite + D3.js)  │
│  - Grid visualization     │
│  - Real-time metrics (WS) │
│  - Control UI             │
└──────────┬────────────────┘
           │ GraphQL/REST + WebSockets
┌──────────┴────────────────┐
│       Go Microservices    │
│ - Grid API Gateway        │
│ - Observability (Prom+OTel)│
│ - Job orchestration       │
│ - Profiling/debug tools   │
└──────────┬────────────────┘
           │ gRPC / NATS
┌──────────┴────────────────┐
│       Zig Core Engine      │
│ - Power grid simulation    │
│ - Load-balancing algorithm │
│ - Failure injection logic  │
│ - Deterministic testing    │
└───────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- **Zig 0.12+** - High-performance simulation engine
- **Go 1.23+** - Microservices and API layer
- **Node.js 18+** - Frontend development
- **Docker & Docker Compose** - Containerization and deployment

### Automated Setup (Recommended)

Use our comprehensive setup script for a one-command development environment:

```bash
# Clone the repository
git clone https://github.com/yourusername/edge-volt.git
cd edge-volt

# Run the automated setup
./scripts/setup-dev.sh setup

# Start the development environment
./scripts/setup-dev.sh start
```

### Manual Development Setup

1. **Install Dependencies:**
   ```bash
   # Frontend
   cd svelte-frontend
   npm ci
   
   # Backend
   cd ../go-services
   go mod download
   
   # Zig Core
   cd ../zig-core
   zig build
   ```

2. **Run Tests:**
   ```bash
   # Run all tests
   ./scripts/setup-dev.sh test
   
   # Or run individually
   cd svelte-frontend && npm test
   cd ../go-services && go test ./...
   cd ../zig-core && zig build test
   ```

3. **Start Development Environment:**
   ```bash
   # Using Docker Compose (recommended)
   docker-compose up -d
   
   # Or run services individually
   # Terminal 1: Zig Core
   cd zig-core && zig build run
   
   # Terminal 2: Go Services
   cd go-services && go run cmd/main.go
   
   # Terminal 3: Frontend
   cd svelte-frontend && npm run dev
   ```

4. **Access the Application:**
   - **Frontend Dashboard:** http://localhost:5173
   - **API Gateway:** http://localhost:8080
   - **Metrics & Monitoring:** http://localhost:9090
   - **Prometheus:** http://localhost:9092
   - **Grafana:** http://localhost:3000 (admin/admin)

### Production Deployment

```bash
# Build and deploy with Docker Compose
docker-compose -f docker-compose.prod.yml up -d

# Or deploy to GitHub Pages (automated via CI/CD)
git push origin main
```

### Available Scripts

```bash
./scripts/setup-dev.sh setup   # Complete environment setup
./scripts/setup-dev.sh test    # Run all tests
./scripts/setup-dev.sh start   # Start development environment
./scripts/setup-dev.sh stop    # Stop development environment
./scripts/setup-dev.sh clean   # Clean up build artifacts
./scripts/setup-dev.sh help    # Show help
```

## 📁 Project Structure

```
edge-volt/
├── zig-core/                 # Zig simulation engine
│   ├── src/
│   │   ├── grid.zig         # Core grid simulation logic
│   │   ├── power_plant.zig  # Power generation modeling
│   │   ├── transmission.zig # Transmission line simulation
│   │   └── simulator.zig    # Main simulation orchestrator
│   ├── tests/               # Deterministic test scenarios
│   └── build.zig
├── go-services/             # Go microservices layer
│   ├── cmd/                 # Service entry points
│   ├── internal/
│   │   ├── api/            # REST/GraphQL APIs
│   │   ├── grpc/           # gRPC client for Zig
│   │   ├── observability/  # Prometheus, OpenTelemetry
│   │   └── orchestration/  # Job management
│   ├── pkg/                # Shared packages
│   └── tools/              # Developer CLI tools
├── svelte-frontend/         # Modern dashboard
│   ├── src/
│   │   ├── components/     # Reusable UI components
│   │   ├── stores/         # State management
│   │   ├── lib/            # Utilities and D3.js integration
│   │   └── routes/         # Page components
│   └── static/             # Assets and grid data
├── docker/                  # Container configurations
├── docs/                    # API documentation
└── scripts/                 # Build and deployment scripts
```

## 🔧 Key Features

### Zig Core Engine
- **High-Performance Simulation**: 100,000+ events/sec deterministic modeling
- **Grid Components**: Power plants, renewables, batteries, substations
- **Failure Modeling**: Cascading failures, blackouts, fault injection
- **Deterministic Testing**: Reproducible scenarios for validation

### Go Microservices
- **API Gateway**: REST/GraphQL with WebSocket streaming
- **Observability**: Prometheus metrics, OpenTelemetry tracing
- **Orchestration**: Multi-worker simulation management
- **Developer Tools**: CLI for simulation control and debugging

### Svelte Frontend
- **Real-Time Visualization**: Live grid map with D3.js/WebGL
- **Interactive Controls**: Scenario injection, parameter tuning
- **Analytics Dashboard**: Historical data, performance metrics
- **Responsive Design**: Modern UX with accessibility features

## 🧪 Testing Strategy

- **Unit Tests**: Individual component validation
- **Integration Tests**: Cross-service communication
- **Deterministic Simulation Tests**: Reproducible grid scenarios
- **Load Tests**: Performance under high event rates
- **End-to-End Tests**: Full user workflow validation

## 📊 Performance Targets

- **Simulation Latency**: < 1ms per simulation tick
- **API Response Time**: < 100ms for dashboard queries
- **WebSocket Updates**: < 50ms for real-time data
- **Concurrent Users**: 100+ simultaneous dashboard sessions

## 🔒 Security & Reliability

- **Input Validation**: All simulation parameters sanitized
- **Rate Limiting**: API protection against abuse
- **Error Handling**: Graceful degradation and recovery
- **Audit Logging**: Complete simulation history tracking

## 🚀 Deployment

Designed for simple deployment with:
- **Alpine Linux** base images for minimal footprint
- **GitHub Actions** CI/CD pipeline
- **Docker Compose** for local development
- **Production-ready** container orchestration

## 📈 Future Enhancements

- **ML Prediction Module**: Failure prediction using historical data
- **Multi-Tenant SaaS**: Isolated simulation environments
- **Edge Deployment**: Raspberry Pi IoT integration
- **Real Hardware Testing**: Physical grid component simulation

## 🤝 Contributing

This project demonstrates modern engineering practices:
- Clean, modular architecture
- Comprehensive testing
- Performance optimization
- Security best practices
- Developer experience focus

Perfect for showcasing systems programming, distributed architecture, and modern web development skills.


