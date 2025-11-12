# Microservices Demo - Machine 2 Setup

This directory contains the Docker Compose configuration for Machine 2.

## Services on Machine 2

1. **Order Service** (Port 3003) - Order management API
2. **PostgreSQL** (Port 5432) - Database for all services
3. **Redis** (Port 6379) - Message queue for background workers
4. **Data Sync Worker** (Background) - Data synchronization processor

## Prerequisites

- Docker installed
- Docker Compose installed
- Firewall configured to allow connections from Machine 1

## Configuration

1. Copy the environment file:
   ```bash
   cp .env.example .env
   ```

2. (Optional) Edit `.env` to change default passwords

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

## Firewall Configuration

Machine 1 needs to access these ports on Machine 2:

```bash
# Allow PostgreSQL
sudo ufw allow 5432/tcp

# Allow Redis
sudo ufw allow 6379/tcp

# Allow Order Service
sudo ufw allow 3003/tcp

# Check firewall status
sudo ufw status
```

## Accessing Services

- Order Service API: http://localhost:3003
- PostgreSQL: localhost:5432
- Redis: localhost:6379

## Testing

```bash
# Test Order Service
curl http://localhost:3003/api/orders

# Create an order
curl -X POST http://localhost:3003/api/orders \
  -H "Content-Type: application/json" \
  -d '{"userId": 1, "productId": 1, "quantity": 2, "totalAmount": 1999.98}'

# Check PostgreSQL
docker-compose exec postgres psql -U postgres -d microservices -c "SELECT * FROM orders;"

# Check Redis
docker-compose exec redis redis-cli -a redis123 INFO
```

## Database Management

```bash
# Connect to PostgreSQL
docker-compose exec postgres psql -U postgres -d microservices

# View tables
\dt

# Query users
SELECT * FROM users;

# Query products
SELECT * FROM products;

# Query orders
SELECT * FROM orders;

# Exit
\q
```

## Redis Management

```bash
# Connect to Redis
docker-compose exec redis redis-cli -a redis123

# Check queue length
LLEN email-queue

# View queue items (without removing)
LRANGE email-queue 0 -1

# Exit
exit
```

## Monitoring

```bash
# View all logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f order-service
docker-compose logs -f data-sync-worker
docker-compose logs -f postgres
docker-compose logs -f redis

# Check resource usage
docker stats
```

## Backup and Restore

### Backup Database
```bash
docker-compose exec postgres pg_dump -U postgres microservices > backup.sql
```

### Restore Database
```bash
cat backup.sql | docker-compose exec -T postgres psql -U postgres microservices
```

## Troubleshooting

### Database connection errors
1. Check if PostgreSQL is running:
   ```bash
   docker-compose ps postgres
   ```
2. Check logs:
   ```bash
   docker-compose logs postgres
   ```

### Redis connection errors
1. Check if Redis is running:
   ```bash
   docker-compose ps redis
   ```
2. Test connection:
   ```bash
   docker-compose exec redis redis-cli -a redis123 PING
   ```

## Stopping Services

```bash
# Stop all services
docker-compose down

# Stop and remove volumes (WARNING: This deletes all data)
docker-compose down -v
```
