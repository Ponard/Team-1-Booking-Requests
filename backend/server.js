// server.js - THE ONLY FILE YOU NEED TO MODIFY

// 1. Load the original server instance created by your core application file
const coreAppInstance = require('./src/app'); 

const { testConnection } = require('./src/config/database');
const { syncDatabase } = require('./src/models');
const express = require('express');
const cors = require('cors');

// 2. FIX THE FLUTTER NETWORK ERROR: Inject CORS directly into your original app instance
coreAppInstance.use(cors());

// 3. FIX PREFLIGHT BLOCKS: Intercept and approve the Flutter app's security checks
coreAppInstance.use((req, res, next) => {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
  res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept, Authorization");
  
  if (req.method === 'OPTIONS') {
    return res.sendStatus(200);
  }
  next();
});

// Load original Environment configuration
require('dotenv').config({ 
  path: `.env.${process.env.NODE_ENV || 'development'}` 
});

const PORT = process.env.PORT || 3000;

// Preserved original database and startup routine
const startServer = async () => {
  try {
    console.log('🚀 Starting Diocese API Server...');
    console.log(`📝 Environment: ${process.env.NODE_ENV}`);
    
    // Test database connection
    await testConnection();
    
    // Sync database models
    await syncDatabase({ 
      force: false,  
      alter: true,   
    });
    
    // 4. FIX THE BACKEND CRASH: Boot the server up cleanly using the original instance reference
    coreAppInstance.listen(PORT, '0.0.0.0', () => {
      console.log('');
      console.log('✅ Server started successfully with CORS active!');
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      console.log(`🌐 Server URL: http://localhost:${PORT}`);
      console.log(`📱 Flutter Android Target: http://10.0.2.2:${PORT}`);
      console.log(`📱 Flutter iOS Target: http://127.0.0.1:${PORT}`);
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