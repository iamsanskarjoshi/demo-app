# Load Balancing Setup Guide

This guide explains the high-availability load-balanced architecture implemented in this microservices demo.

## 🏗️ Architecture Overview

Each machine runs:
- **All 3 API services** (primary on one machine, replica on the other)
- **Nginx Load Balancer** (distributes traffic across both machines)
- **Background workers**
- **Shared database and Redis** (on Machine 2)

```
┌──────────────────────────────────────────────────────────────────┐
│                         MACHINE 1                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ User Service │  │Product Service│ │Order Service │          │
│  │   :3001      │  │   :3002      │  │  :3013       │          │
│  │  (Primary)   │  │  (Primary)   │  │  (Replica)   │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                  │                  │                   │
│         └──────────────────┴──────────────────┘                  │
│                            │                                      │
│                    ┌───────▼────────┐                            │
│                    │  Nginx :8080   │◄──── Client Requests       │
│                    │ Load Balancer  │                            │
│                    └────────────────┘                            │
│                                                                   │
└───────────────────────────┬───────────────────────────────────────┘
                            │ Cross-Machine Communication
┌───────────────────────────▼───────────────────────────────────────┐
│                         MACHINE 2                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ User Service │  │Product Service│ │Order Service │          │
│  │   :3011      │  │   :3012      │  │  :3003       │          │
│  │  (Replica)   │  │  (Replica)   │  │  (Primary)   │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                  │                  │                   │
│         └──────────────────┴──────────────────┘                  │
│                            │                                      │
│                    ┌───────▼────────┐                            │
│                    │  Nginx :8080   │◄──── Client Requests       │
│                    │ Load Balancer  │                            │
│                    └────────────────┘                            │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐                             │
│  │  PostgreSQL  │  │    Redis     │                             │
│  │   :5432      │  │   :6379      │                             │
│  └──────────────┘  └──────────────┘                             │
└──────────────────────────────────────────────────────────────────┘
```

## 📊 Service Distribution

### Machine 1
| Service | Port | Type |
|---------|------|------|
| User Service | 3001 | Primary |
| Product Service | 3002 | Primary |
| Order Service Replica | 3013 | Replica |
| Nginx Load Balancer | 8080 | Load Balancer |
| Email Worker | - | Background |
| UI Service | 80 | Frontend |

### Machine 2
| Service | Port | Type |
|---------|------|------|
| User Service Replica | 3011 | Replica |
| Product Service Replica | 3012 | Replica |
| Order Service | 3003 | Primary |
| Nginx Load Balancer | 8080 | Load Balancer |
| Data Sync Worker | - | Background |
| PostgreSQL | 5432 | Database |
| Redis | 6379 | Cache/Queue |

## 🔧 How Load Balancing Works

### 1. Nginx Configuration

Each Nginx instance has upstream blocks pointing to **both machines**:

```nginx
upstream user_service_backend {
    least_conn;
    server MACHINE1_IP:3001 max_fails=3 fail_timeout=10s;  # Primary
    server MACHINE2_IP:3011 max_fails=3 fail_timeout=10s;  # Replica
}
```

### 2. Load Balancing Algorithm

- **least_conn**: Routes to the server with the least active connections
- **max_fails=3**: Mark server as down after 3 failed attempts
- **fail_timeout=10s**: Retry failed server after 10 seconds

### 3. Request Flow

```
Client Request
    ↓
Nginx (either machine)
    ↓
[Load Balancing Decision]
    ↓
Route to Machine 1 OR Machine 2
    ↓
API Service processes request
    ↓
Response back to client
```

## 🚀 Deployment Steps

### Step 1: Update Nginx Configurations

**On Machine 1**, edit `machine1/nginx/nginx.conf`:
```bash
nano machine1/nginx/nginx.conf
```

Replace `172.31.11.13` with your **Machine 2's IP**:
```nginx
server 172.31.11.13:3001  # Change this
server 172.31.11.13:3002  # Change this
server 172.31.11.13:3003  # Change this
```

