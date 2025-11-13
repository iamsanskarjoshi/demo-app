# 🎯 Load Balancing Setup - Visual Guide

## Before vs After

### ❌ BEFORE (Original Setup)
```
┌─────────────────────────┐
│      MACHINE 1          │
│                         │
│  User API :3001         │
│  Product API :3002      │
│  Email Worker           │
│  UI :80                 │
│                         │
└─────────────────────────┘
            │
            │ Single connection
            ↓
┌─────────────────────────┐
│      MACHINE 2          │
│                         │
│  Order API :3003        │
│  PostgreSQL :5432       │
│  Redis :6379            │
│  Data Sync Worker       │
│                         │
└─────────────────────────┘

Problems:
❌ No redundancy
❌ No load distribution  
❌ Single point of failure
❌ M1 goes down = User/Product APIs unavailable
❌ M2 goes down = Order API + Database unavailable
```

### ✅ AFTER (With Load Balancing)
```
         Client Requests
              │
              ↓
    ┌─────────────────────┐
    │   Can hit either    │
    │   load balancer!    │
    └─────────────────────┘
         │           │
         ↓           ↓
┌──────────────┐ ┌──────────────┐
│  MACHINE 1   │ │  MACHINE 2   │
│              │ │              │
│  Nginx :8080 ├─┤  Nginx :8080 │
│  (LB)        │ │  (LB)        │
└──────┬───────┘ └───────┬──────┘
       │                 │
       ↓                 ↓
  ┌─────────┐       ┌─────────┐
  │ User    │◄─────►│ User    │
  │ :3001   │       │ :3011   │
  │(Primary)│       │(Replica)│
  └─────────┘       └─────────┘
  
  ┌─────────┐       ┌─────────┐
  │ Product │◄─────►│ Product │
  │ :3002   │       │ :3012   │
  │(Primary)│       │(Replica)│
  └─────────┘       └─────────┘
  
  ┌─────────┐       ┌─────────┐
  │ Order   │◄─────►│ Order   │
  │ :3013   │       │ :3003   │
  │(Replica)│       │(Primary)│
  └─────────┘       └─────────┘

Benefits:
✅ High Availability
✅ Load Distribution
✅ Automatic Failover
✅ Any machine can serve requests
✅ Services continue if one machine fails
```

## Request Flow Example

### Scenario: User creates an order

```
1. Client Request
   │
   └──► http://MACHINE1_IP:8080/api/orders
        (Or http://MACHINE2_IP:8080/api/orders)
        │
        ↓
2. Nginx Load Balancer (on either machine)
   │
   ├──► Checks: Which backend has fewer connections?
   │     - Machine 1 Order Service :3013 (2 connections)
   │     - Machine 2 Order Service :3003 (1 connection)
   │
   └──► Routes to: Machine 2 :3003 ✓
        │
        ↓
3. Order Service on Machine 2
   │
   ├──► Saves order to PostgreSQL
   │     └──► Success ✓
   │
   └──► Pushes notification to Redis queue
        └──► Success ✓
        │
        ↓
4. Response back to client
   │
   └──► HTTP 201 Created
        {"id": 123, "status": "pending", ...}

5. Email Worker (Machine 1)
   │
   └──► Picks up notification from Redis
        └──► Sends email ✓
```

## Failover Example

### Scenario: Machine 1's User Service crashes

```
BEFORE CRASH:
Client → Nginx (M1) → User Service (M1) ✓
Client → Nginx (M2) → User Service (M1) ✓

AFTER M1 User Service CRASHES:
┌────────────────────────────────────┐
│  Nginx detects failure             │
│  (max_fails=3, fail_timeout=10s)   │
└────────────────────────────────────┘
         │
         ↓
Client → Nginx (M1) → User Service (M2) ✓
                      (Automatic!)
         │
         ↓
Client → Nginx (M2) → User Service (M2) ✓
                      (Already using it)

Result: ZERO DOWNTIME! 🎉
```

## Port Map - Complete View

```
┌──────────────────────────────────────────────────────────────┐
│                        MACHINE 1                             │
├──────────────────────────────────────────────────────────────┤
│ Service             │ Port │ Type      │ Accessible From     │
├──────────────────────────────────────────────────────────────┤
│ User Service        │ 3001 │ Primary   │ Both machines       │
│ Product Service     │ 3002 │ Primary   │ Both machines       │
│ Order Service       │ 3013 │ Replica   │ Both machines       │
│ Nginx Load Balancer │ 8080 │ LB        │ External + Internal │
│ UI Service          │  80  │ Frontend  │ External            │
│ Email Worker        │  -   │ Worker    │ N/A                 │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                        MACHINE 2                             │
├──────────────────────────────────────────────────────────────┤
│ Service             │ Port │ Type      │ Accessible From     │
├──────────────────────────────────────────────────────────────┤
│ User Service        │ 3011 │ Replica   │ Both machines       │
│ Product Service     │ 3012 │ Replica   │ Both machines       │
│ Order Service       │ 3003 │ Primary   │ Both machines       │
│ Nginx Load Balancer │ 8080 │ LB        │ External + Internal │
│ PostgreSQL          │ 5432 │ Database  │ Both machines       │
│ Redis               │ 6379 │ Queue     │ Both machines       │
│ Data Sync Worker    │  -   │ Worker    │ N/A                 │
└──────────────────────────────────────────────────────────────┘
```

## Access Patterns

### ❌ OLD WAY (Direct Access)
```bash
# Had to know which machine has which service
curl http://machine1:3001/api/users     # User on M1 only
curl http://machine1:3002/api/products  # Product on M1 only  
curl http://machine2:3003/api/orders    # Order on M2 only

# Problem: Services locked to specific machines
```

