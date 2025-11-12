#!/bin/bash

echo "=========================================="
echo "  Machine 1 Deployment Script"
echo "=========================================="
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo "⚠️  .env file not found. Creating from .env.example..."
    cp .env.example .env
    echo "✅ Created .env file"
    echo ""
    echo "⚠️  IMPORTANT: Please edit .env and set MACHINE2_IP to Machine 2's IP address!"
    echo "   Example: MACHINE2_IP=192.168.1.100"
    echo ""
    read -p "Press Enter after you've updated the .env file..."
fi

# Load environment variables
source .env

echo "Configuration:"
echo "  Machine 2 IP: ${MACHINE2_IP}"
echo ""

# Stop existing containers
echo "🛑 Stopping existing containers..."
docker-compose down
echo ""

# Build and start services
echo "🚀 Building and starting services..."
docker-compose up -d --build
echo ""

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 10
echo ""

# Check service status
echo "📊 Service Status:"
docker-compose ps
echo ""

# Check service health
echo "🏥 Health Checks:"
echo -n "  User Service: "
curl -s http://localhost:3001/health > /dev/null && echo "✅ Healthy" || echo "❌ Unhealthy"

echo -n "  Product Service: "
curl -s http://localhost:3002/health > /dev/null && echo "✅ Healthy" || echo "❌ Unhealthy"

echo -n "  UI Service: "
curl -s http://localhost/ > /dev/null && echo "✅ Healthy" || echo "❌ Unhealthy"

echo ""
echo "=========================================="
echo "  Deployment Complete!"
echo "=========================================="
echo ""
echo "Services running on Machine 1:"
echo "  • User Service API:    http://localhost:3001"
echo "  • Product Service API: http://localhost:3002"
echo "  • UI Service:          http://localhost"
echo "  • Email Worker:        Running in background"
echo ""
echo "View logs:"
echo "  docker-compose logs -f [service-name]"
echo ""
echo "Stop services:"
echo "  docker-compose down"
echo ""
