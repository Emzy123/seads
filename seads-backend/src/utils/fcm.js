'use strict';

const admin    = require('../config/firebase');

/**
 * Send a Firebase Cloud Messaging push notification.
 *
 * @param {string} fcmToken  Recipient device FCM token
 * @param {string} title     Notification title
 * @param {string} body      Notification body
 * @param {Record<string,string>} data  Extra key/value data payload
 */
async function sendPush(fcmToken, title, body, data = {}) {
  if (!fcmToken) return;
  try {
    await admin.messaging().send({
      token: fcmToken,
      notification: { title, body },
      data: Object.fromEntries(
        Object.entries(data).map(([k, v]) => [k, String(v)])
      ),
      android: {
        priority: 'high',
        notification: { channelId: 'seads_emergency' },
      },
      apns: {
        payload: { aps: { sound: 'default', badge: 1 } },
      },
    });
  } catch (err) {
    // Log but never crash the request if FCM fails
    console.warn('[FCM] Push failed:', err.code || err.message);
  }
}

module.exports = { sendPush };
