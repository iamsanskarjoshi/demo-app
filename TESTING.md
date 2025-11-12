# Step-by-Step Testing Guide

This guide will walk you through testing the entire microservices application.

## Prerequisites

- Both machines are running and accessible
- Docker containers are running on both machines
- You have `curl` installed for API testing

## Step 1: Verify All Services Are Running

### On Machine 1:
```bash
cd machine1
docker-compose ps
```

Expected output: All services should show "Up" status
- user-service
- product-service
- email-worker
- ui-service

### On Machine 2:
```bash
cd machine2
docker-compose ps
```

Expected output: All services should show "Up" status
- order-service
- data-sync-worker
- postgres
- redis

## Step 2: Test User Service API (Machine 1)

Replace `MACHINE1_IP` with Machine 1's IP address.

### Create a user:
```bash
curl -X POST http://MACHINE1_IP:3001/api/users \
  -H "Content-Type: application/json" \
  -d '{"name": "John Doe", "email": "john@example.com", "age": 30}'
```

Expected: `{"id": 1, "name": "John Doe", "email": "john@example.com", "age": 30}`

### Get all users:
```bash
curl http://MACHINE1_IP:3001/api/users
```

### Get user by ID:
```bash
curl http://MACHINE1_IP:3001/api/users/1
```

### Update user:
```bash
curl -X PUT http://MACHINE1_IP:3001/api/users/1 \
  -H "Content-Type: application/json" \
  -d '{"name": "John Smith", "email": "john.smith@example.com", "age": 31}'
```

## Step 3: Test Product Service API (Machine 1)

### Create a product:
```bash
curl -X POST http://MACHINE1_IP:3002/api/products \
  -H "Content-Type: application/json" \
  -d '{"name": "Laptop", "description": "High-performance laptop", "price": 999.99, "stock": 10}'
```

Expected: `{"id": 1, "name": "Laptop", ...}`

### Get all products:
```bash
curl http://MACHINE1_IP:3002/api/products
```

### Create more products:
```bash
curl -X POST http://MACHINE1_IP:3002/api/products \
  -H "Content-Type: application/json" \
  -d '{"name": "Mouse", "description": "Wireless mouse", "price": 29.99, "stock": 50}'

curl -X POST http://MACHINE1_IP:3002/api/products \
  -H "Content-Type: application/json" \
  -d '{"name": "Keyboard", "description": "Mechanical keyboard", "price": 79.99, "stock": 25}'
```

## Step 4: Test Order Service API (Machine 2)

Replace `MACHINE2_IP` with Machine 2's IP address.

### Create an order (this will trigger email worker):
```bash
curl -X POST http://MACHINE2_IP:3003/api/orders \
  -H "Content-Type: application/json" \
  -d '{"userId": 1, "productId": 1, "quantity": 2, "totalAmount": 1999.98}'
```

Expected: `{"id": 1, "userId": 1, "productId": 1, "quantity": 2, "totalAmount": 1999.98, "status": "pending"}`

### Get all orders:
```bash
curl http://MACHINE2_IP:3003/api/orders
```

### Update order status:
```bash
curl -X PUT http://MACHINE2_IP:3003/api/orders/1 \
  -H "Content-Type: application/json" \
  -d '{"status": "completed"}'
```

## Step 5: Verify Email Worker (Machine 1)

Check the email worker logs to see if it processed the order notification:

```bash
cd machine1
docker-compose logs email-worker
```

You should see log messages like:
```
Email Worker: Processing job...
Sending email notification for order #1
Email sent successfully!
```

## Step 6: Verify Data Sync Worker (Machine 2)

Check the data sync worker logs:

```bash
cd machine2
docker-compose logs data-sync-worker
```

You should see periodic sync messages:
```
Data Sync Worker: Running sync...
Synced X records from services
Next sync in 30 seconds
```

## Step 7: Test UI Service (Machine 1)

Open a web browser and navigate to:
```
http://MACHINE1_IP
```

You should see:
1. A dashboard showing summary statistics
2. Sections for Users, Products, and Orders
3. The data you created in previous steps
4. Ability to create new users and products through the UI

### UI Functionality Test:
1. Click "Add User" button and create a new user via the form
2. Click "Add Product" button and create a new product
3. View the orders list (fetched from Machine 2)
4. Verify real-time updates (the UI polls APIs every 5 seconds)

## Step 8: Cross-Machine Communication Test

This tests that services on Machine 1 can communicate with Machine 2.

### From Machine 1, test connectivity to Machine 2:
```bash
# Test Order Service connectivity
curl http://MACHINE2_IP:3003/api/orders

# Test from inside UI container
docker exec -it ui-service curl http://MACHINE2_IP:3003/api/orders
```

## Step 9: Database Persistence Test

### Stop and restart services:
```bash
# On Machine 2
cd machine2
docker-compose down
docker-compose up -d

# Wait 10 seconds for services to start
sleep 10

# Check if data persists
curl http://MACHINE2_IP:3003/api/orders
```

Expected: You should still see all previously created orders.

## Step 10: Load Test (Optional)

Create multiple orders rapidly to test the email worker queue:

```bash
for i in {1..10}; do
  curl -X POST http://MACHINE2_IP:3003/api/orders \
    -H "Content-Type: application/json" \
    -d "{\"userId\": 1, \"productId\": 1, \"quantity\": $i, \"totalAmount\": $((i * 999))}"
  sleep 1
done
```

Then check email worker logs:
```bash
cd machine1
docker-compose logs -f email-worker
```

You should see it processing all 10 orders.

## Step 11: Health Checks

All services expose health check endpoints:

```bash
# Machine 1
curl http://MACHINE1_IP:3001/health  # User Service
curl http://MACHINE1_IP:3002/health  # Product Service

# Machine 2
curl http://MACHINE2_IP:3003/health  # Order Service
```

Expected: `{"status": "healthy", "timestamp": "..."}`

## Step 12: Performance Monitoring

### Check resource usage:
```bash
# On each machine
docker stats
```

### Check network connections:
```bash
# On Machine 2
docker-compose exec postgres psql -U postgres -d microservices -c "SELECT COUNT(*) FROM orders;"
docker-compose exec redis redis-cli -a redis123 INFO
```

## Troubleshooting Common Issues

### Issue: Cannot connect to Machine 2 from Machine 1
**Solution:**
```bash
# On Machine 2, check firewall
sudo ufw status
sudo ufw allow 3003/tcp
sudo ufw allow 5432/tcp
sudo ufw allow 6379/tcp
```

### Issue: Services not starting
**Solution:**
```bash
# Check logs
docker-compose logs [service-name]

# Restart service
docker-compose restart [service-name]
```

### Issue: Database connection errors
**Solution:**
```bash
# On Machine 2, restart postgres
docker-compose restart postgres

# Wait for it to be ready
docker-compose logs -f postgres
```

### Issue: Redis connection errors
**Solution:**
```bash
# On Machine 2, check Redis
docker-compose exec redis redis-cli -a redis123 PING
```

## Success Criteria

✅ All services show "Up" status in docker-compose ps
✅ User Service can create, read, update users
✅ Product Service can create, read, update products
✅ Order Service can create, read, update orders
✅ Email Worker processes order notifications
✅ Data Sync Worker runs periodic syncs
✅ UI displays all data correctly
✅ Cross-machine communication works
✅ Data persists after restart

## Next Steps

- Monitor logs regularly: `docker-compose logs -f`
- Set up proper monitoring (Prometheus/Grafana)
- Configure backup strategy for PostgreSQL
- Implement proper authentication/authorization
- Set up HTTPS with SSL certificates
- Configure production-grade logging
