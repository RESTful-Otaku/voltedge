# Multi-stage build for VoltEdge Zig Core Engine
FROM alpine:3.19 as builder

# Install build dependencies
RUN apk add --no-cache \
    zig \
    build-base \
    git \
    cmake

# Set working directory
WORKDIR /app

# Copy source code
COPY . .

# Build the application
RUN zig build -Doptimize=ReleaseFast

# Production stage
FROM alpine:3.19

# Install runtime dependencies
RUN apk add --no-cache \
    libc6-compat \
    ca-certificates

# Create non-root user
RUN addgroup -g 1001 -S voltedge && \
    adduser -S voltedge -u 1001 -G voltedge

# Set working directory
WORKDIR /app

# Copy binary from builder stage
COPY --from=builder /app/zig-out/bin/voltedge-sim /app/voltedge-sim

# Create data directory
RUN mkdir -p /app/data && \
    chown -R voltedge:voltedge /app

# Switch to non-root user
USER voltedge

# Expose gRPC port
EXPOSE 9091

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD nc -z localhost 9091 || exit 1

# Default command
CMD ["./voltedge-sim", "--port", "9091", "--tick-rate", "100"]

