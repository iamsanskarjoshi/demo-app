#!/bin/bash

# Comprehensive Test Script for Microservices Demo

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Microservices Demo - Comprehensive Test Suite           ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Configuration
MACHINE1_IP="${MACHINE1_IP:-localhost}"
MACHINE2_IP="${MACHINE2_IP:-localhost}"

USER_API="http://${MACHINE1_IP}:3001/api/users"
PRODUCT_API="http://${MACHINE1_IP}:3002/api/products"
ORDER_API="http://${MACHINE2_IP}:3003/api/orders"

PASS_COUNT=0
FAIL_COUNT=0

# Helper function to test endpoint
test_endpoint() {
    local name=$1
    local url=$2
    local expected_status=$3
    
    echo -n "Testing $name... "
    response=$(curl -s -o /dev/null -w "%{http_code}" "$url" --connect-timeout 5)
    
    if [ "$response" == "$expected_status" ]; then
        echo "✅ PASS (HTTP $response)"
        ((PASS_COUNT++))
        return 0
    else
        echo "❌ FAIL (HTTP $response, expected $expected_status)"
        ((FAIL_COUNT++))
        return 1
    fi
}

# Helper function to create resource
create_resource() {
    local name=$1
    local url=$2
    local data=$3
    
    echo -n "Creating $name... "
    response=$(curl -s -X POST "$url" \
        -H "Content-Type: application/json" \
        -d "$data" \
        -w "\n%{http_code}" --connect-timeout 5)
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)
    
    if [ "$http_code" == "201" ] || [ "$http_code" == "200" ]; then
        echo "✅ PASS (HTTP $http_code)"
        echo "$body"
        ((PASS_COUNT++))
        return 0
    else
        echo "❌ FAIL (HTTP $http_code)"
        echo "$body"
        ((FAIL_COUNT++))
        return 1
    fi
}

echo "════════════════════════════════════════════════════════════"
echo "  Test 1: Service Health Checks"
echo "════════════════════════════════════════════════════════════"
echo ""

test_endpoint "User Service Health" "http://${MACHINE1_IP}:3001/health" "200"
test_endpoint "Product Service Health" "http://${MACHINE1_IP}:3002/health" "200"
test_endpoint "Order Service Health" "http://${MACHINE2_IP}:3003/health" "200"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Test 2: User Service CRUD Operations"
echo "════════════════════════════════════════════════════════════"
echo ""

# Create users
USER1=$(create_resource "User 1" "$USER_API" '{"name":"Alice Johnson","email":"alice@example.com","age":28}')
USER2=$(create_resource "User 2" "$USER_API" '{"name":"Bob Smith","email":"bob@example.com","age":35}')
USER3=$(create_resource "User 3" "$USER_API" '{"name":"Carol White","email":"carol@example.com","age":42}')

# Get all users
echo ""
test_endpoint "Get All Users" "$USER_API" "200"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Test 3: Product Service CRUD Operations"
echo "════════════════════════════════════════════════════════════"
echo ""

# Create products
PROD1=$(create_resource "Product 1" "$PRODUCT_API" '{"name":"Laptop Pro","description":"High-performance laptop","price":1299.99,"stock":15}')
PROD2=$(create_resource "Product 2" "$PRODUCT_API" '{"name":"Wireless Mouse","description":"Ergonomic design","price":29.99,"stock":50}')
PROD3=$(create_resource "Product 3" "$PRODUCT_API" '{"name":"Mechanical Keyboard","description":"RGB backlit","price":89.99,"stock":30}')
PROD4=$(create_resource "Product 4" "$PRODUCT_API" '{"name":"USB-C Hub","description":"7-in-1 adapter","price":49.99,"stock":40}')

# Get all products
echo ""
test_endpoint "Get All Products" "$PRODUCT_API" "200"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Test 4: Order Service CRUD Operations"
echo "════════════════════════════════════════════════════════════"
echo ""

# Create orders (these will trigger email notifications)
ORDER1=$(create_resource "Order 1" "$ORDER_API" '{"userId":1,"productId":1,"quantity":1,"totalAmount":1299.99}')
sleep 2
ORDER2=$(create_resource "Order 2" "$ORDER_API" '{"userId":2,"productId":2,"quantity":3,"totalAmount":89.97}')
sleep 2
ORDER3=$(create_resource "Order 3" "$ORDER_API" '{"userId":1,"productId":3,"quantity":1,"totalAmount":89.99}')
sleep 2

# Get all orders
echo ""
test_endpoint "Get All Orders" "$ORDER_API" "200"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Test 5: Cross-Service Communication"
echo "════════════════════════════════════════════════════════════"
echo ""

echo "Testing that services can read data from other services..."
echo ""

# Verify orders were created and can be retrieved
echo -n "Fetching orders from Machine 2... "
ORDERS_RESPONSE=$(curl -s "$ORDER_API")
ORDER_COUNT=$(echo "$ORDERS_RESPONSE" | grep -o '"id"' | wc -l)
if [ "$ORDER_COUNT" -ge 3 ]; then
    echo "✅ PASS (Found $ORDER_COUNT orders)"
    ((PASS_COUNT++))
else
    echo "❌ FAIL (Found only $ORDER_COUNT orders, expected at least 3)"
    ((FAIL_COUNT++))
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Test 6: Email Worker Verification"
echo "════════════════════════════════════════════════════════════"
echo ""

echo "⚠️  Manual verification required:"
echo "   Check email worker logs on Machine 1:"
echo "   cd machine1 && docker-compose logs email-worker"
echo ""
echo "   You should see email notifications for the orders created above."
echo ""

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Test 7: Data Sync Worker Verification"
echo "════════════════════════════════════════════════════════════"
echo ""

echo "⚠️  Manual verification required:"
echo "   Check data sync worker logs on Machine 2:"
echo "   cd machine2 && docker-compose logs data-sync-worker"
echo ""
echo "   You should see periodic sync operations every 30 seconds."
echo ""

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Test 8: Load Test (Multiple Rapid Orders)"
echo "════════════════════════════════════════════════════════════"
echo ""

echo "Creating 5 rapid orders to test email queue..."
for i in {1..5}; do
    echo -n "  Order $i... "
    response=$(curl -s -X POST "$ORDER_API" \
        -H "Content-Type: application/json" \
        -d "{\"userId\":$((i % 3 + 1)),\"productId\":$((i % 4 + 1)),\"quantity\":$i,\"totalAmount\":$((i * 50)).99}" \
        -w "%{http_code}" -o /dev/null)
    
    if [ "$response" == "201" ] || [ "$response" == "200" ]; then
        echo "✅"
    else
        echo "❌ (HTTP $response)"
    fi
    sleep 1
done

echo ""
echo "Check email worker to verify all 5 orders were processed"
echo ""

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Test Results Summary                                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "  ✅ Passed: $PASS_COUNT"
echo "  ❌ Failed: $FAIL_COUNT"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo "  🎉 All tests passed!"
    echo ""
    echo "  Next steps:"
    echo "  1. Open browser: http://${MACHINE1_IP}"
    echo "  2. Check email worker logs: cd machine1 && docker-compose logs -f email-worker"
    echo "  3. Check data sync logs: cd machine2 && docker-compose logs -f data-sync-worker"
else
    echo "  ⚠️  Some tests failed. Check the logs for details:"
    echo "  - docker-compose logs [service-name]"
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo ""
