#!/bin/bash

echo "=========================================="
echo "  Machine 2 Deployment Script"
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
sleep 15
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

echo -n "  Order Service: "
curl -s http://localhost:3003/health > /dev/null && echo "✅ Healthy" || echo "❌ Unhealthy"

echo ""
echo "=========================================="
echo "  Deployment Complete!"
echo "=========================================="
echo ""
echo "Services running on Machine 2:"
echo "  • Order Service API:   http://localhost:3003"
echo "  • PostgreSQL Database: localhost:5432"
echo "  • Redis Cache:         localhost:6379"
echo "  • Data Sync Worker:    Running in background"
echo ""
echo "View logs:"
echo "  docker-compose logs -f [service-name]"
echo ""
echo "Stop services:"
echo "  docker-compose down"
echo ""
