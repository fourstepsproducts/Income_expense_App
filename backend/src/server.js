const app = require('./app');
const config = require('./config/env');
const { connectDB, disconnectDB } = require('./config/db');
const categoryService = require('./services/categoryService');

let server;

const startServer = async () => {
  try {
    await connectDB();

    // Seed default categories on startup if needed
    await categoryService.seedDefaultCategories();
    console.log('[App] Default categories verified/seeded successfully');

    server = app.listen(config.port, () => {
      console.log(`===============================================`);
      console.log(`Personal Finance Tracker API`);
      console.log(`Port:        ${config.port}`);
      console.log(`Environment: ${config.env}`);
      console.log(`Health:      http://localhost:${config.port}/api/health`);
      console.log(`===============================================`);
    });
  } catch (err) {
    console.error('[App] Failed to start server:', err);
    process.exit(1);
  }
};

// Graceful shutdown
const shutdown = async () => {
  console.log('\n[App] Shutting down gracefully...');
  if (server) {
    server.close(async () => {
      console.log('[App] HTTP server closed');
      await disconnectDB();
      console.log('[App] MongoDB disconnected');
      process.exit(0);
    });
  } else {
    process.exit(0);
  }
};

process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);

if (process.env.NODE_ENV !== 'test') {
  startServer();
}

module.exports = { app, startServer };
