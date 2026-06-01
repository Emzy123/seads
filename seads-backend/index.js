'use strict';

require('dotenv').config();

const express    = require('express');
const cors       = require('cors');
const helmet     = require('helmet');
const rateLimit  = require('express-rate-limit');

const db         = require('./src/config/db');
require('./src/config/firebase');           // initialise Firebase Admin early

const authRoutes       = require('./src/routes/auth');
const usersRoutes      = require('./src/routes/users');
const patientsRoutes   = require('./src/routes/patients');
const paramedicsRoutes = require('./src/routes/paramedics');
const dispatchersRoutes = require('./src/routes/dispatchers');

// ─── App ────────────────────────────────────────────────────────────────────
const app  = express();
const PORT = process.env.PORT || 3000;

// ─── Security & parsing ─────────────────────────────────────────────────────
app.use(helmet());
app.use(cors({
  origin: process.env.ALLOWED_ORIGIN === '*'
    ? '*'
    : process.env.ALLOWED_ORIGIN?.split(',').map(s => s.trim()),
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
app.use(express.json({ limit: '1mb' }));

// ─── Rate limiting ───────────────────────────────────────────────────────────
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests, please try again later.' },
});

const generalLimiter = rateLimit({
  windowMs: 60 * 1000,       // 1 minute
  max: 120,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Rate limit exceeded.' },
});

app.use('/api/auth', authLimiter);
app.use('/api', generalLimiter);

// ─── Routes ──────────────────────────────────────────────────────────────────
app.get('/', (_req, res) => res.json({ status: 'ok', service: 'SEADS API', version: '2.0.0' }));

app.use('/api/auth',        authRoutes);
app.use('/api/users',       usersRoutes);
app.use('/api',             patientsRoutes);    // /api/dispatch, /api/patients/*
app.use('/api',             paramedicsRoutes);  // /api/incidents, /api/paramedics/*, /api/ambulances/*
app.use('/api',             dispatchersRoutes); // /api/ambulances, /api/dispatchers/*

// ─── 404 & error handler ────────────────────────────────────────────────────
app.use((_req, res) => res.status(404).json({ error: 'Not found' }));

app.use((err, _req, res, _next) => {
  console.error('[SEADS]', err);
  const status = err.status || err.statusCode || 500;
  res.status(status).json({ error: err.message || 'Internal server error' });
});

// ─── Start ───────────────────────────────────────────────────────────────────
async function start() {
  try {
    await db.connect();           // verify DB connection + PostGIS
    app.listen(PORT, () => {
      console.log(`[SEADS] Server running on port ${PORT} (${process.env.NODE_ENV || 'production'})`);
    });
  } catch (err) {
    console.error('[SEADS] Failed to start:', err.message);
    process.exit(1);
  }
}

start();
