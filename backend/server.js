require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { PORT, UPLOAD_DIR } = require('./config');

const routes = require('./routes');
const { initDB } = require('./db');
const { ensureBucketExists } = require('./services/storage.service');

const app = express();

// Global Middlewares
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use('/uploads', express.static(UPLOAD_DIR));

// Ensure database is initialized
let isInitialized = false;
let initPromise = null;

async function ensureAppInitialized() {
  if (isInitialized) return;
  if (!initPromise) {
    initPromise = (async () => {
      try {
        await initDB();
        await ensureBucketExists();
        isInitialized = true;
      } catch (err) {
        console.warn('[Sima.net Backend] Init notice:', err.message);
      }
    })();
  }
  return initPromise;
}

// Global middleware to guarantee initialization before handling requests on serverless
app.use(async (req, res, next) => {
  if (!isInitialized) {
    await ensureAppInitialized();
  }
  next();
});

// Modular Application Routes
app.use(routes);

// Start Server & Initialize Database/Storage locally (skip when hosted as Vercel serverless function)
if (!process.env.VERCEL) {
  app.listen(PORT, '0.0.0.0', async () => {
    console.log(`[Sima.net Backend] Server running on http://0.0.0.0:${PORT}`);
    await ensureAppInitialized();
  });
}

module.exports = app;
