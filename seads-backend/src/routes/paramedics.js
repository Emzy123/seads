'use strict';

const { z }        = require('zod');
const { v4: uuid } = require('uuid');
const db           = require('../config/db');
const requireAuth  = require('../middleware/auth');
const validate     = require('../middleware/validate');

const router = require('express').Router();

// ─── GET /api/incidents ───────────────────────────────────────────────────────
// Active incidents assigned to the paramedic's ambulance
router.get('/incidents', requireAuth, async (req, res, next) => {
  try {
    // Find the ambulance this paramedic is assigned to
    const ambulanceRes = await db.query(
      "SELECT id FROM ambulances WHERE paramedic_id = $1 AND status != 'offline' LIMIT 1",
      [req.uid]
    );

    if (!ambulanceRes.rows.length) {
      return res.json({ incidents: [] });
    }

    const ambulanceId = ambulanceRes.rows[0].id;

    const { rows } = await db.query(
      `SELECT i.*,
              ST_X(i.location::GEOMETRY) AS lng,
              ST_Y(i.location::GEOMETRY) AS lat,
              u.name AS patient_name, u.phone AS patient_phone
       FROM incidents i
       JOIN users u ON u.id = i.patient_id
       WHERE i.assigned_ambulance_id = $1
         AND i.status NOT IN ('resolved', 'cancelled')
       ORDER BY i.created_at DESC`,
      [ambulanceId]
    );
    res.json({ incidents: rows });
  } catch (err) {
    next(err);
  }
});

// ─── PUT /api/incidents/:id/status ────────────────────────────────────────────
const incidentStatusSchema = z.object({
  status: z.enum(['pending', 'dispatched', 'en_route', 'on_scene', 'resolved', 'cancelled']),
});

router.put('/incidents/:id/status', requireAuth, validate(incidentStatusSchema), async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    const { rows, rowCount } = await db.query(
      `UPDATE incidents SET status = $1, updated_at = NOW()
       WHERE id = $2
       RETURNING *`,
      [status, id]
    );
    if (!rowCount) return res.status(404).json({ error: 'Incident not found' });

    // If resolved or cancelled, free up the ambulance
    if (status === 'resolved' || status === 'cancelled') {
      if (rows[0].assigned_ambulance_id) {
        await db.query(
          "UPDATE ambulances SET status = 'available', updated_at = NOW() WHERE id = $1",
          [rows[0].assigned_ambulance_id]
        );
      }
    }

    res.json({ incident: rows[0] });
  } catch (err) {
    next(err);
  }
});

// ─── PUT /api/paramedics/status ───────────────────────────────────────────────
const paramedicStatusSchema = z.object({
  status: z.enum(['available', 'on_mission', 'offline']),
});

router.put('/paramedics/status', requireAuth, validate(paramedicStatusSchema), async (req, res, next) => {
  try {
    const { status } = req.body;
    // Map paramedic status to ambulance status
    const ambulanceStatus = status === 'available'   ? 'available'
                          : status === 'on_mission'  ? 'on_mission'
                          : 'offline';

    await db.query(
      'UPDATE ambulances SET status = $1, updated_at = NOW() WHERE paramedic_id = $2',
      [ambulanceStatus, req.uid]
    );
    res.json({ message: 'Status updated', status });
  } catch (err) {
    next(err);
  }
});

// ─── PUT /api/ambulances/location ────────────────────────────────────────────
const locationSchema = z.object({
  lat: z.number().min(-90).max(90),
  lng: z.number().min(-180).max(180),
});

router.put('/ambulances/location', requireAuth, validate(locationSchema), async (req, res, next) => {
  try {
    const { lat, lng } = req.body;
    await db.query(
      `UPDATE ambulances
       SET location = ST_SetSRID(ST_MakePoint($1, $2), 4326)::GEOGRAPHY,
           updated_at = NOW()
       WHERE paramedic_id = $3`,
      [lng, lat, req.uid]
    );
    res.json({ message: 'Location updated' });
  } catch (err) {
    next(err);
  }
});

// ─── GET /api/paramedics/history ──────────────────────────────────────────────
router.get('/paramedics/history', requireAuth, async (req, res, next) => {
  try {
    const ambulanceRes = await db.query(
      'SELECT id FROM ambulances WHERE paramedic_id = $1 LIMIT 1',
      [req.uid]
    );
    if (!ambulanceRes.rows.length) return res.json({ assignments: [] });

    const { rows } = await db.query(
      `SELECT i.*,
              ST_X(i.location::GEOMETRY) AS lng,
              ST_Y(i.location::GEOMETRY) AS lat,
              u.name AS patient_name
       FROM incidents i
       JOIN users u ON u.id = i.patient_id
       WHERE i.assigned_ambulance_id = $1
         AND i.status IN ('resolved', 'cancelled')
       ORDER BY i.updated_at DESC
       LIMIT 50`,
      [ambulanceRes.rows[0].id]
    );
    res.json({ assignments: rows });
  } catch (err) {
    next(err);
  }
});

