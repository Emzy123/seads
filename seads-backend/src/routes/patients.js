'use strict';

const { z }       = require('zod');
const { v4: uuid} = require('uuid');
const db          = require('../config/db');
const requireAuth = require('../middleware/auth');
const validate    = require('../middleware/validate');
const { sendPush} = require('../utils/fcm');

const router = require('express').Router();

// ─── POST /api/dispatch ───────────────────────────────────────────────────────
const dispatchSchema = z.object({
  lat:            z.number().min(-90).max(90),
  lng:            z.number().min(-180).max(180),
  patient_id:     z.string().min(1),
  emergency_type: z.string().min(1).max(120),
  description:    z.string().max(500).optional().nullable(),
});

router.post('/dispatch', requireAuth, validate(dispatchSchema), async (req, res, next) => {
  try {
    const { lat, lng, patient_id, emergency_type, description } = req.body;

    // 1. Find nearest available ambulance using PostGIS KNN operator
    const nearestRes = await db.query(
      `SELECT a.*, u.fcm_token AS paramedic_fcm
       FROM ambulances a
       LEFT JOIN users u ON u.id = a.paramedic_id
       WHERE a.status = 'available'
         AND a.location IS NOT NULL
       ORDER BY a.location <-> ST_SetSRID(ST_MakePoint($1, $2), 4326)::GEOGRAPHY
       LIMIT 1`,
      [lng, lat]
    );

    const ambulance = nearestRes.rows[0] || null;
    const incidentId = uuid();

    // 2. Create incident
    await db.query(
      `INSERT INTO incidents
         (id, patient_id, status, location, emergency_type, description, assigned_ambulance_id)
       VALUES ($1, $2, $3, ST_SetSRID(ST_MakePoint($4, $5), 4326)::GEOGRAPHY, $6, $7, $8)`,
      [
        incidentId,
        patient_id,
        ambulance ? 'dispatched' : 'pending',
        lng, lat,
        emergency_type,
        description || null,
        ambulance?.id || null,
      ]
    );

    // 3. Mark ambulance on_mission
    if (ambulance) {
      await db.query(
        "UPDATE ambulances SET status = 'on_mission', updated_at = NOW() WHERE id = $1",
        [ambulance.id]
      );

      // 4. FCM push to paramedic
      if (ambulance.paramedic_fcm) {
        await sendPush(
          ambulance.paramedic_fcm,
          '🚨 New Emergency Dispatch',
          `${emergency_type} — navigate to patient location`,
          { incident_id: incidentId, type: 'dispatch' }
        );
      }
    }

    res.status(201).json({
      message: ambulance
        ? `Ambulance ${ambulance.name} dispatched successfully.`
        : 'Incident created. No ambulances currently available — dispatcher has been alerted.',
      incident_id:  incidentId,
      ambulance_id: ambulance?.id || null,
      status:       ambulance ? 'dispatched' : 'pending',
    });
  } catch (err) {
    next(err);
  }
});

// ─── GET /api/patients/history ───────────────────────────────────────────────
router.get('/patients/history', requireAuth, async (req, res, next) => {
  try {
    const { rows } = await db.query(
      `SELECT i.*,
              ST_X(i.location::GEOMETRY) AS lng,
              ST_Y(i.location::GEOMETRY) AS lat,
              a.name AS ambulance_name
       FROM incidents i
       LEFT JOIN ambulances a ON a.id = i.assigned_ambulance_id
       WHERE i.patient_id = $1
       ORDER BY i.created_at DESC
       LIMIT 50`,
      [req.uid]
    );
    res.json({ history: rows });
  } catch (err) {
    next(err);
  }
});

// ─── GET /api/patients/contacts ──────────────────────────────────────────────
router.get('/patients/contacts', requireAuth, async (req, res, next) => {
  try {
    const { rows } = await db.query(
      'SELECT * FROM emergency_contacts WHERE user_id = $1 ORDER BY is_primary DESC, created_at',
      [req.uid]
    );
    res.json({ contacts: rows });
  } catch (err) {
    next(err);
  }
});

// ─── POST /api/patients/contacts ─────────────────────────────────────────────
const contactSchema = z.object({
  name:         z.string().min(1).max(120),
  phone:        z.string().min(1).max(30),
  relationship: z.string().min(1).max(60),
  is_primary:   z.boolean().optional().default(false),
});

