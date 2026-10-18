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

// Start Server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`[Sima.net Backend] Server running on http://0.0.0.0:${PORT}`);
});

module.exports = app;
