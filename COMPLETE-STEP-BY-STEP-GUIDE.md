# 🎯 Complete Step-by-Step Deployment Guide

**Last Updated:** November 13, 2025  
**Estimated Time:** 30-45 minutes  
**Difficulty:** Intermediate

This guide will walk you through **every single step** to deploy your load-balanced microservices application on 2 Ubuntu machines.

---

## 📋 Table of Contents

1. [Prerequisites Check](#step-1-prerequisites-check)
2. [Prepare Machine Information](#step-2-prepare-machine-information)
3. [Setup Machine 2 (Database & Redis Host)](#step-3-setup-machine-2)
4. [Setup Machine 1 (Primary Application Host)](#step-4-setup-machine-1)
5. [Configure Load Balancing](#step-5-configure-load-balancing)
6. [Deploy Services](#step-6-deploy-services)
7. [Verify Deployment](#step-7-verify-deployment)
8. [Test Load Balancing](#step-8-test-load-balancing)
9. [Access Your Application](#step-9-access-your-application)
10. [Troubleshooting](#step-10-troubleshooting)

---

## Step 1: Prerequisites Check

### On BOTH Ubuntu Machines

**1.1** Check if Docker is installed:
```bash
docker --version
```
Expected output: `Docker version 20.10.x` or higher

**1.2** Check if Docker Compose is installed:
```bash
docker-compose --version
```
Expected output: `docker-compose version 1.29.x` or higher

**1.3** If NOT installed, install Docker:
```bash
# Update system
sudo apt-get update

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your user to docker group (to run without sudo)
sudo usermod -aG docker $USER

# Log out and log back in, then verify
docker --version
```

**1.4** Install Docker Compose (if needed):
```bash
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
```

**1.5** Check network connectivity between machines:
```bash
# On Machine 1, ping Machine 2
ping -c 3 172.31.11.13

# On Machine 2, ping Machine 1 (replace with actual IP)
ping -c 3 <MACHINE_1_IP>
```

✅ **Checkpoint:** Both machines have Docker installed and can ping each other.

---

## Step 2: Prepare Machine Information

**2.1** Get Machine 2 IP address:
```bash
# On Machine 2
hostname -I
```
Write down the first IP (e.g., `172.31.11.13`)

**2.2** Get Machine 1 IP address:
```bash
# On Machine 1
hostname -I
```
Write down the first IP (e.g., `172.31.10.50`)

**2.3** Fill in this table:

| Machine | IP Address | Role |
|---------|------------|------|
| Machine 1 | `____________` | Primary App + UI + Nginx LB |
| Machine 2 | `172.31.11.13` | Database + Redis + Nginx LB |

✅ **Checkpoint:** You have both IP addresses written down.

---

## Step 3: Setup Machine 2

### Why Machine 2 First?
Machine 2 hosts PostgreSQL and Redis, which Machine 1 services need to connect to.

**3.1** Copy project to Machine 2:
```bash
# On Machine 2
cd /tmp
```

**If files are already in `/tmp/microservices-demo`:**
```bash
cd /tmp/microservices-demo/machine2
```

**If not, you need to transfer the files** (use scp, git, or USB):
```bash
# Example: From your development machine
scp -r /tmp/microservices-demo user@172.31.11.13:/tmp/
```

**3.2** Navigate to Machine 2 directory:
```bash
cd /tmp/microservices-demo/machine2
```

**3.3** Verify files are present:
```bash
ls -la
```
You should see:
- `docker-compose.yml`
- `nginx/` directory
- `.env.example`

**3.4** Create environment file:
```bash
cp .env.example .env
```

**3.5** Edit the `.env` file:
```bash
nano .env
```

Update these values:
```env
# Machine IPs
MACHINE1_IP=<YOUR_MACHINE_1_IP>      # Replace with actual Machine 1 IP
MACHINE2_IP=172.31.11.13              # Your Machine 2 IP

# Database
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_USER=appuser
POSTGRES_PASSWORD=apppass123          # Change this in production!
POSTGRES_DB=microservices_db

# Redis
REDIS_HOST=redis
REDIS_PORT=6379
```

Save and exit (CTRL+X, Y, Enter)

**3.6** Edit Nginx configuration with actual IPs:
```bash
nano nginx/nginx.conf
```

Find all instances of `<MACHINE_1_IP>` and replace with your actual Machine 1 IP:

**Before:**
```nginx
upstream user_service {
    least_conn;
    server <MACHINE_1_IP>:3001;
    server 172.31.11.13:3011;
}
```

**After:**
```nginx
upstream user_service {
    least_conn;
    server 172.31.10.50:3001;    # Your actual Machine 1 IP
    server 172.31.11.13:3011;
}
```

Repeat for all upstream blocks (user_service, product_service, order_service).

Save and exit (CTRL+X, Y, Enter)

**3.7** Configure firewall to allow required ports:
```bash
# Allow PostgreSQL
sudo ufw allow 5432/tcp

# Allow Redis
sudo ufw allow 6379/tcp

# Allow Nginx Load Balancer
sudo ufw allow 8080/tcp

# Allow API services
sudo ufw allow 3001:3003/tcp
sudo ufw allow 3011:3013/tcp

# Allow HTTP for UI
sudo ufw allow 80/tcp

# Check status
sudo ufw status
```

**3.8** Make deploy script executable:
```bash
chmod +x deploy-with-lb.sh
```

**3.9** Deploy Machine 2 services:
```bash
./deploy-with-lb.sh
```

**3.10** Wait for services to start (about 1-2 minutes), then verify:
```bash
docker-compose ps
```

You should see all services as "Up":
- `postgres`
- `redis`
- `nginx-lb`
- `user-service-replica`
- `product-service-replica`
- `order-service`
- `data-sync-worker`

**3.11** Check PostgreSQL is accessible:
```bash
docker-compose exec postgres psql -U appuser -d microservices_db -c "\dt"
```
Should show tables: `users`, `products`, `orders`, `sync_stats`

**3.12** Check Redis is accessible:
```bash
docker-compose exec redis redis-cli ping
```
Should return: `PONG`

**3.13** Test Nginx load balancer:
```bash
curl http://localhost:8080/health
```
Should return JSON with service health status.

✅ **Checkpoint:** Machine 2 is fully deployed with all services running.

---

## Step 4: Setup Machine 1

**4.1** Copy project to Machine 1 (if not already there):
```bash
# On Machine 1
cd /tmp/microservices-demo/machine1
```

**4.2** Verify files:
```bash
ls -la
```
Should see:
- `docker-compose.yml`
- `nginx/` directory
- `.env.example`

**4.3** Create environment file:
```bash
cp .env.example .env
```

**4.4** Edit the `.env` file:
```bash
nano .env
```

Update these values:
```env
# Machine IPs
MACHINE1_IP=<YOUR_MACHINE_1_IP>      # Your actual Machine 1 IP
MACHINE2_IP=172.31.11.13              # Machine 2 IP

# Database (connects to Machine 2)
POSTGRES_HOST=172.31.11.13            # Machine 2 IP
POSTGRES_PORT=5432
POSTGRES_USER=appuser
POSTGRES_PASSWORD=apppass123          # Must match Machine 2!
POSTGRES_DB=microservices_db

# Redis (connects to Machine 2)
REDIS_HOST=172.31.11.13               # Machine 2 IP
REDIS_PORT=6379

# API Endpoints
USER_API=http://localhost:8080/api/users
PRODUCT_API=http://localhost:8080/api/products
ORDER_API=http://localhost:8080/api/orders
```

Save and exit (CTRL+X, Y, Enter)

**4.5** Edit Nginx configuration:
```bash
nano nginx/nginx.conf
```

Replace `<MACHINE_1_IP>` and `<MACHINE_2_IP>` with actual IPs:

**Before:**
```nginx
upstream user_service {
    least_conn;
    server <MACHINE_1_IP>:3001;
    server <MACHINE_2_IP>:3011;
}
```

**After:**
```nginx
upstream user_service {
    least_conn;
    server 172.31.10.50:3001;    # Machine 1 IP
    server 172.31.11.13:3011;    # Machine 2 IP
}
```

Update all three upstream blocks (user_service, product_service, order_service).

Save and exit (CTRL+X, Y, Enter)

**4.6** Configure firewall:
```bash
# Allow Nginx Load Balancer
sudo ufw allow 8080/tcp

# Allow API services
sudo ufw allow 3001:3003/tcp
sudo ufw allow 3011:3013/tcp

# Allow HTTP for UI
sudo ufw allow 80/tcp

# Check status
sudo ufw status
```

**4.7** Test connectivity to Machine 2:
```bash
# Test PostgreSQL port
telnet 172.31.11.13 5432
# Press Ctrl+] then type 'quit' to exit

# Test Redis port
telnet 172.31.11.13 6379
# Press Ctrl+] then type 'quit' to exit
```

Both should connect successfully.

**4.8** Make deploy script executable:
```bash
chmod +x deploy-with-lb.sh
```

**4.9** Deploy Machine 1 services:
```bash
./deploy-with-lb.sh
```

**4.10** Wait for services to start, then verify:
```bash
docker-compose ps
```

Should see all services as "Up":
- `nginx-lb`
- `user-service`
- `product-service`
- `order-service-replica`
- `email-worker`
- `ui-service`

**4.11** Check service logs (optional):
```bash
# Check if services connected to database
docker-compose logs user-service | grep -i "connected"
docker-compose logs product-service | grep -i "connected"
docker-compose logs order-service-replica | grep -i "connected"
```

✅ **Checkpoint:** Machine 1 is fully deployed with all services running.

---

## Step 5: Configure Load Balancing

Load balancing is already configured in the nginx.conf files! Let's verify it's working.

**5.1** On Machine 1, check Nginx upstream configuration:
```bash
docker exec nginx-lb cat /etc/nginx/nginx.conf | grep -A 5 "upstream"
```

Should show upstream blocks with both machine IPs.

**5.2** On Machine 2, do the same:
```bash
docker exec nginx-lb cat /etc/nginx/nginx.conf | grep -A 5 "upstream"
```

**5.3** Check Nginx is running on both machines:
```bash
# On Machine 1
curl http://localhost:8080/health

# On Machine 2
curl http://localhost:8080/health
```

Both should return health status JSON.

✅ **Checkpoint:** Load balancing is configured and Nginx is running on both machines.

---

## Step 6: Deploy Services

Services are already deployed! Let's verify the deployment.

**6.1** Check all containers on Machine 1:
```bash
# On Machine 1
cd /tmp/microservices-demo/machine1
docker-compose ps
```

**6.2** Check all containers on Machine 2:
```bash
# On Machine 2
cd /tmp/microservices-demo/machine2
docker-compose ps
```

**6.3** Verify no containers have exited:
```bash
# On both machines
docker ps -a | grep Exit
```

Should return nothing (empty output is good).

**6.4** Check resource usage:
```bash
# On both machines
docker stats --no-stream
```

Services should be using reasonable CPU/Memory.

✅ **Checkpoint:** All services are deployed and running.

---

## Step 7: Verify Deployment

**7.1** Test User Service through Load Balancer:
```bash
# On Machine 1
curl http://localhost:8080/api/users

# On Machine 2
curl http://localhost:8080/api/users
```

Both should return JSON array (empty `[]` or with users).

**7.2** Test Product Service:
```bash
# On Machine 1
curl http://localhost:8080/api/products

# On Machine 2
curl http://localhost:8080/api/products
```

**7.3** Test Order Service:
```bash
# On Machine 1
curl http://localhost:8080/api/orders

# On Machine 2
curl http://localhost:8080/api/orders
```

**7.4** Create a test user through Machine 1:
```bash
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com"}'
```

Should return the created user with an ID.

**7.5** Verify the user appears on Machine 2:
```bash
# On Machine 2
curl http://localhost:8080/api/users
```

Should show the user you just created!

**7.6** Check background workers are running:
```bash
# On Machine 1 - Email Worker
docker-compose logs email-worker --tail=20

# On Machine 2 - Data Sync Worker
docker-compose logs data-sync-worker --tail=20
```

Data Sync Worker should show periodic sync messages.

**7.7** Check database has data:
```bash
# On Machine 2
docker-compose exec postgres psql -U appuser -d microservices_db -c "SELECT * FROM users;"
```

Should show the test user.

✅ **Checkpoint:** All services are working and communicating correctly.

---

## Step 8: Test Load Balancing

**8.1** Create the test script (on Machine 1):
```bash
cd /tmp/microservices-demo
chmod +x test-load-balancing.sh
```

**8.2** Run the load balancing test:
```bash
./test-load-balancing.sh
```

This will test:
1. Health endpoints
2. API access through load balancer
3. Service replication
4. Load distribution
5. Failover capability

**8.3** Manual load balancing test - Make multiple requests:
```bash
# On Machine 1, make 10 requests
for i in {1..10}; do
  curl -s http://localhost:8080/api/users | head -1
  echo " - Request $i"
done
```

**8.4** Check Nginx access logs to see load distribution:
```bash
# On Machine 1
docker logs nginx-lb | grep "GET /api/users" | tail -10

# On Machine 2
docker logs nginx-lb | grep "GET /api/users" | tail -10
```

You should see requests being distributed.

**8.5** Test failover - Stop a service on Machine 1:
```bash
# On Machine 1
docker-compose stop user-service
```

**8.6** Verify requests still work (served by Machine 2):
```bash
# On Machine 1
curl http://localhost:8080/api/users
```

Should still return users! (served by user-service-replica on Machine 2)

**8.7** Check Nginx detected the failure:
```bash
docker logs nginx-lb | grep "failed" | tail -5
```

**8.8** Restart the service:
```bash
# On Machine 1
docker-compose start user-service
```

**8.9** Verify it's back in rotation:
```bash
curl http://localhost:8080/api/users
docker logs nginx-lb | tail -10
```

✅ **Checkpoint:** Load balancing is working with automatic failover!

---

## Step 9: Access Your Application

**9.1** Access the Web UI:

Open a browser and go to:
- `http://<MACHINE_1_IP>` (Machine 1 IP)
- or `http://172.31.11.13` (Machine 2 IP - if UI deployed there)

**9.2** You should see a dashboard showing:
- List of Users
- List of Products
- List of Orders
- Auto-refreshing every 5 seconds

**9.3** Test creating data through UI:

The UI fetches data from APIs. To add data, use API calls:

```bash
# Create a user
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com"}'

# Create a product
curl -X POST http://localhost:8080/api/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Laptop","price":999.99,"stock":10}'

# Create an order
curl -X POST http://localhost:8080/api/orders \
  -H "Content-Type: application/json" \
  -d '{"user_id":1,"product_id":1,"quantity":1}'
```

**9.4** Refresh the browser - you should see the new data!

**9.5** Check email worker processed the order:
```bash
# On Machine 1
docker-compose logs email-worker | grep "Processing"
```

Should show email notification processing.

✅ **Checkpoint:** Application is fully functional and accessible!

---

## Step 10: Troubleshooting

### Problem: Container won't start

**Check logs:**
```bash
docker-compose logs <service-name>
```

**Common issues:**
- Port already in use: `sudo netstat -tulpn | grep <port>`
- Environment variables incorrect: Check `.env` file
- Database not ready: Wait 30 seconds and try again

### Problem: Can't connect to database

**Test connection:**
```bash
# From Machine 1
telnet 172.31.11.13 5432
```

**Solutions:**
- Check firewall: `sudo ufw status`
- Verify PostgreSQL is running: `docker-compose ps postgres`
- Check `.env` has correct POSTGRES_HOST

### Problem: API returns empty data

**Check database has tables:**
```bash
docker-compose exec postgres psql -U appuser -d microservices_db -c "\dt"
```

**If no tables:**
```bash
# Restart services to recreate tables
docker-compose restart user-service product-service order-service
```

### Problem: Load balancer returns 502 Bad Gateway

**Check backend services are running:**
```bash
docker-compose ps
```

**Check Nginx can reach backends:**
```bash
# From inside Nginx container
docker exec nginx-lb ping -c 2 <MACHINE_1_IP>
docker exec nginx-lb ping -c 2 172.31.11.13
```

**Check Nginx configuration:**
```bash
docker exec nginx-lb nginx -t
```

### Problem: Failover not working

**Verify upstream configuration:**
```bash
docker exec nginx-lb cat /etc/nginx/nginx.conf | grep -A 5 "upstream"
```

**Check health check settings:**
```nginx
server 172.31.11.13:3001 max_fails=3 fail_timeout=10s;
```

**Restart Nginx:**
```bash
docker-compose restart nginx-lb
```

### Problem: Services can't talk to each other

**Check network:**
```bash
docker network ls
docker network inspect machine1_microservices-network
```

**Check DNS resolution:**
```bash
docker-compose exec user-service ping postgres
```

### Get detailed logs

```bash
# All services
docker-compose logs

# Specific service with timestamps
docker-compose logs -f --timestamps user-service

# Last 50 lines
docker-compose logs --tail=50 nginx-lb
```

### Restart everything

**Clean restart:**
```bash
# Stop all services
docker-compose down

# Remove volumes (WARNING: deletes data)
docker-compose down -v

# Start fresh
docker-compose up -d
```

---

## 🎉 Success Checklist

Mark each item as you complete it:

- [ ] Docker installed on both machines
- [ ] Project files copied to both machines
- [ ] Machine 2 deployed with all services up
- [ ] Machine 1 deployed with all services up
- [ ] Load balancers configured with correct IPs
- [ ] Can create users through API
- [ ] Can create products through API
- [ ] Can create orders through API
- [ ] Email worker processes orders
- [ ] Data sync worker runs periodically
- [ ] Web UI accessible in browser
- [ ] Load balancing test passes
- [ ] Failover test works (stop service, still works)
- [ ] Both Nginx load balancers accessible

---

## 📊 Architecture Summary

You now have:

**Machine 1:**
- User Service (Primary) - Port 3001
- Product Service (Primary) - Port 3002
- Order Service (Replica) - Port 3013
- Email Worker (Background)
- UI Service - Port 80
- Nginx Load Balancer - Port 8080

**Machine 2:**
- User Service (Replica) - Port 3011
- Product Service (Replica) - Port 3012
- Order Service (Primary) - Port 3003
- Data Sync Worker (Background)
- PostgreSQL - Port 5432
- Redis - Port 6379
- Nginx Load Balancer - Port 8080

**Load Balancing:**
- Each API runs on BOTH machines
- Nginx on each machine distributes requests
- Automatic failover if service goes down
- Least connections algorithm

---

## 🚀 Next Steps

1. **Show your senior:**
   - Access: `http://<MACHINE_1_IP>:8080/api/users`
   - Demonstrate failover by stopping a service
   - Show both Nginx load balancers working

2. **Monitor in production:**
   - Set up log aggregation
   - Add monitoring (Prometheus/Grafana)
   - Configure alerts for service failures

3. **Enhance the setup:**
   - Add more service replicas
   - Implement database replication
   - Add SSL/TLS certificates
   - Set up automated backups

---

## 📞 Quick Reference

**Start services:**
```bash
docker-compose up -d
```

**Stop services:**
```bash
docker-compose down
```

**View logs:**
```bash
docker-compose logs -f [service-name]
```

**Restart service:**
```bash
docker-compose restart [service-name]
```

**Check status:**
```bash
docker-compose ps
```

**Run tests:**
```bash
./test-load-balancing.sh
```

---

## ✅ Final Verification Commands

Run these to verify everything is working:

```bash
# Health check
curl http://localhost:8080/health

# Get all users
curl http://localhost:8080/api/users

# Get all products
curl http://localhost:8080/api/products

# Get all orders
curl http://localhost:8080/api/orders

# Create test user
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"test@test.com"}'

# Check all containers are up
docker-compose ps | grep Up

# Check Nginx is load balancing
docker logs nginx-lb | tail -20
```

---

**🎊 Congratulations!** Your load-balanced microservices application is now running across 2 machines with high availability!

**Documentation:** See `DOCUMENTATION-INDEX.md` for all available guides.

**Questions?** Check the troubleshooting section above or review:
- `LOAD-BALANCING.md` for load balancing details
- `VISUAL-GUIDE.md` for architecture diagrams
- `TESTING.md` for comprehensive testing procedures

---

**Last Updated:** November 13, 2025  
**Version:** 2.0 with Load Balancing
