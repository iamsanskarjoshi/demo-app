# Microservices Demo - Machine 1 Setup

This directory contains the Docker Compose configuration for Machine 1.

## Services on Machine 1

1. **User Service** (Port 3001) - User management API
2. **Product Service** (Port 3002) - Product management API
3. **Email Worker** (Background) - Email notification processor
4. **UI Service** (Port 80) - React frontend

## Prerequisites

- Docker installed
- Docker Compose installed
- Network connectivity to Machine 2

## Configuration

1. Copy the environment file:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and set `MACHINE2_IP` to Machine 2's IP address:
   ```bash
   MACHINE2_IP=192.168.1.100  # Replace with actual IP
   ```

## Deployment

### Option 1: Using the deployment script
```bash
chmod +x deploy.sh
./deploy.sh
```

### Option 2: Manual deployment
```bash
# Build and start all services
docker-compose up -d --build

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

## Accessing Services

- User Service API: http://localhost:3001
- Product Service API: http://localhost:3002
- UI Application: http://localhost

## Testing

```bash
# Test User Service
curl http://localhost:3001/api/users

# Test Product Service
curl http://localhost:3002/api/products

# Create a user
curl -X POST http://localhost:3001/api/users \
  -H "Content-Type: application/json" \
  -d '{"name": "John Doe", "email": "john@example.com", "age": 30}'
```

## Monitoring

```bash
# View all logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f user-service
docker-compose logs -f email-worker

# Check resource usage
docker stats
```

## Troubleshooting

### Services can't connect to Machine 2
1. Check if Machine 2 services are running
2. Verify firewall settings on Machine 2:
   ```bash
   sudo ufw allow 5432/tcp
   sudo ufw allow 6379/tcp
   sudo ufw allow 3003/tcp
   ```
3. Test connectivity:
   ```bash
   telnet <MACHINE2_IP> 5432
   ```

### Email worker not processing jobs
1. Check Redis connectivity on Machine 2
2. View email worker logs:
   ```bash
   docker-compose logs -f email-worker
   ```

## Stopping Services

```bash
# Stop all services
docker-compose down

# Stop and remove volumes
docker-compose down -v
```
