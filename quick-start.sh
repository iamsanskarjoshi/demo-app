#!/bin/bash

# Quick Start Script for Microservices Demo
# This script helps you set up both machines

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Microservices Demo - Quick Start Setup                  ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Detect which machine we're on
read -p "Which machine is this? (1 or 2): " MACHINE_NUM

if [ "$MACHINE_NUM" != "1" ] && [ "$MACHINE_NUM" != "2" ]; then
    echo "❌ Invalid selection. Please enter 1 or 2."
    exit 1
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Step 1: Check Prerequisites"
echo "════════════════════════════════════════════════════════════"
echo ""

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed!"
    echo "   Install with: curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh"
    exit 1
else
    echo "✅ Docker is installed: $(docker --version)"
fi

# Check Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed!"
    echo "   Install with: sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose"
    exit 1
else
    echo "✅ Docker Compose is installed: $(docker-compose --version)"
fi

# Check if user is in docker group
if groups | grep -q docker; then
    echo "✅ User is in docker group"
else
    echo "⚠️  User is not in docker group"
    echo "   Run: sudo usermod -aG docker $USER"
    echo "   Then logout and login again"
fi

echo ""

if [ "$MACHINE_NUM" == "1" ]; then
    # Machine 1 setup
    echo "════════════════════════════════════════════════════════════"
    echo "  Step 2: Configure Machine 1"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    
    cd machine1
    
    if [ ! -f .env ]; then
        cp .env.example .env
        echo "✅ Created .env file"
    else
        echo "✅ .env file already exists"
    fi
    
    echo ""
    echo "⚠️  IMPORTANT: You need to configure Machine 2's IP address"
    echo ""
    read -p "Enter Machine 2's IP address: " MACHINE2_IP
    
    # Update .env file
    sed -i "s/MACHINE2_IP=.*/MACHINE2_IP=$MACHINE2_IP/" .env
    echo "✅ Updated .env with MACHINE2_IP=$MACHINE2_IP"
    
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "  Step 3: Deploy Services on Machine 1"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    
    chmod +x deploy.sh
    ./deploy.sh
    
else
    # Machine 2 setup
    echo "════════════════════════════════════════════════════════════"
    echo "  Step 2: Configure Machine 2"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    
    cd machine2
    
    if [ ! -f .env ]; then
        cp .env.example .env
        echo "✅ Created .env file"
    else
        echo "✅ .env file already exists"
    fi
    
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "  Step 3: Configure Firewall on Machine 2"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    
    echo "Opening required ports..."
    
    if command -v ufw &> /dev/null; then
        sudo ufw allow 5432/tcp  # PostgreSQL
        sudo ufw allow 6379/tcp  # Redis
        sudo ufw allow 3003/tcp  # Order Service
        echo "✅ Firewall rules configured"
    else
        echo "⚠️  UFW not found. Please manually open ports 5432, 6379, and 3003"
    fi
    
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "  Step 4: Deploy Services on Machine 2"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    
    chmod +x deploy.sh
    ./deploy.sh
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Setup Complete!                                          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

if [ "$MACHINE_NUM" == "1" ]; then
    echo "Next steps:"
    echo "1. Make sure Machine 2 is also set up and running"
    echo "2. Open your browser and go to http://localhost"
    echo "3. Run the test script: ./test-all.sh"
else
    echo "Next steps:"
    echo "1. Set up Machine 1 using this script"
    echo "2. Machine 1 will connect to this machine automatically"
fi

echo ""
