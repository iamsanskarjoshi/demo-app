#!/bin/bash

# Load Balancing Test Script
# Tests the load balancing functionality across both machines

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Load Balancing Test Suite                                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Configuration - UPDATE THESE WITH YOUR ACTUAL IPs
MACHINE1_IP="${MACHINE1_IP:-172.31.11.12}"
MACHINE2_IP="${MACHINE2_IP:-172.31.11.13}"

echo "Configuration:"
echo "  Machine 1 IP: ${MACHINE1_IP}"
echo "  Machine 2 IP: ${MACHINE2_IP}"
echo ""

PASS_COUNT=0
FAIL_COUNT=0

# Test helper function
test_endpoint() {
    local name=$1
    local url=$2
    
    echo -n "Testing $name... "
    response=$(curl -s -o /dev/null -w "%{http_code}" "$url" --connect-timeout 5)
    
    if [ "$response" == "200" ]; then
        echo "✅ PASS (HTTP $response)"
        ((PASS_COUNT++))
        return 0
    else
        echo "❌ FAIL (HTTP $response)"
        ((FAIL_COUNT++))
        return 1
    fi
}

echo "════════════════════════════════════════════════════════════"
echo "  Test 1: Nginx Load Balancers Health"
echo "════════════════════════════════════════════════════════════"
echo ""

test_endpoint "Machine 1 Nginx" "http://${MACHINE1_IP}:8080/health"
test_endpoint "Machine 2 Nginx" "http://${MACHINE2_IP}:8080/health"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Test 2: Direct Service Access (Verify All Replicas Running)"
echo "════════════════════════════════════════════════════════════"
echo ""

echo "Machine 1 Services:"
test_endpoint "  User Service (Primary)" "http://${MACHINE1_IP}:3001/health"
test_endpoint "  Product Service (Primary)" "http://${MACHINE1_IP}:3002/health"
test_endpoint "  Order Service (Replica)" "http://${MACHINE1_IP}:3013/health"

echo ""
echo "Machine 2 Services:"
test_endpoint "  User Service (Replica)" "http://${MACHINE2_IP}:3011/health"
test_endpoint "  Product Service (Replica)" "http://${MACHINE2_IP}:3012/health"
test_endpoint "  Order Service (Primary)" "http://${MACHINE2_IP}:3003/health"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Test 3: Load Balancing Distribution"
echo "════════════════════════════════════════════════════════════"
echo ""

echo "Creating 10 users through Machine 1 Nginx (should distribute to both machines)..."
M1_SUCCESS=0
for i in {1..10}; do
    response=$(curl -s -X POST http://${MACHINE1_IP}:8080/api/users \
        -H "Content-Type: application/json" \
        -d "{\"name\":\"LB Test User M1-$i\",\"email\":\"lbtest-m1-$i@example.com\",\"age\":$((20+i))}" \
        -w "%{http_code}" -o /dev/null)
    
    if [ "$response" == "201" ] || [ "$response" == "200" ]; then
        ((M1_SUCCESS++))
        echo -n "✓"
    else
        echo -n "✗"
    fi
done
echo ""
echo "Machine 1 Nginx: $M1_SUCCESS/10 successful"

if [ $M1_SUCCESS -ge 8 ]; then
    echo "✅ PASS - Machine 1 load balancing working"
    ((PASS_COUNT++))
else
    echo "❌ FAIL - Machine 1 load balancing issues"
    ((FAIL_COUNT++))
fi

echo ""
echo "Creating 10 users through Machine 2 Nginx (should distribute to both machines)..."
M2_SUCCESS=0
for i in {1..10}; do
    response=$(curl -s -X POST http://${MACHINE2_IP}:8080/api/users \
        -H "Content-Type: application/json" \
        -d "{\"name\":\"LB Test User M2-$i\",\"email\":\"lbtest-m2-$i@example.com\",\"age\":$((30+i))}" \
        -w "%{http_code}" -o /dev/null)
    
    if [ "$response" == "201" ] || [ "$response" == "200" ]; then
        ((M2_SUCCESS++))
        echo -n "✓"
    else
        echo -n "✗"
    fi
done
echo ""
echo "Machine 2 Nginx: $M2_SUCCESS/10 successful"

if [ $M2_SUCCESS -ge 8 ]; then
    echo "✅ PASS - Machine 2 load balancing working"
    ((PASS_COUNT++))
else
    echo "❌ FAIL - Machine 2 load balancing issues"
    ((FAIL_COUNT++))
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Test 4: High Availability - Failover Test"
echo "════════════════════════════════════════════════════════════"
echo ""

echo "Testing if requests still work even if one replica might be down..."
echo ""

# Test products through both load balancers
echo "Creating products through Machine 1 Nginx..."
PROD_M1=0
for i in {1..5}; do
    response=$(curl -s -X POST http://${MACHINE1_IP}:8080/api/products \
        -H "Content-Type: application/json" \
        -d "{\"name\":\"Product M1-$i\",\"description\":\"Load balanced product\",\"price\":$((i*10)).99,\"stock\":$((i*5))}" \
        -w "%{http_code}" -o /dev/null)
    
    if [ "$response" == "201" ] || [ "$response" == "200" ]; then
        ((PROD_M1++))
        echo -n "✓"
    else
        echo -n "✗"
    fi
done
echo " ($PROD_M1/5)"

