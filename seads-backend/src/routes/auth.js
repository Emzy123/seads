'use strict';

const { z }        = require('zod');
const db           = require('../config/db');
const requireAuth  = require('../middleware/auth');
const validate     = require('../middleware/validate');

const router = require('express').Router();

// ─── Schemas ────────────────────────────────────────────────────────────────
const registerSchema = z.object({
  firebase_uid: z.string().min(1),
  email:        z.string().email(),
  name:         z.string().min(1).max(120),
  phone:        z.string().optional().default(''),
  role:         z.enum(['patient', 'paramedic', 'dispatcher']),
});

const loginSchema = z.object({
  firebase_uid: z.string().min(1),
  email:        z.string().email(),
});

// ─── POST /api/auth/register ─────────────────────────────────────────────────
router.post('/register', validate(registerSchema), async (req, res, next) => {
  try {
    const { firebase_uid, email, name, phone, role } = req.body;

    const { rows } = await db.query(
      `INSERT INTO users (id, email, name, phone, role)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (id) DO UPDATE
         SET email = EXCLUDED.email,
             name  = EXCLUDED.name,
             phone = EXCLUDED.phone
       RETURNING *`,
      [firebase_uid, email, name, phone || '', role]
    );

    res.status(201).json({ user: rows[0] });
  } catch (err) {
    next(err);
  }
});

// ─── POST /api/auth/login ────────────────────────────────────────────────────
router.post('/login', validate(loginSchema), async (req, res, next) => {
  try {
    const { firebase_uid, email } = req.body;

    const { rows } = await db.query(
      `INSERT INTO users (id, email, name, phone, role)
       VALUES ($1, $2, '', '', 'patient')
       ON CONFLICT (id) DO UPDATE
         SET email      = EXCLUDED.email,
             updated_at = NOW()
       RETURNING *`,
      [firebase_uid, email]
    );

    res.json({ user: rows[0] });
  } catch (err) {
    next(err);
  }
});

// ─── GET /api/auth/me ────────────────────────────────────────────────────────
router.get('/me', requireAuth, async (req, res, next) => {
  try {
    const { rows } = await db.query(
      'SELECT * FROM users WHERE id = $1',
      [req.uid]
    );
    if (!rows.length) return res.status(404).json({ error: 'User not found' });
    res.json({ user: rows[0] });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
