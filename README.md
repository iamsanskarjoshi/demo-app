# Microservices Demo Application

A complete microservices application with 3 API services, 2 background services, and 1 UI service deployed across 2 Ubuntu machines using Docker.

## Architecture Overview

### Machine 1 (Primary Services + Load Balancer)
- **User Service API** (Port 3001) - Manages user data (Primary)
- **Product Service API** (Port 3002) - Manages product catalog (Primary)
- **Order Service API** (Port 3013) - Manages orders (Replica)
- **Nginx Load Balancer** (Port 8080) - Distributes traffic across both machines
- **Email Worker** (Background) - Processes email notifications
- **UI Service** (Port 80) - React frontend application

### Machine 2 (Secondary Services + Database + Load Balancer)
- **User Service API** (Port 3011) - Manages user data (Replica)
- **Product Service API** (Port 3012) - Manages product catalog (Replica)
- **Order Service API** (Port 3003) - Manages orders (Primary)
- **Nginx Load Balancer** (Port 8080) - Distributes traffic across both machines
- **Data Sync Worker** (Background) - Syncs data between services
- **Redis** (Port 6379) - Message broker for background workers
- **PostgreSQL** (Port 5432) - Database for services

### Load Balancing Features
- ✅ **High Availability** - Services run on both machines
- ✅ **Automatic Failover** - Nginx routes around failed services
- ✅ **Load Distribution** - Requests balanced using least_conn algorithm
- ✅ **Health Checks** - Automatic detection of unhealthy backends

## Services Description

### API Services (Load Balanced across both machines)
1. **User Service** - CRUD operations for users
   - Primary on Machine 1 (:3001)
   - Replica on Machine 2 (:3011)
2. **Product Service** - CRUD operations for products
   - Primary on Machine 1 (:3002)
   - Replica on Machine 2 (:3012)
3. **Order Service** - CRUD operations for orders
   - Primary on Machine 2 (:3003)
   - Replica on Machine 1 (:3013)

### Load Balancers
- **Nginx** on Machine 1 (:8080) - Routes to all API instances
- **Nginx** on Machine 2 (:8080) - Routes to all API instances

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

### Deployment with Load Balancing

#### Step 1: Configure Nginx (Both Machines)
```bash
# Machine 1: Edit nginx/nginx.conf and replace 172.31.11.13 with Machine 2's IP
# Machine 2: Edit nginx/nginx.conf and replace 172.31.11.12 with Machine 1's IP
```

#### Step 2: Open Firewall Ports (Both Machines)
```bash
sudo ufw allow 3001/tcp 3002/tcp 3003/tcp 3011/tcp 3012/tcp 3013/tcp 8080/tcp
```

#### Step 3: Deploy Machine 2 First
```bash
cd machine2
chmod +x deploy-with-lb.sh
./deploy-with-lb.sh
```

#### Step 4: Deploy Machine 1
```bash
cd machine1
# Edit .env file and set MACHINE2_IP to Machine 2's IP address
chmod +x deploy-with-lb.sh
./deploy-with-lb.sh
```

#### Step 5: Test Load Balancing
```bash
chmod +x test-load-balancing.sh
export MACHINE1_IP=<your_machine1_ip>
export MACHINE2_IP=<your_machine2_ip>
./test-load-balancing.sh
```

## Testing Guide

- [TESTING.md](./TESTING.md) - Complete step-by-step testing instructions
- [LOAD-BALANCING.md](./LOAD-BALANCING.md) - Load balancing setup and testing

### Quick Load Balancing Test
```bash
chmod +x test-load-balancing.sh
export MACHINE1_IP=<your_machine1_ip>
export MACHINE2_IP=<your_machine2_ip>
./test-load-balancing.sh
```

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

### Option 1: Direct Service Access

#### User Service
- Machine 1:3001 (Primary) or Machine 2:3011 (Replica)
- GET /api/users - List all users
- POST /api/users - Create user
- GET /api/users/:id - Get user by ID
- PUT /api/users/:id - Update user
- DELETE /api/users/:id - Delete user

#### Product Service
- Machine 1:3002 (Primary) or Machine 2:3012 (Replica)
- GET /api/products - List all products
- POST /api/products - Create product
- GET /api/products/:id - Get product by ID
- PUT /api/products/:id - Update product
- DELETE /api/products/:id - Delete product

#### Order Service
- Machine 2:3003 (Primary) or Machine 1:3013 (Replica)
- GET /api/orders - List all orders
- POST /api/orders - Create order (triggers email notification)
- GET /api/orders/:id - Get order by ID
- PUT /api/orders/:id - Update order
- DELETE /api/orders/:id - Delete order

### Option 2: Through Load Balancer (Recommended)

Access through either machine's Nginx on port 8080:
- `http://MACHINE1_IP:8080/api/users`
- `http://MACHINE1_IP:8080/api/products`
- `http://MACHINE1_IP:8080/api/orders`

OR

- `http://MACHINE2_IP:8080/api/users`
- `http://MACHINE2_IP:8080/api/products`
- `http://MACHINE2_IP:8080/api/orders`

Both load balancers distribute traffic across all service instances!

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
