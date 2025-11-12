# Installation Guide - Complete Step-by-Step Instructions

This guide will walk you through installing and testing the complete microservices application on 2 Ubuntu machines.

---

## 📋 Prerequisites

### Hardware Requirements
- **2 Ubuntu machines** (20.04 or later)
  - Machine 1: Minimum 2GB RAM, 10GB disk
  - Machine 2: Minimum 2GB RAM, 20GB disk (for database)
- Network connectivity between both machines

### Software Requirements (will be installed)
- Docker
- Docker Compose
- curl

---

## 🚀 Installation Steps

### Part 1: On Both Machines

#### Step 1.1: Update System
```bash
sudo apt update
sudo apt upgrade -y
```

#### Step 1.2: Install Docker
```bash
# Download and run Docker installation script
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your user to docker group (replace 'youruser' with your username)
sudo usermod -aG docker $USER

# Verify installation
docker --version
```

#### Step 1.3: Install Docker Compose
```bash
# Download Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Make it executable
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker-compose --version
```

#### Step 1.4: Install curl (if not already installed)
```bash
sudo apt install curl -y
```

#### Step 1.5: Logout and Login
```bash
# IMPORTANT: Logout and login again for docker group changes to take effect
exit
# Then SSH back in or login again
```

#### Step 1.6: Download the Application
```bash
# Clone or download the application files to both machines
# For this demo, assume files are in ~/microservices-demo

cd ~
# (Copy the microservices-demo folder to this location)
```

---

### Part 2: Machine 2 Setup (Database Server)

**⚠️ IMPORTANT: Set up Machine 2 FIRST before Machine 1**

#### Step 2.1: Get Machine 2's IP Address
```bash
# Find your IP address
hostname -I
# Note down the IP address (e.g., 192.168.1.100)
```

#### Step 2.2: Configure Firewall
```bash
# Install UFW if not present
sudo apt install ufw -y

# Allow SSH (important!)
sudo ufw allow ssh
sudo ufw allow 22/tcp

# Allow services
sudo ufw allow 5432/tcp  # PostgreSQL
sudo ufw allow 6379/tcp  # Redis
sudo ufw allow 3003/tcp  # Order Service

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status
```

#### Step 2.3: Navigate to Machine 2 Directory
```bash
cd ~/microservices-demo/machine2
```

#### Step 2.4: Create Environment File
```bash
# Copy example environment file
cp .env.example .env

# Optional: Edit .env to change passwords
nano .env
# Press Ctrl+X, then Y, then Enter to save
```

#### Step 2.5: Deploy Services
```bash
# Make deploy script executable
chmod +x deploy.sh

# Run deployment
./deploy.sh
```

#### Step 2.6: Verify Services are Running
```bash
# Check all services are up
docker-compose ps

# You should see:
# - postgres (healthy)
# - redis (healthy)
# - order-service (Up)
# - data-sync-worker (Up)

# Check logs
docker-compose logs -f

# Press Ctrl+C to stop following logs
```

#### Step 2.7: Test Machine 2 Services
```bash
# Test Order Service
curl http://localhost:3003/health

# Should return: {"status":"healthy","service":"order-service",...}

# Test PostgreSQL
docker-compose exec postgres pg_isready -U postgres

# Should return: postgres:5432 - accepting connections

# Test Redis
docker-compose exec redis redis-cli -a redis123 PING

# Should return: PONG
```

✅ **Machine 2 is now ready!**

---

### Part 3: Machine 1 Setup (Application Server)

#### Step 3.1: Navigate to Machine 1 Directory
```bash
cd ~/microservices-demo/machine1
```

#### Step 3.2: Create and Configure Environment File
```bash
# Copy example environment file
cp .env.example .env

# Edit .env and set Machine 2's IP address
nano .env

# Change this line:
# MACHINE2_IP=192.168.1.100
# Replace 192.168.1.100 with Machine 2's actual IP address

# Press Ctrl+X, then Y, then Enter to save
```

#### Step 3.3: Deploy Services
```bash
# Make deploy script executable
chmod +x deploy.sh

# Run deployment
./deploy.sh
```

#### Step 3.4: Verify Services are Running
```bash
# Check all services are up
docker-compose ps

# You should see:
# - user-service (Up)
# - product-service (Up)
# - email-worker (Up)
# - ui-service (Up)

# Check logs
docker-compose logs -f

# Press Ctrl+C to stop following logs
```

#### Step 3.5: Test Machine 1 Services
```bash
# Test User Service
curl http://localhost:3001/health

# Test Product Service
curl http://localhost:3002/health

# Test UI Service
curl http://localhost/
```

✅ **Machine 1 is now ready!**

---

## 🧪 Testing the Complete Application

### Test 1: Run Automated Tests

On Machine 1, run the comprehensive test script:

```bash
cd ~/microservices-demo

# Make test script executable
chmod +x test-all.sh

# Run tests (assuming Machine 2 IP is 192.168.1.100)
export MACHINE2_IP=192.168.1.100
./test-all.sh
```

### Test 2: Manual API Testing

