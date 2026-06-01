'use strict';

const { z }       = require('zod');
const db          = require('../config/db');
const requireAuth = require('../middleware/auth');
const validate    = require('../middleware/validate');

const router = require('express').Router();

// ─── GET /api/users/:userId ──────────────────────────────────────────────────
router.get('/:userId', requireAuth, async (req, res, next) => {
  try {
    const { rows } = await db.query(
      'SELECT * FROM users WHERE id = $1',
      [req.params.userId]
    );
    if (!rows.length) return res.status(404).json({ error: 'User not found' });
    res.json({ user: rows[0] });
  } catch (err) {
    next(err);
  }
});

// ─── POST /api/users/role ────────────────────────────────────────────────────
const roleSchema = z.object({
  role: z.enum(['patient', 'paramedic', 'dispatcher']),
});

router.post('/role', requireAuth, validate(roleSchema), async (req, res, next) => {
  try {
    const { rows } = await db.query(
      'UPDATE users SET role = $1, updated_at = NOW() WHERE id = $2 RETURNING *',
      [req.body.role, req.uid]
    );
    if (!rows.length) return res.status(404).json({ error: 'User not found' });
    res.json({ user: rows[0] });
  } catch (err) {
    next(err);
  }
});

// ─── PUT /api/users/profile ──────────────────────────────────────────────────
const profileSchema = z.object({
  name:  z.string().min(1).max(120).optional(),
  phone: z.string().max(30).optional(),
  email: z.string().email().optional(),
}).strict();

router.put('/profile', requireAuth, validate(profileSchema), async (req, res, next) => {
  try {
    const updates = req.body;
    const fields  = Object.keys(updates);
    if (!fields.length) return res.status(422).json({ error: 'No fields to update' });

    const setClauses = fields.map((f, i) => `${f} = $${i + 1}`);
    const values     = fields.map(f => updates[f]);

    const { rows } = await db.query(
      `UPDATE users SET ${setClauses.join(', ')}, updated_at = NOW()
       WHERE id = $${fields.length + 1} RETURNING *`,
      [...values, req.uid]
    );
    if (!rows.length) return res.status(404).json({ error: 'User not found' });
    res.json({ user: rows[0] });
  } catch (err) {
    next(err);
  }
});

// ─── POST /api/users/fcm-token ───────────────────────────────────────────────
const fcmSchema = z.object({
  fcm_token: z.string().min(1),
});

router.post('/fcm-token', requireAuth, validate(fcmSchema), async (req, res, next) => {
  try {
    await db.query(
      'UPDATE users SET fcm_token = $1, updated_at = NOW() WHERE id = $2',
      [req.body.fcm_token, req.uid]
    );
    res.json({ message: 'FCM token saved' });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