**On Machine 2**, edit `machine2/nginx/nginx.conf`:
```bash
nano machine2/nginx/nginx.conf
```

Replace `172.31.11.12` with your **Machine 1's IP**:
```nginx
server 172.31.11.12:3001  # Change this
server 172.31.11.12:3002  # Change this
server 172.31.11.12:3003  # Change this
```

### Step 2: Open Firewall Ports

**On both machines**:
```bash
# Open API service ports
sudo ufw allow 3001/tcp  # User Service
sudo ufw allow 3002/tcp  # Product Service
sudo ufw allow 3003/tcp  # Order Service
sudo ufw allow 3011/tcp  # User Service Replica
sudo ufw allow 3012/tcp  # Product Service Replica
sudo ufw allow 3013/tcp  # Order Service Replica
sudo ufw allow 8080/tcp  # Nginx Load Balancer

# Machine 2 only
sudo ufw allow 5432/tcp  # PostgreSQL
sudo ufw allow 6379/tcp  # Redis
```

### Step 3: Deploy with Load Balancing

**On Machine 2** (deploy first):
```bash
cd machine2
docker-compose down
docker-compose up -d --build
```

**On Machine 1**:
```bash
cd machine1
docker-compose down
docker-compose up -d --build
```

### Step 4: Verify Load Balancing

```bash
# Test through Nginx on Machine 1
for i in {1..10}; do
  curl http://MACHINE1_IP:8080/api/users
  echo ""
done

# Test through Nginx on Machine 2
for i in {1..10}; do
  curl http://MACHINE2_IP:8080/api/users
  echo ""
done
```

You should see requests distributed between both machines!

## 🧪 Testing Load Balancing

### Test 1: Check Nginx Status

```bash
# On Machine 1
curl http://localhost:8080/health
curl http://localhost:8080/nginx-status

# On Machine 2
curl http://localhost:8080/health
curl http://localhost:8080/nginx-status
```

### Test 2: Create Users Through Load Balancer

```bash
# Through Machine 1's Nginx
curl -X POST http://MACHINE1_IP:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"User from M1 LB","email":"user1@example.com","age":25}'

# Through Machine 2's Nginx
curl -X POST http://MACHINE2_IP:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"User from M2 LB","email":"user2@example.com","age":30}'
```

### Test 3: Simulate Service Failure

```bash
# Stop User Service on Machine 1
docker stop user-service

# Requests should still work through Machine 2's replica
curl http://MACHINE1_IP:8080/api/users

# Restart
docker start user-service
```

### Test 4: Load Test Script

Create `test-load-balancing.sh`:
```bash
#!/bin/bash

echo "Load Balancing Test"
echo "==================="
echo ""

MACHINE1_IP="172.31.11.12"  # Update with your IP
MACHINE2_IP="172.31.11.13"  # Update with your IP

echo "Creating 20 users through Machine 1 Nginx..."
for i in {1..20}; do
  curl -s -X POST http://${MACHINE1_IP}:8080/api/users \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"User$i\",\"email\":\"user$i@test.com\",\"age\":$((20+i))}" \
    > /dev/null
  echo -n "."
done
echo " Done!"

echo ""
echo "Creating 20 users through Machine 2 Nginx..."
for i in {21..40}; do
  curl -s -X POST http://${MACHINE2_IP}:8080/api/users \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"User$i\",\"email\":\"user$i@test.com\",\"age\":$((20+i))}" \
    > /dev/null
  echo -n "."
done
echo " Done!"

echo ""
echo "Total users created:"
curl -s http://${MACHINE1_IP}:8080/api/users | grep -o '"id"' | wc -l
```

## 📊 Monitoring Load Balancing

### Check Nginx Logs

```bash
# Machine 1
docker logs nginx-lb -f

# Machine 2
docker logs nginx-lb -f
```

