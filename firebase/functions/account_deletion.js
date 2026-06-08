const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');

/**
 * Processes account_deletion_requests: deletes Auth user and user profile doc.
 */
exports.onAccountDeletionRequestCreate = functions.firestore
  .document('account_deletion_requests/{requestId}')
  .onCreate(async (snap, context) => {
    const data = snap.data() || {};
    const userId = data.userId;
    if (!userId) {
      await snap.ref.update({
        status: 'failed',
        error: 'missing_userId',
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return null;
    }

    const db = admin.firestore();
    try {
      await db.collection('user').doc(userId).set(
        {
          accountStatus: 'deleted',
          deletedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      await db.collection('user').doc(userId).delete();

      try {
        await admin.auth().deleteUser(userId);
      } catch (authErr) {
        if (authErr.code !== 'auth/user-not-found') {
          throw authErr;
        }
      }

      await snap.ref.update({
        status: 'completed',
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (error) {
      console.error('account_deletion failed', userId, error);
      await snap.ref.update({
        status: 'failed',
        error: String(error.message || error),
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    return null;
  });