#### On Machine 1:

```bash
# Create a user
curl -X POST http://localhost:3001/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com","age":30}'

# Get all users
curl http://localhost:3001/api/users

# Create a product
curl -X POST http://localhost:3002/api/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Laptop","description":"High-performance laptop","price":999.99,"stock":10}'

# Get all products
curl http://localhost:3002/api/products
```

#### On Machine 1 (connecting to Machine 2):

```bash
# Replace 192.168.1.100 with your Machine 2 IP
MACHINE2_IP=192.168.1.100

# Create an order (this will trigger email worker!)
curl -X POST http://${MACHINE2_IP}:3003/api/orders \
  -H "Content-Type: application/json" \
  -d '{"userId":1,"productId":1,"quantity":2,"totalAmount":1999.98}'

# Get all orders
curl http://${MACHINE2_IP}:3003/api/orders
```

### Test 3: Verify Email Worker

On Machine 1, check if the email worker processed the order:

```bash
cd ~/microservices-demo/machine1
docker-compose logs email-worker

# You should see output like:
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📧 EMAIL NOTIFICATION SENT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Order ID: 1
# ...
```

### Test 4: Verify Data Sync Worker

On Machine 2, check the data sync worker:

```bash
cd ~/microservices-demo/machine2
docker-compose logs data-sync-worker

# You should see periodic sync operations:
# 🔄 DATA SYNC STARTED
# 📊 Syncing Users...
# ✅ Users synced: X records
# ...
```

### Test 5: Test the UI

Open a web browser and navigate to:
```
http://<MACHINE1_IP>
```

Or if you're on Machine 1:
```
http://localhost
```

You should see:
- A dashboard with statistics
- Lists of users, products, and orders
- Ability to create new users, products, and orders
- Auto-refresh every 5 seconds

---

## 📊 Monitoring

### View All Logs

#### On Machine 1:
```bash
cd ~/microservices-demo/machine1

# All services
docker-compose logs -f

# Specific service
docker-compose logs -f user-service
docker-compose logs -f email-worker
```

#### On Machine 2:
```bash
cd ~/microservices-demo/machine2

# All services
docker-compose logs -f

# Specific service
docker-compose logs -f order-service
docker-compose logs -f data-sync-worker
docker-compose logs -f postgres
```

### Resource Usage

```bash
# Check CPU and memory usage
docker stats
```

### Database Inspection

On Machine 2:
```bash
# Connect to PostgreSQL
docker-compose exec postgres psql -U postgres -d microservices

# List tables
\dt

# View data
SELECT * FROM users;
SELECT * FROM products;
SELECT * FROM orders;

# Exit
\q
```

---

## 🔧 Troubleshooting

### Problem: Services on Machine 1 can't connect to Machine 2

**Solution:**
```bash
# On Machine 2, verify firewall
sudo ufw status

# Ensure these ports are open
sudo ufw allow 5432/tcp
sudo ufw allow 6379/tcp
sudo ufw allow 3003/tcp

# Test connectivity from Machine 1
telnet <MACHINE2_IP> 5432
telnet <MACHINE2_IP> 6379
telnet <MACHINE2_IP> 3003
```

### Problem: Docker permission denied

**Solution:**
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Logout and login again
exit
# Then SSH back in
```

### Problem: Service won't start

**Solution:**
```bash
# Check logs
docker-compose logs [service-name]

# Restart service
docker-compose restart [service-name]

# Rebuild and restart
docker-compose up -d --build [service-name]
```

### Problem: Port already in use

**Solution:**
```bash
# Find what's using the port
sudo lsof -i :3001

# Kill the process or change the port in docker-compose.yml
```

---

## 🛑 Stopping Services

### On Machine 1:
```bash
cd ~/microservices-demo/machine1
docker-compose down
```

### On Machine 2:
```bash
cd ~/microservices-demo/machine2
docker-compose down
```

### To also remove data:
```bash
# This will delete all database data!
docker-compose down -v
```

---

## ✅ Success Checklist

- [ ] Docker and Docker Compose installed on both machines
- [ ] Machine 2 services running and accessible
- [ ] Machine 1 services running and can connect to Machine 2
- [ ] User Service API works (create/read users)
- [ ] Product Service API works (create/read products)
- [ ] Order Service API works (create/read orders)
- [ ] Email Worker processes order notifications
- [ ] Data Sync Worker runs periodic syncs
- [ ] UI accessible and displays all data
- [ ] Cross-machine communication verified

---

## 📝 Next Steps

1. **Production Hardening:**
   - Change default passwords
   - Enable SSL/TLS
   - Set up proper authentication
   - Configure backup strategy

2. **Monitoring:**
   - Set up Prometheus and Grafana
   - Configure log aggregation
   - Set up alerts

3. **Scaling:**
   - Add more instances of services
   - Set up load balancing
   - Implement service mesh

---

## 📞 Support

If you encounter any issues:
1. Check the logs: `docker-compose logs -f`
2. Verify network connectivity between machines
3. Ensure all ports are open on firewalls
4. Check the TESTING.md file for detailed test procedures
