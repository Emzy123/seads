'use strict';

/**
 * SEADS Database Clear Script
 * Run with: node src/utils/clear-db.js
 *
 * Drops all tables in the database to clear all data.
 * After running, you can re-run the migration and seed scripts.
 */

require('dotenv').config({ path: require('path').join(__dirname, '../../.env') });
const db = require('../config/db');

async function clearDatabase() {
  try {
    await db.connect();
    console.log('[Clear DB] Connected to DB');

    // Drop tables in correct order (respecting foreign key dependencies)
    const tables = [
      'shift_swap_requests',
      'shifts',
      'equipment_items',
      'medical_profiles',
      'emergency_contacts',
      'incidents',
      'ambulances',
      'users'
    ];

    for (const table of tables) {
      await db.query(`DROP TABLE IF EXISTS ${table} CASCADE`);
      console.log(`[Clear DB] Dropped table: ${table}`);
    }

    console.log('[Clear DB] All tables dropped ✓');
    console.log('[Clear DB] Run supabase-migration.sql to recreate schema');
    console.log('[Clear DB] Run npm run seed to populate with demo data');
    
    process.exit(0);
  } catch (err) {
    console.error('[Clear DB] Error:', err.message);
    process.exit(1);
  }
}

clearDatabase();
