# Multi-stage build for VoltEdge Svelte Frontend
FROM node:18-alpine AS builder

# Install dependencies
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Copy source code and build
COPY . .
RUN npm run build

# Production stage
FROM alpine:3.19

# Install nginx and runtime dependencies
RUN apk add --no-cache nginx wget

# Create directories
RUN mkdir -p /var/lib/nginx/tmp/client_temp \
             /var/lib/nginx/tmp/proxy_temp \
             /var/lib/nginx/tmp/fastcgi_temp \
             /var/lib/nginx/tmp/uwsgi_temp \
             /var/lib/nginx/tmp/scgi_temp \
             /var/log/nginx \
             /etc/nginx/conf.d \
             /app

# Copy built application
COPY --from=builder /app/build /app

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Set permissions
RUN chown -R nginx:nginx /var/lib/nginx /var/log/nginx /etc/nginx /app

# Switch to nginx user
USER nginx

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
