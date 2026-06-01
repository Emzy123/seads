'use strict';

const { Pool } = require('pg');

let pool;

/**
 * Returns the shared pg.Pool, creating it on first call.
 * Call db.connect() at startup to verify the connection and PostGIS.
 */
function getPool() {
  if (!pool) {
    pool = new Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: process.env.NODE_ENV === 'production'
        ? { rejectUnauthorized: false }
        : false,
      max: 10,
      idleTimeoutMillis: 30_000,
      connectionTimeoutMillis: 10_000,
    });

    pool.on('error', (err) => {
      console.error('[DB] Unexpected pool error:', err.message);
    });
  }
  return pool;
}

/**
 * Verify DB connectivity and PostGIS extension.
 * Called once at server startup — throws on failure.
 */
async function connect() {
  const p = getPool();
  const client = await p.connect();
  try {
    // Basic connectivity
    await client.query('SELECT 1');

    // Verify PostGIS
    const { rows } = await client.query(
      "SELECT extname FROM pg_extension WHERE extname = 'postgis'"
    );
    if (rows.length === 0) {
      console.warn('[DB] PostGIS extension not found — geo queries will fail. Enable it in Supabase Dashboard → Extensions.');
    } else {
      console.log('[DB] Connected to Supabase PostgreSQL + PostGIS ✓');
    }
  } finally {
    client.release();
  }
}

/**
 * Convenience query shortcut.
 * @param {string} text  SQL text
 * @param {any[]}  params  Query parameters
 */
async function query(text, params) {
  return getPool().query(text, params);
}

module.exports = { connect, query, getPool };
