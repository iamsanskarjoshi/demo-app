# Project Structure

```
microservices-demo/
│
├── README.md                          # Main project documentation
├── INSTALLATION.md                    # Detailed installation guide
├── TESTING.md                         # Step-by-step testing guide
├── quick-start.sh                     # Interactive setup script
├── test-all.sh                        # Comprehensive test script
│
├── services/                          # All microservices
│   │
│   ├── user-service/                  # User Management API
│   │   ├── server.js                  # Express server
│   │   ├── package.json               # Node.js dependencies
│   │   ├── Dockerfile                 # Docker configuration
│   │   └── .dockerignore              # Docker ignore file
│   │
│   ├── product-service/               # Product Management API
│   │   ├── server.js                  # Express server
│   │   ├── package.json               # Node.js dependencies
│   │   ├── Dockerfile                 # Docker configuration
│   │   └── .dockerignore              # Docker ignore file
│   │
│   ├── order-service/                 # Order Management API
│   │   ├── server.js                  # Express server (with Redis)
│   │   ├── package.json               # Node.js dependencies
│   │   ├── Dockerfile                 # Docker configuration
│   │   └── .dockerignore              # Docker ignore file
│   │
│   ├── email-worker/                  # Email Notification Worker
│   │   ├── worker.js                  # Background worker
│   │   ├── package.json               # Node.js dependencies
│   │   ├── Dockerfile                 # Docker configuration
│   │   └── .dockerignore              # Docker ignore file
│   │
│   ├── data-sync-worker/              # Data Synchronization Worker
│   │   ├── worker.js                  # Background worker
│   │   ├── package.json               # Node.js dependencies
│   │   ├── Dockerfile                 # Docker configuration
│   │   └── .dockerignore              # Docker ignore file
│   │
│   └── ui-service/                    # React Frontend
│       ├── public/
│       │   └── index.html             # HTML template
│       ├── src/
│       │   ├── index.js               # React entry point
│       │   ├── index.css              # Global styles
│       │   ├── App.js                 # Main React component
│       │   └── App.css                # Component styles
│       ├── package.json               # Node.js dependencies
│       ├── Dockerfile                 # Multi-stage Docker build
│       └── .dockerignore              # Docker ignore file
│
├── machine1/                          # Machine 1 deployment
│   ├── docker-compose.yml             # Services for Machine 1
│   ├── .env.example                   # Environment template
│   ├── deploy.sh                      # Deployment script
│   └── README.md                      # Machine 1 documentation
│
└── machine2/                          # Machine 2 deployment
    ├── docker-compose.yml             # Services for Machine 2
    ├── .env.example                   # Environment template
    ├── deploy.sh                      # Deployment script
    └── README.md                      # Machine 2 documentation
```

## Service Descriptions

### API Services (3)

1. **User Service** (Port 3001)
   - CRUD operations for users
   - PostgreSQL database (on Machine 2)
   - Endpoints: GET, POST, PUT, DELETE /api/users

2. **Product Service** (Port 3002)
   - CRUD operations for products
   - PostgreSQL database (on Machine 2)
   - Endpoints: GET, POST, PUT, DELETE /api/products

3. **Order Service** (Port 3003)
   - CRUD operations for orders
   - PostgreSQL database (on Machine 2)
   - Redis integration for email notifications
   - Endpoints: GET, POST, PUT, DELETE /api/orders

### Background Services (2)

1. **Email Worker**
   - Listens to Redis queue (on Machine 2)
   - Processes order notifications
   - Simulates email sending
   - Runs continuously

2. **Data Sync Worker**
   - Periodically syncs data from all services
   - Updates sync statistics in PostgreSQL
   - Runs every 30 seconds
   - Tracks sync status

### UI Service (1)

1. **React Frontend** (Port 80)
   - Modern, responsive UI
   - Dashboard with statistics
   - CRUD interfaces for all entities
   - Auto-refresh every 5 seconds
   - Connects to all API services

### Infrastructure Services

1. **PostgreSQL** (Machine 2, Port 5432)
   - Shared database for all services
   - Tables: users, products, orders, sync_stats

2. **Redis** (Machine 2, Port 6379)
   - Message queue for background workers
   - Queue: email-queue

## Technology Stack

### Backend
- **Runtime:** Node.js 18
- **Framework:** Express.js
- **Database:** PostgreSQL 15
- **Cache/Queue:** Redis 7

### Frontend
- **Framework:** React 18
- **HTTP Client:** Axios
- **Build Tool:** Create React App

### DevOps
- **Containerization:** Docker
- **Orchestration:** Docker Compose
- **OS:** Ubuntu 20.04+

## Network Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        MACHINE 1                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ User Service │  │Product Service│  │ Email Worker │     │
│  │   :3001      │  │   :3002      │  │ (background) │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
│         │                  │                  │             │
│         │         ┌────────┴────────┐        │             │
│         │         │   UI Service    │        │             │
│         │         │      :80        │        │             │
│         │         └─────────────────┘        │             │
│         │                                     │             │
└─────────┼─────────────────────────────────────┼─────────────┘
          │                                     │
          │         Network Connection          │
          │                                     │
┌─────────┼─────────────────────────────────────┼─────────────┐
│         ↓                                     ↓             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  PostgreSQL  │  │    Redis     │  │Order Service │     │
│  │   :5432      │  │   :6379      │  │   :3003      │     │
│  └──────┬───────┘  └──────────────┘  └──────────────┘     │
│         │                                                   │
│         │         ┌──────────────────┐                     │
│         └────────→│ Data Sync Worker │                     │
│                   │  (background)    │                     │
│                   └──────────────────┘                     │
│                        MACHINE 2                            │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow

### 1. User Creates Order (via UI)
```
UI → Order Service → PostgreSQL (save order)
                  → Redis (queue email notification)
                  
Redis → Email Worker → Process notification
                    → Display email details
```

### 2. Data Synchronization
```
Data Sync Worker (every 30s)
    ↓
    → Fetch from User Service (Machine 1)
    → Fetch from Product Service (Machine 1)
    → Fetch from PostgreSQL (orders)
    → Update sync_stats table
```

### 3. UI Data Display
```
UI → User Service (Machine 1)     → Display users
  → Product Service (Machine 1)   → Display products
  → Order Service (Machine 2)     → Display orders
```

## Port Mapping

### Machine 1
- 3001: User Service API
- 3002: Product Service API
- 80: UI Service (HTTP)

### Machine 2
- 3003: Order Service API
- 5432: PostgreSQL Database
- 6379: Redis Cache/Queue

## Environment Variables

### Machine 1 (.env)
```env
MACHINE2_IP=<IP_ADDRESS_OF_MACHINE_2>
DB_HOST=<MACHINE2_IP>
REDIS_HOST=<MACHINE2_IP>
```

### Machine 2 (.env)
```env
POSTGRES_PASSWORD=postgres123
REDIS_PASSWORD=redis123
```

## File Sizes (Approximate)

- Services (source): ~10 KB each
- Docker images: ~150-200 MB each
- Total deployment: ~1.5 GB
- Database volume: Grows with data

## Development vs Production

This is a **demo/development** setup. For production:

1. **Security:**
   - Change all default passwords
   - Enable SSL/TLS
   - Implement authentication/authorization
   - Use secrets management

2. **Scalability:**
   - Use orchestration (Kubernetes)
   - Implement load balancing
   - Add caching layers
   - Database replication

3. **Reliability:**
   - Health checks
   - Auto-restart policies
   - Backup strategies
   - Monitoring and alerting

4. **Performance:**
   - Connection pooling
   - Query optimization
   - CDN for static assets
   - Compression
