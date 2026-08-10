'use strict';

/**
 * SEADS Seed Script
 * Run with: npm run seed
 *
 * Seeds demo ambulances, equipment, and shifts so the app has
 * realistic data immediately after first deploy.
 *
 * Safe to run multiple times — uses ON CONFLICT DO NOTHING.
 */

require('dotenv').config({ path: require('path').join(__dirname, '../../.env') });
const db = require('../config/db');

const AMBULANCES = [
  { id: 'amb-0916', name: 'SEADS-0916 (Emergency 09164880144)', lat: 51.5090, lng: -0.1180, status: 'available', phone: '09164880144' },
  { id: 'amb-001', name: 'SEADS-01', lat:  51.5074, lng: -0.1278, status: 'available', phone: '09164880144' },  // London
  { id: 'amb-002', name: 'SEADS-02', lat:  51.5155, lng: -0.0922, status: 'available', phone: '09164880144' },
  { id: 'amb-003', name: 'SEADS-03', lat:  51.4994, lng: -0.1772, status: 'available', phone: '09164880144' },
  { id: 'amb-004', name: 'SEADS-04', lat:  51.5225, lng: -0.1358, status: 'maintenance', phone: '09164880144' },
  { id: 'amb-005', name: 'SEADS-05', lat:  51.4879, lng: -0.1060, status: 'offline', phone: '09164880144' },
];

const EQUIPMENT_TEMPLATES = [
  { name: 'Defibrillator (AED)',    category: 'Critical',   status: 'ok'      },
  { name: 'Oxygen Tank',            category: 'Critical',   status: 'ok'      },
  { name: 'Stretcher',              category: 'Critical',   status: 'ok'      },
  { name: 'IV Cannula Kit',         category: 'Medical',    status: 'ok'      },
  { name: 'Blood Pressure Monitor', category: 'Medical',    status: 'ok'      },
  { name: 'Pulse Oximeter',         category: 'Medical',    status: 'ok'      },
  { name: 'Trauma Dressing Kit',    category: 'Medical',    status: 'ok'      },
  { name: 'Morphine (10mg/ml)',      category: 'Medication', status: 'warning' },
  { name: 'Epinephrine (1mg/ml)',   category: 'Medication', status: 'ok'      },
  { name: 'Aspirin 300mg',          category: 'Medication', status: 'low'     },
  { name: 'Gloves (L)',             category: 'PPE',        status: 'ok'      },
  { name: 'Face Shields',           category: 'PPE',        status: 'ok'      },
];

async function seed() {
  try {
    await db.connect();
    console.log('[Seed] Connected to DB');

    // ── Ambulances ──────────────────────────────────────────
    for (const amb of AMBULANCES) {
      await db.query(
        `INSERT INTO ambulances (id, name, status, phone, location)
         VALUES ($1, $2, $3, $4, ST_SetSRID(ST_MakePoint($5, $6), 4326)::GEOGRAPHY)
         ON CONFLICT (id) DO UPDATE SET phone = EXCLUDED.phone, name = EXCLUDED.name`,
        [amb.id, amb.name, amb.status, amb.phone, amb.lng, amb.lat]
      );

      // ── Equipment per ambulance ─────────────────────────
      for (const eq of EQUIPMENT_TEMPLATES) {
        await db.query(
          `INSERT INTO equipment_items (ambulance_id, name, category, status, last_checked)
           VALUES ($1, $2, $3, $4, NOW() - INTERVAL '6 hours')
           ON CONFLICT DO NOTHING`,
          [amb.id, eq.name, eq.category, eq.status]
        );
      }
    }

    console.log(`[Seed] Inserted ${AMBULANCES.length} ambulances with equipment ✓`);

    // ── Sample shifts (for any existing paramedic users) ─────
    const { rows: paramedics } = await db.query(
      "SELECT id FROM users WHERE role = 'paramedic' LIMIT 5"
    );

    const shiftTypes = ['Day Shift', 'Night Shift', 'Day Shift', 'Night Shift'];
    const now = new Date();

    for (let i = 0; i < paramedics.length; i++) {
      const paramedic  = paramedics[i];
      const ambulance  = AMBULANCES[i % AMBULANCES.length];

      for (let d = -1; d <= 5; d++) {
        const shiftType = shiftTypes[(i + d) % shiftTypes.length];
        const isDay     = shiftType === 'Day Shift';

        const start = new Date(now);
        start.setDate(start.getDate() + d);
        start.setHours(isDay ? 7 : 19, 0, 0, 0);

        const end = new Date(start);
        end.setHours(start.getHours() + 12);

        const shiftStatus = d < 0  ? 'completed'
                          : d === 0 ? 'active'
                          : 'scheduled';

        await db.query(
          `INSERT INTO shifts (paramedic_id, ambulance_id, type, start_time, end_time, status)
           VALUES ($1, $2, $3, $4, $5, $6)
           ON CONFLICT DO NOTHING`,
          [paramedic.id, ambulance.id, shiftType, start.toISOString(), end.toISOString(), shiftStatus]
        );
      }
    }

    if (paramedics.length) {
      console.log(`[Seed] Inserted shifts for ${paramedics.length} paramedic(s) ✓`);
    } else {
      console.log('[Seed] No paramedic users found — shifts will be seeded on first paramedic signup');
    }

    console.log('[Seed] Done ✓');
    process.exit(0);
  } catch (err) {
    console.error('[Seed] Error:', err.message);
    process.exit(1);
  }
}

seed();