// ─── GET /api/paramedics/stats ────────────────────────────────────────────────
router.get('/paramedics/stats', requireAuth, async (req, res, next) => {
  try {
    const period = req.query.period || 'week';
    const interval = period === 'month' ? '30 days'
                   : period === 'year'  ? '365 days'
                   : '7 days';

    const ambulanceRes = await db.query(
      'SELECT id FROM ambulances WHERE paramedic_id = $1 LIMIT 1',
      [req.uid]
    );
    if (!ambulanceRes.rows.length) {
      return res.json({ total: 0, resolved: 0, avg_response_minutes: 0, period });
    }

    const { rows } = await db.query(
      `SELECT
         COUNT(*)                                                      AS total,
         COUNT(*) FILTER (WHERE status = 'resolved')                  AS resolved,
         ROUND(AVG(
           EXTRACT(EPOCH FROM (updated_at - created_at)) / 60
         ) FILTER (WHERE status = 'resolved'), 1)                     AS avg_response_minutes
       FROM incidents
       WHERE assigned_ambulance_id = $1
         AND created_at >= NOW() - $2::INTERVAL`,
      [ambulanceRes.rows[0].id, interval]
    );
    res.json({ ...rows[0], period });
  } catch (err) {
    next(err);
  }
});

// ─── GET /api/paramedics/equipment ───────────────────────────────────────────
router.get('/paramedics/equipment', requireAuth, async (req, res, next) => {
  try {
    const ambulanceRes = await db.query(
      'SELECT id FROM ambulances WHERE paramedic_id = $1 LIMIT 1',
      [req.uid]
    );
    if (!ambulanceRes.rows.length) return res.json({ equipment: [] });

    const { rows } = await db.query(
      'SELECT * FROM equipment_items WHERE ambulance_id = $1 ORDER BY category, name',
      [ambulanceRes.rows[0].id]
    );
    res.json({ equipment: rows });
  } catch (err) {
    next(err);
  }
});

// ─── POST /api/paramedics/equipment/checklist ─────────────────────────────────
const checklistSchema = z.object({
  items: z.array(z.object({
    id:      z.string().optional(),
    name:    z.string().min(1),
    status:  z.enum(['ok', 'warning', 'low']),
    checked: z.boolean().optional(),
  })).min(1),
});

router.post('/paramedics/equipment/checklist', requireAuth, validate(checklistSchema), async (req, res, next) => {
  try {
    const { items } = req.body;

    // Bulk update: only update items that have an id
    for (const item of items) {
      if (item.id) {
        await db.query(
          'UPDATE equipment_items SET status = $1, last_checked = NOW() WHERE id = $2',
          [item.status, item.id]
        );
      }
    }
    res.json({ message: 'Equipment checklist submitted' });
  } catch (err) {
    next(err);
  }
});

// ─── GET /api/paramedics/shifts ───────────────────────────────────────────────
router.get('/paramedics/shifts', requireAuth, async (req, res, next) => {
  try {
    const { from, to } = req.query;
    const params  = [req.uid];
    let dateFilter = '';

    if (from) { params.push(from); dateFilter += ` AND s.start_time >= $${params.length}`; }
    if (to)   { params.push(to);   dateFilter += ` AND s.end_time   <= $${params.length}`; }

    const { rows } = await db.query(
      `SELECT s.*, a.name AS ambulance_name
       FROM shifts s
       LEFT JOIN ambulances a ON a.id = s.ambulance_id
       WHERE s.paramedic_id = $1 ${dateFilter}
       ORDER BY s.start_time`,
      params
    );

    // Map to expected shape
    const shifts = rows.map(s => ({
      id:           s.id,
      type:         s.type,
      start:        s.start_time,
      end:          s.end_time,
      status:       s.status,
      partner:      s.partner_name,
      ambulance_id: s.ambulance_id,
    }));

    res.json({ shifts });
  } catch (err) {
    next(err);
  }
});

// ─── POST /api/paramedics/shifts/swap-request ─────────────────────────────────
const swapSchema = z.object({
  shift_id: z.string().min(1),
  message:  z.string().max(500).optional().nullable(),
});

router.post('/paramedics/shifts/swap-request', requireAuth, validate(swapSchema), async (req, res, next) => {
  try {
    const { shift_id, message } = req.body;

    // Verify shift belongs to this paramedic
    const shiftRes = await db.query(
      'SELECT id FROM shifts WHERE id = $1 AND paramedic_id = $2',
      [shift_id, req.uid]
    );
    if (!shiftRes.rows.length) return res.status(404).json({ error: 'Shift not found' });

    const id = uuid();
    await db.query(
      `INSERT INTO shift_swap_requests (id, shift_id, requester_id, message)
       VALUES ($1, $2, $3, $4)`,
      [id, shift_id, req.uid, message || null]
    );
    res.status(201).json({ message: 'Swap request submitted', id });
  } catch (err) {
    next(err);
  }
});