### Check Service Logs

```bash
# Primary services on Machine 1
docker logs user-service -f
docker logs product-service -f

# Replica services on Machine 2
docker logs user-service-replica -f
docker logs product-service-replica -f
```

### Check Connection Distribution

```bash
# Nginx status shows active connections
curl http://localhost:8080/nginx-status
```

## 🎯 Benefits of This Setup

### 1. **High Availability**
- If one machine goes down, the other continues serving traffic
- Nginx automatically routes around failed services

### 2. **Load Distribution**
- Requests spread across both machines
- Prevents overloading a single server

### 3. **Scalability**
- Easy to add more machines
- Just update Nginx upstream configs

### 4. **Fault Tolerance**
- Automatic health checks
- Failed backends removed from rotation

### 5. **Zero Downtime Deployments**
- Update one machine at a time
- Traffic continues on the other

## 🔄 How to Scale to 3+ Machines

### Machine 3 Setup:

1. Deploy all services like Machine 1/2
2. Update Nginx on all machines:

```nginx
upstream user_service_backend {
    least_conn;
    server MACHINE1_IP:3001 max_fails=3 fail_timeout=10s;
    server MACHINE2_IP:3011 max_fails=3 fail_timeout=10s;
    server MACHINE3_IP:3021 max_fails=3 fail_timeout=10s;  # New!
}
```

3. Restart Nginx on all machines:
```bash
docker restart nginx-lb
```

## 🚨 Troubleshooting

### Problem: Nginx returns 502 Bad Gateway

**Check:**
```bash
# Verify backend services are running
docker ps

# Test backend directly
curl http://localhost:3001/api/users

# Check Nginx logs
docker logs nginx-lb
```

**Fix:**
```bash
# Restart services
docker-compose restart user-service
docker restart nginx-lb
```

### Problem: Requests only go to one machine

**Check:**
```bash
# Verify Nginx config has both upstreams
docker exec nginx-lb cat /etc/nginx/nginx.conf

# Check if other machine is reachable
curl http://OTHER_MACHINE_IP:3001/api/users
```

**Fix:**
- Verify firewall rules
- Check IP addresses in nginx.conf
- Restart Nginx

### Problem: One backend always fails

**Check logs:**
```bash
docker logs [service-name]
```

**Common causes:**
- Database connection issues
- Wrong environment variables
- Port conflicts

## 📈 Advanced Configuration

### Session Persistence (Sticky Sessions)

If needed, enable IP-based session stickiness:

```nginx
upstream user_service_backend {
    ip_hash;  # Same client IP always goes to same server
    server MACHINE1_IP:3001;
    server MACHINE2_IP:3011;
}
```

### Weighted Load Balancing

Give more traffic to more powerful machines:

```nginx
upstream user_service_backend {
    server MACHINE1_IP:3001 weight=3;  # Gets 75% of traffic
    server MACHINE2_IP:3011 weight=1;  # Gets 25% of traffic
}
```

### Health Check Intervals

Adjust health check behavior:

```nginx
server MACHINE1_IP:3001 max_fails=2 fail_timeout=5s;  # More sensitive
```

## ✅ Verification Checklist

- [ ] Nginx running on both machines (port 8080)
- [ ] All API services running on both machines
- [ ] Nginx configs have correct IP addresses
- [ ] Firewall ports open on both machines
- [ ] Requests distributed between machines
- [ ] Failover works when service stops
- [ ] Both Nginx instances can route to all backends
- [ ] Health checks passing

## 🎓 Key Concepts Learned

1. **Upstream blocks** - Define backend server pools
2. **Load balancing algorithms** - least_conn, round_robin, ip_hash
3. **Health checks** - Automatic failure detection
4. **Fault tolerance** - Graceful degradation
5. **Horizontal scaling** - Add capacity by adding machines
6. **High availability** - No single point of failure

---

**Your application now has enterprise-grade load balancing and high availability!** 🚀
