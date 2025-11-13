#!/bin/bash

# Deploy script for Machine 2 with Load Balancing

echo "=========================================="
echo "  Machine 2 Deployment Script"
echo "  WITH LOAD BALANCING"
echo "=========================================="
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo "⚠️  .env file not found. Creating from .env.example..."
    cp .env.example .env
    echo "✅ Created .env file"
    echo ""
fi

# Load environment variables
source .env

echo "Configuration:"
echo "  Database: PostgreSQL"
echo "  Cache: Redis"
echo ""

# Check nginx config
echo "🔍 Checking Nginx configuration..."
if [ ! -f nginx/nginx.conf ]; then
    echo "❌ nginx/nginx.conf not found!"
    exit 1
fi

# Verify Machine 1 IP in nginx config
if grep -q "172.31.11.12" nginx/nginx.conf; then
    echo "⚠️  WARNING: nginx.conf contains example IP (172.31.11.12)"
    echo "   You should update it to your actual Machine 1 IP!"
    echo ""
    read -p "Do you want to continue anyway? (y/n): " CONTINUE
    if [ "$CONTINUE" != "y" ]; then
        echo "Deployment cancelled. Please update nginx/nginx.conf"
        exit 1
    fi
fi

echo "✅ Nginx configuration found"
echo ""

# Stop existing containers
echo "🛑 Stopping existing containers..."
docker-compose down
echo ""

# Build and start services
echo "🚀 Building and starting services with load balancing..."
docker-compose up -d --build
echo ""

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 20
echo ""

# Check service status
echo "📊 Service Status:"
docker-compose ps
echo ""

# Check service health
echo "🏥 Health Checks:"
echo -n "  PostgreSQL: "
docker-compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1 && echo "✅ Healthy" || echo "❌ Unhealthy"

echo -n "  Redis: "
docker-compose exec -T redis redis-cli -a redis123 ping > /dev/null 2>&1 && echo "✅ Healthy" || echo "❌ Unhealthy"

echo -n "  Order Service (Primary): "
curl -s http://localhost:3003/health > /dev/null && echo "✅ Healthy" || echo "❌ Unhealthy"

echo -n "  User Service (Replica): "
curl -s http://localhost:3011/health > /dev/null && echo "✅ Healthy" || echo "❌ Unhealthy"

echo -n "  Product Service (Replica): "
curl -s http://localhost:3012/health > /dev/null && echo "✅ Healthy" || echo "❌ Unhealthy"

echo -n "  Nginx Load Balancer: "
curl -s http://localhost:8080/health > /dev/null && echo "✅ Healthy" || echo "❌ Unhealthy"

echo ""
echo "=========================================="
echo "  Deployment Complete!"
echo "=========================================="
echo ""
echo "Services running on Machine 2:"
echo "  • Order Service API (Primary):    http://localhost:3003"
echo "  • User Service API (Replica):     http://localhost:3011"
echo "  • Product Service API (Replica):  http://localhost:3012"
echo "  • Nginx Load Balancer:            http://localhost:8080  ⭐"
echo "  • PostgreSQL Database:            localhost:5432"
echo "  • Redis Cache:                    localhost:6379"
echo "  • Data Sync Worker:               Running in background"
echo ""
echo "🎯 Load Balancer Features:"
echo "  ✓ Distributes traffic across both machines"
echo "  ✓ Automatic failover on service failure"
echo "  ✓ Health checks every 10 seconds"
echo ""
echo "📡 Access APIs through Load Balancer (Recommended):"
echo "  curl http://localhost:8080/api/users"
echo "  curl http://localhost:8080/api/products"
echo "  curl http://localhost:8080/api/orders"
echo ""
echo "📊 Monitor Load Balancer:"
echo "  curl http://localhost:8080/nginx-status"
echo "  docker logs nginx-lb -f"
echo ""
echo "View logs:"
echo "  docker-compose logs -f [service-name]"
echo ""
echo "Stop services:"
echo "  docker-compose down"
echo ""