// ─── GET /api/paramedics/shifts/swap-requests ───────────────────────────────
router.get('/paramedics/shifts/swap-requests', requireAuth, async (req, res, next) => {
  try {
    const { rows } = await db.query(
      `SELECT ssr.*,
              u.name AS requester_name,
              s.type AS requester_shift_type,
              s.start_time AS requester_shift_start,
              s.end_time AS requester_shift_end
       FROM shift_swap_requests ssr
       JOIN shifts s ON s.id = ssr.shift_id
       JOIN users u ON u.id = ssr.requester_id
       WHERE ssr.status = 'pending'
         AND ssr.requester_id != $1`,
      [req.uid]
    );
    res.json({ swap_requests: rows });
  } catch (err) {
    next(err);
  }
});

// ─── POST /api/paramedics/shifts/swap-requests/:id/accept ────────────────────
const acceptSwapSchema = z.object({
  your_shift_id: z.string().min(1),
});

router.post('/paramedics/shifts/swap-requests/:id/accept', requireAuth, validate(acceptSwapSchema), async (req, res, next) => {
  let client;
  try {
    const { id } = req.params;
    const { your_shift_id } = req.body;

    // 1. Get the swap request details
    const reqRes = await db.query(
      'SELECT * FROM shift_swap_requests WHERE id = $1 AND status = \'pending\'',
      [id]
    );
    if (!reqRes.rows.length) {
      return res.status(404).json({ error: 'Swap request not found or already resolved' });
    }
    const swapReq = reqRes.rows[0];

    // 2. Verify both shifts exist and belong to the correct paramedic
    const shiftARes = await db.query(
      'SELECT paramedic_id FROM shifts WHERE id = $1',
      [swapReq.shift_id]
    );
    const shiftBRes = await db.query(
      'SELECT paramedic_id FROM shifts WHERE id = $1',
      [your_shift_id]
    );

    if (!shiftARes.rows.length || !shiftBRes.rows.length) {
      return res.status(404).json({ error: 'One or both shifts not found' });
    }

    if (shiftARes.rows[0].paramedic_id !== swapReq.requester_id) {
      return res.status(400).json({ error: 'Requester does not own the requested shift' });
    }
    if (shiftBRes.rows[0].paramedic_id !== req.uid) {
      return res.status(400).json({ error: 'You do not own the selected swap shift' });
    }

    // 3. Execute the swap transaction
    client = await db.getPool().connect();
    await client.query('BEGIN');

    // Update Shift A to belong to current user (req.uid)
    await client.query(
      'UPDATE shifts SET paramedic_id = $1 WHERE id = $2',
      [req.uid, swapReq.shift_id]
    );

    // Update Shift B to belong to the requester (swapReq.requester_id)
    await client.query(
      'UPDATE shifts SET paramedic_id = $1 WHERE id = $2',
      [swapReq.requester_id, your_shift_id]
    );

    // Approve the swap request
    await client.query(
      'UPDATE shift_swap_requests SET status = \'approved\' WHERE id = $1',
      [id]
    );

    await client.query('COMMIT');
    res.json({ message: 'Shift swap approved and processed successfully' });
  } catch (err) {
    if (client) {
      try {
        await client.query('ROLLBACK');
      } catch (rollbackErr) {
        console.error('Rollback failed:', rollbackErr);
      }
    }
    next(err);
  } finally {
    if (client) client.release();
  }
});

// ─── POST /api/paramedics/shifts/swap-requests/:id/decline ───────────────────
router.post('/paramedics/shifts/swap-requests/:id/decline', requireAuth, async (req, res, next) => {
  try {
    const { id } = req.params;
    const { rowCount } = await db.query(
      'UPDATE shift_swap_requests SET status = \'rejected\' WHERE id = $1 AND status = \'pending\'',
      [id]
    );
    if (!rowCount) {
      return res.status(404).json({ error: 'Swap request not found or already resolved' });
    }
    res.json({ message: 'Shift swap request declined' });
  } catch (err) {
    next(err);
  }
});

// ─── PUT /api/paramedics/shifts/:id/status ───────────────────────────────────
const shiftStatusUpdateSchema = z.object({
  status: z.enum(['scheduled', 'active', 'completed', 'cancelled']),
});

router.put('/paramedics/shifts/:id/status', requireAuth, validate(shiftStatusUpdateSchema), async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    const { rows, rowCount } = await db.query(
      'UPDATE shifts SET status = $1 WHERE id = $2 AND paramedic_id = $3 RETURNING *',
      [status, id, req.uid]
    );
    if (!rowCount) {
      return res.status(404).json({ error: 'Shift not found or not assigned to you' });
    }
    res.json({ shift: rows[0] });
  } catch (err) {
    next(err);
  }
});

module.exports = router;

