const { Pool } = require('pg');
const axios = require('axios');

// Database connection
const pool = new Pool({
  host: process.env.DB_HOST || 'postgres',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'microservices',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres123',
});

// Configuration
const SYNC_INTERVAL = 30000; // 30 seconds
const USER_SERVICE_URL = process.env.USER_SERVICE_URL || 'http://user-service:3001';
const PRODUCT_SERVICE_URL = process.env.PRODUCT_SERVICE_URL || 'http://product-service:3002';

// Initialize sync stats table
async function initDB() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS sync_stats (
        id SERIAL PRIMARY KEY,
        service_name VARCHAR(100) NOT NULL,
        record_count INTEGER DEFAULT 0,
        last_sync TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        status VARCHAR(50) DEFAULT 'success'
      )
    `);
    console.log('Data Sync Worker: Database initialized');
  } catch (err) {
    console.error('Database initialization error:', err);
  }
}

// Fetch data from a service
async function fetchServiceData(serviceName, url) {
  try {
    const response = await axios.get(url, { timeout: 5000 });
    return { success: true, data: response.data, count: response.data.length };
  } catch (err) {
    console.error(`Failed to fetch data from ${serviceName}:`, err.message);
    return { success: false, count: 0 };
  }
}

// Update sync statistics
async function updateSyncStats(serviceName, count, status) {
  try {
    await pool.query(
      `INSERT INTO sync_stats (service_name, record_count, status, last_sync) 
       VALUES ($1, $2, $3, CURRENT_TIMESTAMP)
       ON CONFLICT (id) DO UPDATE 
       SET record_count = $2, status = $3, last_sync = CURRENT_TIMESTAMP`,
      [serviceName, count, status]
    );
  } catch (err) {
    console.error('Failed to update sync stats:', err);
  }
}

// Perform data synchronization
async function performSync() {
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('🔄 DATA SYNC STARTED');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`Timestamp: ${new Date().toISOString()}`);
  
  let totalRecords = 0;
  
  // Sync users
  console.log('\n📊 Syncing Users...');
  const usersResult = await fetchServiceData('User Service', `${USER_SERVICE_URL}/api/users`);
  if (usersResult.success) {
    console.log(`✅ Users synced: ${usersResult.count} records`);
    await updateSyncStats('users', usersResult.count, 'success');
    totalRecords += usersResult.count;
  } else {
    console.log('❌ Users sync failed');
    await updateSyncStats('users', 0, 'failed');
  }
  
  // Sync products
  console.log('\n📦 Syncing Products...');
  const productsResult = await fetchServiceData('Product Service', `${PRODUCT_SERVICE_URL}/api/products`);
  if (productsResult.success) {
    console.log(`✅ Products synced: ${productsResult.count} records`);
    await updateSyncStats('products', productsResult.count, 'success');
    totalRecords += productsResult.count;
  } else {
    console.log('❌ Products sync failed');
    await updateSyncStats('products', 0, 'failed');
  }
  
  // Sync orders (local)
  console.log('\n🛒 Syncing Orders...');
  try {
    const ordersResult = await pool.query('SELECT COUNT(*) FROM orders');
    const orderCount = parseInt(ordersResult.rows[0].count);
    console.log(`✅ Orders synced: ${orderCount} records`);
    await updateSyncStats('orders', orderCount, 'success');
    totalRecords += orderCount;
  } catch (err) {
    console.log('❌ Orders sync failed');
    await updateSyncStats('orders', 0, 'failed');
  }
  
  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`✅ SYNC COMPLETED - Total Records: ${totalRecords}`);
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
}

// Start sync worker
async function start() {
  try {
    await initDB();
    
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('🚀 Data Sync Worker Started');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`Sync Interval: ${SYNC_INTERVAL / 1000} seconds`);
    console.log(`User Service: ${USER_SERVICE_URL}`);
    console.log(`Product Service: ${PRODUCT_SERVICE_URL}`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    
    // Perform initial sync
    await performSync();
    
    // Schedule periodic syncs
    setInterval(async () => {
      await performSync();
      console.log(`⏰ Next sync in ${SYNC_INTERVAL / 1000} seconds...\n`);
    }, SYNC_INTERVAL);
    
  } catch (err) {
    console.error('Failed to start data sync worker:', err);
    process.exit(1);
  }
}

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('\nShutting down data sync worker...');
  await pool.end();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.log('\nShutting down data sync worker...');
  await pool.end();
  process.exit(0);
});

start();
