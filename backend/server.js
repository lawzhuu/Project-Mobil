require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { PORT, UPLOAD_DIR } = require('./config');

const routes = require('./routes');

const app = express();

// Global Middlewares
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use('/uploads', express.static(UPLOAD_DIR));

// Modular Application Routes
app.use(routes);

// Start Server & Initialize Database/Storage
const { initDB } = require('./db');
const { ensureBucketExists } = require('./services/storage.service');

app.listen(PORT, '0.0.0.0', async () => {
  console.log(`[Sima.net Backend] Server running on http://0.0.0.0:${PORT}`);
  try {
    await initDB();
    await ensureBucketExists();
  } catch (err) {
    console.warn('[Sima.net Backend] Init notice:', err.message);
  }
});

module.exports = app;
