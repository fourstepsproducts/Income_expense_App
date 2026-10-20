const mongoose = require('mongoose');
const config = require('./env');

let memServer = null;

const connectDB = async () => {
  try {
    // Attempt standard connection first
    const conn = await mongoose.connect(config.mongoUri, {
      serverSelectionTimeoutMS: 2500
    });
    console.log(`[MongoDB] Connected successfully to: ${conn.connection.host}`);
    return conn;
  } catch (err) {
    if (config.env === 'development' || config.env === 'test') {
      console.warn(`[MongoDB] Primary connection failed (${err.message}). Starting in-memory MongoDB server for zero-friction development...`);
      try {
        const { MongoMemoryServer } = require('mongodb-memory-server');
        memServer = await MongoMemoryServer.create();
        const memUri = memServer.getUri();
        const conn = await mongoose.connect(memUri);
        console.log(`[MongoDB] Connected to in-memory MongoDB at: ${memUri}`);
        return conn;
      } catch (memErr) {
        console.error('[MongoDB] In-memory server failed to start:', memErr.message);
        throw memErr;
      }
    } else {
      console.error('[MongoDB] Connection error:', err.message);
      throw err;
    }
  }
};

const disconnectDB = async () => {
  await mongoose.disconnect();
  if (memServer) {
    await memServer.stop();
  }
};

module.exports = { connectDB, disconnectDB };
