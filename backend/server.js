const app = require('./src/app');
const { testConnection } = require('./src/config/database');
const { syncDatabase } = require('./src/models');
const express = require('express');
const cors = require('cors'); // 1. Make sure this import is here
const app = express();

// 1. Completely open up CORS for development
app.use(cors());

// 2. Add an explicit interceptor for the Preflight check 
app.use((req, res, next) => {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
  res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept, Authorization");
  
  // Instantly approve OPTIONS preflight requests
  if (req.method === 'OPTIONS') {
    return res.sendStatus(200);
  }
  next();
});
require('dotenv').config({ 
  path: `.env.${process.env.NODE_ENV || 'development'}` 
});

const PORT = process.env.PORT || 3000;

const startServer = async () => {
  try {
    console.log('🚀 Starting Diocese API Server...');
    console.log(`📝 Environment: ${process.env.NODE_ENV}`);
    
    // Test database connection
    await testConnection();
    
    // Sync database models
    // CAUTION: Set { force: true } only in development to reset database
    await syncDatabase({ 
      force: false,  // Set to true to drop all tables and recreate
      alter: true,   // Set to true to modify existing tables
    });
    
    // Start Express server
    app.listen(PORT, '0.0.0.0', () => {
      console.log('');
      console.log('✅ Server started successfully!');
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      console.log(`🌐 Server URL: http://localhost:${PORT}`);
      console.log(`📱 Flutter Android: http://10.0.2.2:${PORT}`);
      console.log(`📱 Flutter iOS: http://127.0.0.1:${PORT}`);
      console.log(`❤️  Health Check: http://localhost:${PORT}/health`);
      console.log(`📚 API Info: http://localhost:${PORT}/api`);
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      console.log('');
    });
  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
};

// Handle graceful shutdown
process.on('SIGTERM', () => {
  console.log('⚠️  SIGTERM received. Shutting down gracefully...');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('⚠️  SIGINT received. Shutting down gracefully...');
  process.exit(0);
});

startServer();