router.post('/patients/contacts', requireAuth, validate(contactSchema), async (req, res, next) => {
  try {
    const { name, phone, relationship, is_primary } = req.body;

    // If new contact is primary, demote others
    if (is_primary) {
      await db.query(
        'UPDATE emergency_contacts SET is_primary = FALSE WHERE user_id = $1',
        [req.uid]
      );
    }

    const id = uuid();
    const { rows } = await db.query(
      `INSERT INTO emergency_contacts (id, user_id, name, phone, relationship, is_primary)
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
      [id, req.uid, name, phone, relationship, is_primary]
    );
    res.status(201).json({ contact: rows[0] });
  } catch (err) {
    next(err);
  }
});

// ─── PUT /api/patients/contacts/:id ──────────────────────────────────────────
const updateContactSchema = z.object({
  name:         z.string().min(1).max(120).optional(),
  phone:        z.string().min(1).max(30).optional(),
  relationship: z.string().min(1).max(60).optional(),
  is_primary:   z.boolean().optional(),
});

router.put('/patients/contacts/:id', requireAuth, validate(updateContactSchema), async (req, res, next) => {
  try {
    const { id } = req.params;
    const updates = req.body;

    // Ensure this contact belongs to the authenticated user
    const existing = await db.query(
      'SELECT id FROM emergency_contacts WHERE id = $1 AND user_id = $2',
      [id, req.uid]
    );
    if (!existing.rows.length) return res.status(404).json({ error: 'Contact not found' });

    if (updates.is_primary) {
      await db.query(
        'UPDATE emergency_contacts SET is_primary = FALSE WHERE user_id = $1',
        [req.uid]
      );
    }

    const fields  = Object.keys(updates);
    const setClauses = fields.map((f, i) => `${f} = $${i + 1}`);
    const values     = fields.map(f => updates[f]);

    const { rows } = await db.query(
      `UPDATE emergency_contacts SET ${setClauses.join(', ')}
       WHERE id = $${fields.length + 1} AND user_id = $${fields.length + 2}
       RETURNING *`,
      [...values, id, req.uid]
    );
    res.json({ contact: rows[0] });
  } catch (err) {
    next(err);
  }
});

// ─── DELETE /api/patients/contacts/:id ───────────────────────────────────────
router.delete('/patients/contacts/:id', requireAuth, async (req, res, next) => {
  try {
    const result = await db.query(
      'DELETE FROM emergency_contacts WHERE id = $1 AND user_id = $2',
      [req.params.id, req.uid]
    );
    if (result.rowCount === 0) return res.status(404).json({ error: 'Contact not found' });
    res.json({ message: 'Contact deleted' });
  } catch (err) {
    next(err);
  }
});

// ─── GET /api/patients/medical-profile ───────────────────────────────────────
router.get('/patients/medical-profile', requireAuth, async (req, res, next) => {
  try {
    const { rows } = await db.query(
      'SELECT * FROM medical_profiles WHERE user_id = $1',
      [req.uid]
    );
    if (!rows.length) return res.status(404).json({ error: 'No medical profile found' });
    const row = rows[0];
    // Normalise arrays (stored as TEXT[] in Postgres)
    res.json({
      ...row,
      allergies:   row.allergies   || [],
      conditions:  row.conditions  || [],
      medications: row.medications || [],
    });
  } catch (err) {
    next(err);
  }
});

// ─── PUT /api/patients/medical-profile ───────────────────────────────────────
const medicalProfileSchema = z.object({
  blood_type:  z.string().max(10).optional().nullable(),
  allergies:   z.array(z.string()).optional().default([]),
  conditions:  z.array(z.string()).optional().default([]),
  medications: z.array(z.string()).optional().default([]),
  notes:       z.string().max(2000).optional().nullable(),
});

router.put('/patients/medical-profile', requireAuth, validate(medicalProfileSchema), async (req, res, next) => {
  try {
    const { blood_type, allergies, conditions, medications, notes } = req.body;

    const { rows } = await db.query(
      `INSERT INTO medical_profiles (user_id, blood_type, allergies, conditions, medications, notes, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, NOW())
       ON CONFLICT (user_id) DO UPDATE
         SET blood_type  = EXCLUDED.blood_type,
             allergies   = EXCLUDED.allergies,
             conditions  = EXCLUDED.conditions,
             medications = EXCLUDED.medications,
             notes       = EXCLUDED.notes,
             updated_at  = NOW()
       RETURNING *`,
      [req.uid, blood_type, allergies, conditions, medications, notes]
    );
    res.json({ ...rows[0] });
  } catch (err) {
    next(err);
  }
});


// ─── GET /api/patients/active-incident ───────────────────────────────────────
router.get('/patients/active-incident', requireAuth, async (req, res, next) => {
  try {
    const { rows } = await db.query(
      `SELECT i.*,
              ST_X(i.location::GEOMETRY) AS lng,
              ST_Y(i.location::GEOMETRY) AS lat,
              a.name AS ambulance_name,
              a.status AS ambulance_status,
              ST_X(a.location::GEOMETRY) AS ambulance_lng,
              ST_Y(a.location::GEOMETRY) AS ambulance_lat
       FROM incidents i
       LEFT JOIN ambulances a ON a.id = i.assigned_ambulance_id
       WHERE i.patient_id = $1
         AND i.status NOT IN ('resolved', 'cancelled')
       ORDER BY i.created_at DESC
       LIMIT 1`,
      [req.uid]
    );
    if (!rows.length) {
      return res.status(404).json({ error: 'No active incident found' });
    }
    res.json({ incident: rows[0] });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
