'use strict';

const { z }         = require('zod');
const db            = require('../config/db');
const requireAuth   = require('../middleware/auth');
const validate      = require('../middleware/validate');
const { sendPush }  = require('../utils/fcm');

const router = require('express').Router();

// ─── GET /api/ambulances ──────────────────────────────────────────────────────
router.get('/ambulances', requireAuth, async (req, res, next) => {
  try {
    const { rows } = await db.query(
      `SELECT a.*,
              ST_X(a.location::GEOMETRY) AS lng,
              ST_Y(a.location::GEOMETRY) AS lat,
              u.name AS paramedic_name
       FROM ambulances a
       LEFT JOIN users u ON u.id = a.paramedic_id
       ORDER BY a.name`
    );
    res.json({ ambulances: rows });
  } catch (err) {
    next(err);
  }
});

// ─── PUT /api/ambulances/:id/status ──────────────────────────────────────────
const ambulanceStatusSchema = z.object({
  status: z.enum(['available', 'on_mission', 'maintenance', 'offline']),
});

router.put('/ambulances/:id/status', requireAuth, validate(ambulanceStatusSchema), async (req, res, next) => {
  try {
    const { rows, rowCount } = await db.query(
      'UPDATE ambulances SET status = $1, updated_at = NOW() WHERE id = $2 RETURNING *',
      [req.body.status, req.params.id]
    );
    if (!rowCount) return res.status(404).json({ error: 'Ambulance not found' });
    res.json({ ambulance: rows[0] });
  } catch (err) {
    next(err);
  }
});

// ─── GET /api/dispatchers/fleet ───────────────────────────────────────────────
router.get('/dispatchers/fleet', requireAuth, async (req, res, next) => {
  try {
    const { rows } = await db.query(
      `SELECT a.*,
              ST_X(a.location::GEOMETRY) AS lng,
              ST_Y(a.location::GEOMETRY) AS lat,
              u.name  AS paramedic_name,
              u.phone AS paramedic_phone
       FROM ambulances a
       LEFT JOIN users u ON u.id = a.paramedic_id
       ORDER BY a.name`
    );
    res.json({ fleet: rows });
  } catch (err) {
    next(err);
  }
});

// ─── GET /api/dispatchers/staff ───────────────────────────────────────────────
router.get('/dispatchers/staff', requireAuth, async (req, res, next) => {
  try {
    const { rows } = await db.query(
      `SELECT u.*,
              a.id   AS ambulance_id,
              a.name AS ambulance_name,
              a.status AS ambulance_status
       FROM users u
       LEFT JOIN ambulances a ON a.paramedic_id = u.id
       WHERE u.role IN ('paramedic', 'dispatcher')
       ORDER BY u.role, u.name`
    );
    res.json({ staff: rows });
  } catch (err) {
    next(err);
  }
});

// ─── GET /api/dispatchers/incidents ───────────────────────────────────────────
// Supports query filters: status, emergency_type, from, to
router.get('/dispatchers/incidents', requireAuth, async (req, res, next) => {
  try {
    const { status, emergency_type, from, to } = req.query;
    const params = [];
    const where  = [];

    if (status)         { params.push(status);         where.push(`i.status = $${params.length}`); }
    if (emergency_type) { params.push(emergency_type); where.push(`i.emergency_type = $${params.length}`); }
    if (from)           { params.push(from);           where.push(`i.created_at >= $${params.length}`); }
    if (to)             { params.push(to);             where.push(`i.created_at <= $${params.length}`); }

    const whereClause = where.length ? `WHERE ${where.join(' AND ')}` : '';

    const { rows } = await db.query(
      `SELECT i.*,
              ST_X(i.location::GEOMETRY) AS lng,
              ST_Y(i.location::GEOMETRY) AS lat,
              u.name  AS patient_name,
              a.name  AS ambulance_name
       FROM incidents i
       JOIN    users      u ON u.id = i.patient_id
       LEFT JOIN ambulances a ON a.id = i.assigned_ambulance_id
       ${whereClause}
       ORDER BY i.created_at DESC
       LIMIT 200`,
      params
    );
    res.json({ incidents: rows });
  } catch (err) {
    next(err);
  }
});

