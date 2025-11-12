const { createClient } = require('redis');

// Redis connection
const redisClient = createClient({
  socket: {
    host: process.env.REDIS_HOST || 'redis',
    port: process.env.REDIS_PORT || 6379
  },
  password: process.env.REDIS_PASSWORD || 'redis123'
});

redisClient.on('error', (err) => console.error('Redis Client Error', err));
redisClient.on('connect', () => console.log('Email Worker: Connected to Redis'));

// Simulate sending an email
async function sendEmail(notification) {
  return new Promise((resolve) => {
    setTimeout(() => {
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      console.log('📧 EMAIL NOTIFICATION SENT');
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      console.log(`Type: ${notification.type}`);
      console.log(`Order ID: ${notification.orderId}`);
      console.log(`User ID: ${notification.userId}`);
      console.log(`Product ID: ${notification.productId}`);
      console.log(`Quantity: ${notification.quantity}`);
      console.log(`Total Amount: $${notification.totalAmount}`);
      console.log(`Timestamp: ${notification.timestamp}`);
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      console.log('✅ Email sent successfully!\n');
      resolve();
    }, 1000); // Simulate 1 second delay
  });
}

// Process email queue
async function processEmailQueue() {
  console.log('Email Worker: Starting to process email queue...');
  
  while (true) {
    try {
      // Block and wait for items in the queue (BRPOP with 5 second timeout)
      const result = await redisClient.brPop('email-queue', 5);
      
      if (result) {
        const notification = JSON.parse(result.element);
        console.log('\nEmail Worker: Processing job...');
        await sendEmail(notification);
      } else {
        // Timeout occurred, no messages in queue
        process.stdout.write('.');
      }
    } catch (err) {
      console.error('Error processing email queue:', err);
      await new Promise(resolve => setTimeout(resolve, 5000)); // Wait 5 seconds on error
    }
  }
}

// Start worker
async function start() {
  try {
    await redisClient.connect();
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('🚀 Email Worker Started');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('Waiting for notifications...\n');
    await processEmailQueue();
  } catch (err) {
    console.error('Failed to start email worker:', err);
    process.exit(1);
  }
}

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('\nShutting down email worker...');
  await redisClient.quit();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.log('\nShutting down email worker...');
  await redisClient.quit();
  process.exit(0);
});

start();