### ✅ NEW WAY (Through Load Balancer)
```bash
# Access ANY service through ANY machine!
curl http://machine1:8080/api/users     # Works!
curl http://machine1:8080/api/products  # Works!
curl http://machine1:8080/api/orders    # Works!

curl http://machine2:8080/api/users     # Also works!
curl http://machine2:8080/api/products  # Also works!
curl http://machine2:8080/api/orders    # Also works!

# Benefit: True high availability!
```

## Load Distribution Example

```
10 Requests to User Service:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Request 1  →  Nginx  →  Machine 1 (fewer connections)
Request 2  →  Nginx  →  Machine 2 (fewer connections)
Request 3  →  Nginx  →  Machine 1 (fewer connections)
Request 4  →  Nginx  →  Machine 2 (fewer connections)
Request 5  →  Nginx  →  Machine 1 (fewer connections)
Request 6  →  Nginx  →  Machine 2 (fewer connections)
Request 7  →  Nginx  →  Machine 1 (fewer connections)
Request 8  →  Nginx  →  Machine 2 (fewer connections)
Request 9  →  Nginx  →  Machine 1 (fewer connections)
Request 10 →  Nginx  →  Machine 2 (fewer connections)

Result: 50/50 distribution! ⚖️
(Algorithm: least_conn ensures balanced load)
```

## Health Check Flow

```
Every 10 seconds, Nginx checks each backend:

┌─────────────────────────────────────┐
│  Health Check Cycle                 │
└─────────────────────────────────────┘
         │
         ↓
Check Machine 1 User Service :3001
  └──► Success? ✓ → Keep in rotation
       Failure? ✗ → Mark as down, retry in 10s

Check Machine 2 User Service :3011
  └──► Success? ✓ → Keep in rotation
       Failure? ✗ → Mark as down, retry in 10s

(Repeat for all services...)

If backend fails 3 times consecutively:
  → Remove from rotation
  → Route traffic to healthy backend
  → Retry every 10 seconds
  → Add back when healthy
```

## Configuration Snippet Explained

```nginx
upstream user_service_backend {
    least_conn;           # Algorithm: route to least busy
    
    server 172.31.11.13:3001    # Machine 2's User Service
           max_fails=3          # Fail after 3 attempts
           fail_timeout=10s;    # Retry after 10 seconds
    
    server 127.0.0.1:3011       # Local User Service
           max_fails=3
           fail_timeout=10s;
}
```

## Deployment Checklist

```
MACHINE 2 (Deploy First):
├─ [ ] Update nginx/nginx.conf with Machine 1 IP
├─ [ ] Open firewall ports (3003, 3011, 3012, 8080, 5432, 6379)
├─ [ ] Run: ./deploy-with-lb.sh
├─ [ ] Verify: curl http://localhost:8080/health
└─ [ ] Check: docker-compose ps (all should be Up)

MACHINE 1 (Deploy Second):
├─ [ ] Update .env with MACHINE2_IP
├─ [ ] Update nginx/nginx.conf with Machine 2 IP
├─ [ ] Open firewall ports (3001, 3002, 3013, 8080, 80)
├─ [ ] Run: ./deploy-with-lb.sh
├─ [ ] Verify: curl http://localhost:8080/health
└─ [ ] Check: docker-compose ps (all should be Up)

TESTING:
├─ [ ] Run: ./test-load-balancing.sh
├─ [ ] Create data through both load balancers
├─ [ ] Stop a service, verify failover works
├─ [ ] Check nginx status: curl localhost:8080/nginx-status
└─ [ ] Monitor logs: docker logs nginx-lb -f
```

## Troubleshooting Visual Guide

```
Problem: Nginx returns 502 Bad Gateway
         │
         ↓
    Check backend services
         │
    ┌────┴────┐
    │         │
    ↓         ↓
  Running?  Healthy?
    │         │
   No        No
    │         │
    ↓         ↓
  Start    Check logs
  Service  Fix issue
    │         │
    └────┬────┘
         │
         ↓
   Restart Nginx
         │
         ↓
      Test again


Problem: Requests only go to one machine
         │
         ↓
    Check Nginx upstream config
         │
    ┌────┴────┐
    │         │
    ↓         ↓
  Correct   Firewall
   IPs?      open?
    │         │
   No        No
    │         │
    ↓         ↓
  Update    Open ports
  Config    sudo ufw
    │         │
    └────┬────┘
         │
         ↓
   Restart Nginx
         │
         ↓
   Test connectivity
```

## Success Indicators

```
✅ All services show "Up" in docker-compose ps
✅ curl http://localhost:8080/health returns 200
✅ curl http://localhost:8080/nginx-status shows stats
✅ Can create/read data through both load balancers
✅ Data is consistent regardless of which LB used
✅ Stopping a service doesn't break API calls
✅ Nginx logs show distribution to both machines
✅ test-load-balancing.sh passes all tests
```

## Quick Commands Reference

```bash
# Check everything is running
docker-compose ps

# View load balancer logs
docker logs nginx-lb -f

# Test health
curl http://localhost:8080/health

# Check Nginx status
curl http://localhost:8080/nginx-status

# Test API through LB
curl http://localhost:8080/api/users

# Create data through LB
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"test@example.com","age":25}'

# Simulate failure (test failover)
docker stop user-service
curl http://localhost:8080/api/users  # Still works!
docker start user-service

# Full load balancing test
./test-load-balancing.sh
```

---

**Your setup now matches exactly what your senior requested!** 🎉

Every machine runs Nginx, services are replicated, and load is distributed automatically with failover support!
