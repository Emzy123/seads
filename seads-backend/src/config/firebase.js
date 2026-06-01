'use strict';

const admin = require('firebase-admin');

if (!admin.apps.length) {
  const b64 = process.env.FIREBASE_SERVICE_ACCOUNT_BASE64;
  if (!b64) {
    console.warn('[Firebase] FIREBASE_SERVICE_ACCOUNT_BASE64 not set — auth middleware will reject all requests.');
  } else {
    try {
      const serviceAccount = JSON.parse(
        Buffer.from(b64, 'base64').toString('utf-8')
      );
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      console.log('[Firebase] Admin SDK initialised ✓');
    } catch (err) {
      console.error('[Firebase] Failed to parse service account:', err.message);
      process.exit(1);
    }
  }
}

module.exports = admin;
