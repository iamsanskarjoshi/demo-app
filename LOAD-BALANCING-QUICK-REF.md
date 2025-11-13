# Load Balancing Quick Reference

## 🎯 What Changed?

Your microservices demo now includes **enterprise-grade load balancing**:

### Before (Original Setup)
```
Machine 1: User API, Product API, Email Worker, UI
Machine 2: Order API, Database, Redis, Data Sync Worker
```

### After (With Load Balancing)
```
Machine 1: User API (Primary), Product API (Primary), Order API (Replica)
          + Nginx Load Balancer + Email Worker + UI
          
Machine 2: User API (Replica), Product API (Replica), Order API (Primary)
          + Nginx Load Balancer + Database + Redis + Data Sync Worker
```

## 🚀 Key Changes

1. **All API services now run on BOTH machines**
   - One as primary, one as replica
   - Provides redundancy and high availability

2. **Nginx Load Balancer on each machine**
   - Port 8080
   - Distributes traffic across both machines
   - Automatic failover if one service goes down

3. **Health checks and auto-recovery**
   - Failed backends automatically removed
   - Automatic retry after 10 seconds

## 📡 How to Use

### Access APIs Through Load Balancer (Recommended)

Instead of:
```bash
curl http://MACHINE1_IP:3001/api/users  # Direct access
```

Use:
```bash
curl http://MACHINE1_IP:8080/api/users  # Through load balancer
# OR
curl http://MACHINE2_IP:8080/api/users  # Either machine works!
```

### Benefits

✅ **High Availability** - If Machine 1 fails, Machine 2 continues serving
✅ **Load Distribution** - Requests spread across both machines
✅ **Better Performance** - No single bottleneck
✅ **Automatic Failover** - Nginx detects and routes around failures
✅ **Zero Downtime** - Update one machine while other serves traffic

## 🔧 Configuration Files

### Nginx Config Location
- Machine 1: `machine1/nginx/nginx.conf`
- Machine 2: `machine2/nginx/nginx.conf`

### Important: Update IPs

**Before deploying**, edit both nginx.conf files and replace example IPs with your actual IPs:

```nginx
# In machine1/nginx/nginx.conf
server 172.31.11.13:3001  # ← Change to your Machine 2 IP

# In machine2/nginx/nginx.conf
server 172.31.11.12:3001  # ← Change to your Machine 1 IP
```

## 🎬 Deployment Steps

### 1. Update Nginx Configs (Both Machines)
```bash
# Edit and set correct IPs
nano machine1/nginx/nginx.conf
nano machine2/nginx/nginx.conf
```

### 2. Open Firewall Ports (Both Machines)
```bash
sudo ufw allow 3001/tcp  # User Service
sudo ufw allow 3002/tcp  # Product Service
sudo ufw allow 3003/tcp  # Order Service
sudo ufw allow 3011/tcp  # User Service Replica
sudo ufw allow 3012/tcp  # Product Service Replica
sudo ufw allow 3013/tcp  # Order Service Replica
sudo ufw allow 8080/tcp  # Nginx Load Balancer
```

### 3. Deploy (Machine 2 First)
```bash
# On Machine 2
cd machine2
docker-compose down
docker-compose up -d --build

# On Machine 1
cd machine1
docker-compose down
docker-compose up -d --build
```

### 4. Test Load Balancing
```bash
chmod +x test-load-balancing.sh
export MACHINE1_IP=your_machine1_ip
export MACHINE2_IP=your_machine2_ip
./test-load-balancing.sh
```

## 🧪 Testing Commands

### Check Nginx Status
```bash
curl http://localhost:8080/health
curl http://localhost:8080/nginx-status
```

### Test Load Distribution
```bash
# Create users through both load balancers
for i in {1..10}; do
  curl -X POST http://MACHINE1_IP:8080/api/users \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"User$i\",\"email\":\"user$i@test.com\",\"age\":$((20+i))}"
done
```

### Verify Failover
```bash
# Stop a service on Machine 1
docker stop user-service

# Requests should still work through Machine 2's replica
curl http://MACHINE1_IP:8080/api/users  # Still works!

# Restart
docker start user-service
```

## 📊 Port Map

| Service | Machine 1 | Machine 2 | Purpose |
|---------|-----------|-----------|---------|
| User Service | 3001 (Primary) | 3011 (Replica) | User management |
| Product Service | 3002 (Primary) | 3012 (Replica) | Product management |
| Order Service | 3013 (Replica) | 3003 (Primary) | Order management |
| Nginx LB | 8080 | 8080 | Load balancer |
| PostgreSQL | - | 5432 | Database |
| Redis | - | 6379 | Message queue |
| UI | 80 | - | Frontend |

## 🔍 Monitoring

### View Nginx Logs
```bash
docker logs nginx-lb -f
```

### View Service Logs
```bash
# Primary services
docker logs user-service -f
docker logs product-service -f

# Replica services
docker logs user-service-replica -f
docker logs product-service-replica -f
```

### Check All Services
```bash
docker-compose ps
```

## 🚨 Troubleshooting

### Nginx returns 502 Bad Gateway
```bash
# Check if backend services are running
docker ps | grep service

# Test backend directly
curl http://localhost:3001/api/users

# Check Nginx config
docker exec nginx-lb cat /etc/nginx/nginx.conf

# Restart Nginx
docker restart nginx-lb
```

### Requests only go to one machine
```bash
# Verify other machine is reachable
curl http://OTHER_MACHINE_IP:3001/api/users

# Check firewall
sudo ufw status

# Verify IPs in nginx.conf
docker exec nginx-lb cat /etc/nginx/nginx.conf | grep server
```

## 📈 Load Balancing Algorithms

Current setup uses **least_conn** (least connections):
- Routes to server with fewest active connections
- Best for long-lived connections

Other options (edit nginx.conf):
- `round_robin` - Default, alternates between servers
- `ip_hash` - Same client always goes to same server (sticky sessions)
- `weight=N` - Give more traffic to specific servers

## 🎓 What You've Achieved

✅ **High Availability Architecture** - No single point of failure
✅ **Load Balancing** - Traffic distributed across multiple servers
✅ **Fault Tolerance** - Automatic failover on service failure
✅ **Horizontal Scalability** - Easy to add more machines
✅ **Production-Ready** - Enterprise-grade setup

## 📚 Full Documentation

- [LOAD-BALANCING.md](./LOAD-BALANCING.md) - Complete guide
- [README.md](./README.md) - Main documentation
- [TESTING.md](./TESTING.md) - Testing procedures

## 💡 Pro Tips

1. **Always access through load balancer** (port 8080) for best availability
2. **Monitor nginx-status** regularly to check backend health
3. **Update one machine at a time** for zero-downtime deployments
4. **Test failover** regularly to ensure it works when needed
5. **Scale by adding machines** - just update nginx.conf on all nodes

---

**Your microservices are now highly available and load-balanced!** 🎉
