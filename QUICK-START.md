# Microservices Demo Application

This is a complete, production-ready demonstration of a microservices architecture deployed across 2 Ubuntu machines using Docker.

## 🚀 Quick Start

**The fastest way to get started:**

```bash
# Download the project
cd ~
# (Copy microservices-demo folder here)

# Run the quick start script
cd microservices-demo
chmod +x quick-start.sh
./quick-start.sh
```

Follow the interactive prompts!

## 📁 What's Included

- **3 API Services:** User, Product, Order management
- **2 Background Workers:** Email notifications, Data synchronization
- **1 UI Service:** React-based frontend
- **Infrastructure:** PostgreSQL database, Redis message queue
- **Complete documentation:** Installation, testing, troubleshooting guides
- **Deployment scripts:** Automated setup for both machines
- **Test suite:** Comprehensive testing scripts

## 📚 Documentation

- **[README.md](README.md)** - Overview and quick reference
- **[INSTALLATION.md](INSTALLATION.md)** - Complete step-by-step installation guide
- **[TESTING.md](TESTING.md)** - Detailed testing procedures
- **[PROJECT-STRUCTURE.md](PROJECT-STRUCTURE.md)** - Architecture and file structure

## 🏗️ Architecture

```
Machine 1: User API, Product API, Email Worker, UI
Machine 2: Order API, PostgreSQL, Redis, Data Sync Worker
```

## 🛠️ Technology Stack

- **Backend:** Node.js + Express
- **Frontend:** React
- **Database:** PostgreSQL
- **Queue:** Redis
- **Deployment:** Docker + Docker Compose

## 📋 Prerequisites

- 2 Ubuntu machines (20.04+)
- Docker & Docker Compose
- Network connectivity between machines

## ⚡ Quick Commands

```bash
# Deploy Machine 2 (run this first)
cd machine2
./deploy.sh

# Deploy Machine 1
cd machine1
./deploy.sh

# Run tests
./test-all.sh

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

## 🎯 Features

✅ RESTful API services with full CRUD operations
✅ Asynchronous background job processing
✅ Real-time data synchronization
✅ Modern, responsive web UI
✅ Cross-service communication
✅ Database persistence
✅ Message queue integration
✅ Health check endpoints
✅ Comprehensive logging
✅ Auto-restart policies

## 📊 Service Endpoints

### Machine 1
- User API: http://localhost:3001/api/users
- Product API: http://localhost:3002/api/products
- Web UI: http://localhost

### Machine 2
- Order API: http://localhost:3003/api/orders
- PostgreSQL: localhost:5432
- Redis: localhost:6379

## 🧪 Testing

```bash
# Automated tests
./test-all.sh

# Manual API tests
curl http://localhost:3001/api/users
curl -X POST http://localhost:3001/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John","email":"john@example.com","age":30}'
```

## 📖 Learning Resources

This project demonstrates:
- Microservices architecture
- Service-to-service communication
- Background job processing
- Database management in distributed systems
- Message queue patterns
- Containerization with Docker
- Multi-machine deployment
- RESTful API design

## 🔧 Troubleshooting

See [INSTALLATION.md](INSTALLATION.md) troubleshooting section for common issues and solutions.

Quick checks:
```bash
# Check services
docker-compose ps

# View logs
docker-compose logs [service-name]

# Test connectivity
curl http://localhost:3001/health
```

## 📞 Support

1. Check the documentation files
2. View service logs: `docker-compose logs -f`
3. Verify network connectivity between machines
4. Ensure all required ports are open

## 📄 License

MIT License - Feel free to use this for learning and development!

## 🎓 Educational Use

Perfect for:
- Learning microservices architecture
- Understanding Docker deployment
- Practicing DevOps workflows
- Teaching distributed systems
- Portfolio projects

---

**Ready to deploy? Start with [INSTALLATION.md](INSTALLATION.md)!**
