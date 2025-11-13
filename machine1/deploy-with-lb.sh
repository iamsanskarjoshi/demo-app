#!/bin/bash

# Deploy script for Machine 1 with Load Balancing

echo "=========================================="
echo "  Machine 1 Deployment Script"
echo "  WITH LOAD BALANCING"
echo "=========================================="
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo "⚠️  .env file not found. Creating from .env.example..."
    cp .env.example .env
    echo "✅ Created .env file"
    echo ""
    echo "⚠️  IMPORTANT: Please edit .env and set MACHINE2_IP to Machine 2's IP address!"
    echo "   Example: MACHINE2_IP=172.31.11.13"
    echo ""
    read -p "Press Enter after you've updated the .env file..."
fi

# Load environment variables
source .env

echo "Configuration:"
echo "  Machine 2 IP: ${MACHINE2_IP}"
echo ""

# Check nginx config
echo "🔍 Checking Nginx configuration..."
if [ ! -f nginx/nginx.conf ]; then
    echo "❌ nginx/nginx.conf not found!"
    exit 1
fi

# Verify Machine 2 IP in nginx config
if grep -q "172.31.11.13" nginx/nginx.conf; then
    echo "⚠️  WARNING: nginx.conf contains example IP (172.31.11.13)"
    echo "   You should update it to your actual Machine 2 IP!"
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
sleep 15
echo ""

# Check service status
echo "📊 Service Status:"
docker-compose ps
echo ""

# Check service health
echo "🏥 Health Checks:"
echo -n "  User Service (Primary): "
curl -s http://localhost:3001/health > /dev/null && echo "✅ Healthy" || echo "❌ Unhealthy"

echo -n "  Product Service (Primary): "
curl -s http://localhost:3002/health > /dev/null && echo "✅ Healthy" || echo "❌ Unhealthy"

echo -n "  Order Service (Replica): "
curl -s http://localhost:3013/health > /dev/null && echo "✅ Healthy" || echo "❌ Unhealthy"

echo -n "  Nginx Load Balancer: "
curl -s http://localhost:8080/health > /dev/null && echo "✅ Healthy" || echo "❌ Unhealthy"

echo -n "  UI Service: "
curl -s http://localhost/ > /dev/null && echo "✅ Healthy" || echo "❌ Unhealthy"

echo ""
echo "=========================================="
echo "  Deployment Complete!"
echo "=========================================="
echo ""
echo "Services running on Machine 1:"
echo "  • User Service API (Primary):    http://localhost:3001"
echo "  • Product Service API (Primary):  http://localhost:3002"
echo "  • Order Service API (Replica):    http://localhost:3013"
echo "  • Nginx Load Balancer:            http://localhost:8080  ⭐"
echo "  • Email Worker:                   Running in background"
echo "  • UI Service:                     http://localhost"
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
echo "🧪 Test Load Balancing:"
echo "  cd .. && ./test-load-balancing.sh"
echo ""
echo "View logs:"
echo "  docker-compose logs -f [service-name]"
echo ""
echo "Stop services:"
echo "  docker-compose down"
echo ""
