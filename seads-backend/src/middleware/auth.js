'use strict';

const admin = require('../config/firebase');

/**
 * Express middleware — verifies Firebase ID token from Authorization header.
 * On success: sets req.uid (Firebase UID string).
 * On failure: returns 401.
 */
async function requireAuth(req, res, next) {
  const header = req.headers['authorization'] || '';
  const token  = header.startsWith('Bearer ') ? header.slice(7).trim() : null;

  if (!token) {
    return res.status(401).json({ error: 'Missing Authorization header' });
  }

  try {
    const decoded = await admin.auth().verifyIdToken(token);
    req.uid = decoded.uid;
    next();
  } catch (err) {
    console.warn('[Auth] Token verification failed:', err.code || err.message);
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}

module.exports = requireAuth;