// ─── GET /api/dispatchers/analytics ───────────────────────────────────────────
router.get('/dispatchers/analytics', requireAuth, async (req, res, next) => {
  try {
    const period   = req.query.period || 'week';
    const interval = period === 'month' ? '30 days'
                   : period === 'year'  ? '365 days'
                   : '7 days';

    const [overview, byStatus, byType, fleet] = await Promise.all([
      // Overall numbers
      db.query(
        `SELECT
           COUNT(*)                                                   AS total_incidents,
           COUNT(*) FILTER (WHERE status = 'resolved')               AS resolved,
           COUNT(*) FILTER (WHERE status = 'pending')                AS pending,
           COUNT(*) FILTER (WHERE status = 'dispatched')             AS dispatched,
           ROUND(AVG(
             EXTRACT(EPOCH FROM (updated_at - created_at)) / 60
           ) FILTER (WHERE status = 'resolved'), 1)                  AS avg_response_minutes
         FROM incidents
         WHERE created_at >= NOW() - $1::INTERVAL`,
        [interval]
      ),
      // By status breakdown
      db.query(
        `SELECT status, COUNT(*) AS count
         FROM incidents
         WHERE created_at >= NOW() - $1::INTERVAL
         GROUP BY status`,
        [interval]
      ),
      // By emergency type
      db.query(
        `SELECT emergency_type, COUNT(*) AS count
         FROM incidents
         WHERE created_at >= NOW() - $1::INTERVAL
         GROUP BY emergency_type
         ORDER BY count DESC`,
        [interval]
      ),
      // Fleet status snapshot
      db.query(
        `SELECT status, COUNT(*) AS count
         FROM ambulances
         GROUP BY status`
      ),
    ]);

    res.json({
      period,
      ...overview.rows[0],
      by_status:         byStatus.rows,
      by_emergency_type: byType.rows,
      fleet_summary:     fleet.rows,
    });
  } catch (err) {
    next(err);
  }
});

// ─── POST /api/dispatchers/assign ─────────────────────────────────────────────
const assignSchema = z.object({
  incident_id:  z.string().min(1),
  ambulance_id: z.string().min(1),
});

router.post('/dispatchers/assign', requireAuth, validate(assignSchema), async (req, res, next) => {
  try {
    const { incident_id, ambulance_id } = req.body;

    // Verify ambulance exists and is available (or we're re-assigning)
    const ambRes = await db.query(
      `SELECT a.id, a.name, a.status, a.paramedic_id,
              ST_X(a.location::GEOMETRY) AS lng,
              ST_Y(a.location::GEOMETRY) AS lat,
              u.fcm_token AS paramedic_fcm
       FROM ambulances a
       LEFT JOIN users u ON u.id = a.paramedic_id
       WHERE a.id = $1`,
      [ambulance_id]
    );
    if (!ambRes.rows.length) return res.status(404).json({ error: 'Ambulance not found' });

    const incRes = await db.query(
      `UPDATE incidents
       SET assigned_ambulance_id = $1, status = 'dispatched', updated_at = NOW()
       WHERE id = $2 RETURNING *`,
      [ambulance_id, incident_id]
    );
    if (!incRes.rowCount) return res.status(404).json({ error: 'Incident not found' });

    // Mark ambulance on_mission
    await db.query(
      "UPDATE ambulances SET status = 'on_mission', updated_at = NOW() WHERE id = $1",
      [ambulance_id]
    );

    // FCM to paramedic
    const amb = ambRes.rows[0];
    if (amb.paramedic_fcm) {
      await sendPush(
        amb.paramedic_fcm,
        '🚨 Assignment Updated',
        `You have been assigned to incident ${incident_id}`,
        { incident_id, type: 'assign' }
      );
    }

    res.json({ message: 'Ambulance assigned', incident: incRes.rows[0] });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