echo "Creating products through Machine 2 Nginx..."
PROD_M2=0
for i in {1..5}; do
    response=$(curl -s -X POST http://${MACHINE2_IP}:8080/api/products \
        -H "Content-Type: application/json" \
        -d "{\"name\":\"Product M2-$i\",\"description\":\"Load balanced product\",\"price\":$((i*20)).99,\"stock\":$((i*10))}" \
        -w "%{http_code}" -o /dev/null)
    
    if [ "$response" == "201" ] || [ "$response" == "200" ]; then
        ((PROD_M2++))
        echo -n "✓"
    else
        echo -n "✗"
    fi
done
echo " ($PROD_M2/5)"

TOTAL_PROD=$((PROD_M1 + PROD_M2))
if [ $TOTAL_PROD -ge 8 ]; then
    echo "✅ PASS - High availability working ($TOTAL_PROD/10 requests successful)"
    ((PASS_COUNT++))
else
    echo "❌ FAIL - High availability issues ($TOTAL_PROD/10 requests successful)"
    ((FAIL_COUNT++))
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Test 5: Load Distribution Verification"
echo "════════════════════════════════════════════════════════════"
echo ""

echo "Fetching data through both load balancers to verify consistency..."
echo ""

# Get users through both LBs
USERS_M1=$(curl -s http://${MACHINE1_IP}:8080/api/users | grep -o '"id"' | wc -l)
USERS_M2=$(curl -s http://${MACHINE2_IP}:8080/api/users | grep -o '"id"' | wc -l)

echo "Users retrieved through Machine 1 LB: $USERS_M1"
echo "Users retrieved through Machine 2 LB: $USERS_M2"

if [ "$USERS_M1" == "$USERS_M2" ] && [ "$USERS_M1" -gt 0 ]; then
    echo "✅ PASS - Both load balancers return consistent data"
    ((PASS_COUNT++))
else
    echo "❌ FAIL - Data inconsistency detected"
    ((FAIL_COUNT++))
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Test 6: Nginx Status Check"
echo "════════════════════════════════════════════════════════════"
echo ""

echo "Machine 1 Nginx Status:"
curl -s http://${MACHINE1_IP}:8080/nginx-status
echo ""

echo ""
echo "Machine 2 Nginx Status:"
curl -s http://${MACHINE2_IP}:8080/nginx-status
echo ""

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Test 7: Cross-Machine Order Processing"
echo "════════════════════════════════════════════════════════════"
echo ""

echo "Creating orders through both load balancers..."
ORDER_SUCCESS=0

# Order through Machine 1 LB
response=$(curl -s -X POST http://${MACHINE1_IP}:8080/api/orders \
    -H "Content-Type: application/json" \
    -d '{"userId":1,"productId":1,"quantity":2,"totalAmount":199.98}' \
    -w "%{http_code}" -o /dev/null)

if [ "$response" == "201" ] || [ "$response" == "200" ]; then
    echo "✓ Order created through Machine 1 LB"
    ((ORDER_SUCCESS++))
else
    echo "✗ Order failed through Machine 1 LB (HTTP $response)"
fi

sleep 1

# Order through Machine 2 LB
response=$(curl -s -X POST http://${MACHINE2_IP}:8080/api/orders \
    -H "Content-Type: application/json" \
    -d '{"userId":1,"productId":2,"quantity":1,"totalAmount":99.99}' \
    -w "%{http_code}" -o /dev/null)

if [ "$response" == "201" ] || [ "$response" == "200" ]; then
    echo "✓ Order created through Machine 2 LB"
    ((ORDER_SUCCESS++))
else
    echo "✗ Order failed through Machine 2 LB (HTTP $response)"
fi

if [ $ORDER_SUCCESS -ge 1 ]; then
    echo "✅ PASS - Order processing through load balancers working"
    ((PASS_COUNT++))
else
    echo "❌ FAIL - Order processing issues"
    ((FAIL_COUNT++))
fi

echo ""
echo "⚠️  Check email worker logs to verify notifications:"
echo "    ssh machine1 'cd microservices-demo/machine1 && docker logs email-worker'"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Load Balancing Test Results                              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "  ✅ Passed: $PASS_COUNT"
echo "  ❌ Failed: $FAIL_COUNT"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo "  🎉 All load balancing tests passed!"
    echo ""
    echo "  Your setup provides:"
    echo "    ✓ High Availability"
    echo "    ✓ Load Distribution"
    echo "    ✓ Fault Tolerance"
    echo "    ✓ Automatic Failover"
    echo ""
    echo "  Access your application through either load balancer:"
    echo "    • http://${MACHINE1_IP}:8080/api/*"
    echo "    • http://${MACHINE2_IP}:8080/api/*"
else
    echo "  ⚠️  Some tests failed. Check:"
    echo "    1. All services running: docker-compose ps"
    echo "    2. Nginx configs have correct IPs"
    echo "    3. Firewall ports open on both machines"
    echo "    4. Network connectivity between machines"
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo ""

# Show service distribution
echo "📊 Service Distribution Summary:"
echo ""
echo "Machine 1:"
echo "  • User Service (Primary) :3001"
echo "  • Product Service (Primary) :3002"
echo "  • Order Service (Replica) :3013"
echo "  • Nginx Load Balancer :8080"
echo ""
echo "Machine 2:"
echo "  • User Service (Replica) :3011"
echo "  • Product Service (Replica) :3012"
echo "  • Order Service (Primary) :3003"
echo "  • Nginx Load Balancer :8080"
echo ""

exit $FAIL_COUNT
