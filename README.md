# Microservices Demo Application

A complete microservices application with 3 API services, 2 background services, and 1 UI service deployed across 2 Ubuntu machines using Docker.

## Architecture Overview

### Machine 1 (Primary Services)
- **User Service API** (Port 3001) - Manages user data
- **Product Service API** (Port 3002) - Manages product catalog
- **Email Worker** (Background) - Processes email notifications
- **UI Service** (Port 80) - React frontend application

### Machine 2 (Secondary Services)
- **Order Service API** (Port 3003) - Manages orders
- **Data Sync Worker** (Background) - Syncs data between services
- **Redis** (Port 6379) - Message broker for background workers
- **PostgreSQL** (Port 5432) - Database for services

## Services Description

### API Services
1. **User Service** - CRUD operations for users
2. **Product Service** - CRUD operations for products
3. **Order Service** - CRUD operations for orders

### Background Services
1. **Email Worker** - Listens to Redis queue and sends email notifications
2. **Data Sync Worker** - Periodically syncs data across services

### UI Service
- React-based frontend that consumes all API services

## Quick Start

### Prerequisites
- 2 Ubuntu machines (20.04 or later)
- Docker and Docker Compose installed on both machines
- Network connectivity between machines

### Installation

#### On Both Machines:
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Logout and login again for group changes to take effect
```

### Deployment

#### Machine 1 (Primary):
```bash
cd machine1
# Edit .env file and set MACHINE2_IP to Machine 2's IP address
docker-compose up -d
```

#### Machine 2 (Secondary):
```bash
cd machine2
docker-compose up -d
```

## Testing Guide

See [TESTING.md](./TESTING.md) for complete step-by-step testing instructions.

## Environment Variables

### Machine 1 (.env)
```
MACHINE2_IP=<IP_ADDRESS_OF_MACHINE_2>
```

### Machine 2 (.env)
```
POSTGRES_PASSWORD=postgres123
REDIS_PASSWORD=redis123
```

## API Endpoints

### User Service (Machine 1:3001)
- GET /api/users - List all users
- POST /api/users - Create user
- GET /api/users/:id - Get user by ID
- PUT /api/users/:id - Update user
- DELETE /api/users/:id - Delete user

### Product Service (Machine 1:3002)
- GET /api/products - List all products
- POST /api/products - Create product
- GET /api/products/:id - Get product by ID
- PUT /api/products/:id - Update product
- DELETE /api/products/:id - Delete product

### Order Service (Machine 2:3003)
- GET /api/orders - List all orders
- POST /api/orders - Create order (triggers email notification)
- GET /api/orders/:id - Get order by ID
- PUT /api/orders/:id - Update order
- DELETE /api/orders/:id - Delete order

## Monitoring

### Check Service Status
```bash
# On Machine 1
docker-compose ps
docker-compose logs -f [service-name]

# On Machine 2
docker-compose ps
docker-compose logs -f [service-name]
```

## Stopping Services

```bash
# On each machine
docker-compose down

# To remove volumes as well
docker-compose down -v
```

## Troubleshooting

### Services can't connect between machines
- Check firewall rules: `sudo ufw status`
- Open required ports: `sudo ufw allow 3003/tcp` (on Machine 2)
- Test connectivity: `telnet <machine2-ip> 3003`

### Container logs
```bash
docker-compose logs -f [service-name]
```

### Restart a service
```bash
docker-compose restart [service-name]
```

## License
MIT
