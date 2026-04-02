/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {setGlobalOptions} from "firebase-functions";
// import {onRequest} from "firebase-functions/https";
// import * as logger from "firebase-functions/logger";

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({maxInstances: 10});

// export const helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });


// added below
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

admin.initializeApp(); // start Firebase Admin SDK inside Cloud Function.
const db = admin.firestore(); // creates a Firestore database connection.


/**
 * Delete invalid token docs under users/{uid}/tokens/{token}
 */
async function cleanupInvalidTokens(uid: string, tokensToRemove: string[]) {
  if (!tokensToRemove || tokensToRemove.length === 0) return;
  try {
    const deletes = tokensToRemove.map((token) =>
      db.collection("users").doc(uid).collection("tokens").doc(token).delete()
    );
    await Promise.all(deletes);
    console.log(`Removed ${tokensToRemove.length} invalid token(s) for user ${uid}`);
  } catch (err) {
    console.warn(`Failed to cleanup tokens for ${uid}:`, err);
  }
}

/**
 * Trigger: threads/{threadId}/messages/{messageId} onCreate
 * Uses only users/{uid}/tokens/{token} subcollection (no legacy fallback).
 */
export const onMessageCreated = onDocumentCreated(
  "threads/{threadId}/messages/{messageId}",
  async (event) => {
    try {
      const message = event.data?.data() as any;
      if (!message) {
        console.log("No message data");
        return null;
      }

      const threadId = event.params.threadId as string;
      const senderId = message.senderId as string | undefined;
      const senderName = (message.senderName as string) || "New message";
      const text = (message.text as string) || "";

      // Read thread doc to obtain participants
      const threadRef = db.collection("threads").doc(threadId);
      const threadSnap = await threadRef.get();
      if (!threadSnap.exists) {
        console.log(`Thread ${threadId} not found`);
        return null;
      }

      const threadData = threadSnap.data() as any;
      const users: string[] = Array.isArray(threadData?.users) ? threadData.users : [];
      const recipients = users.filter((uid) => uid !== senderId);
      if (recipients.length === 0) {
        console.log("No recipients after excluding sender");
        return null;
      }

      // Fetch tokens for all recipients in parallel (prefer subcollection)
      const tokenOwnerPromises = recipients.map(async (uid) => {
        try {
          const tokenSnap = await db.collection("users").doc(uid).collection("tokens").get();
          if (tokenSnap.empty) return [] as { uid: string; token: string }[];
          return tokenSnap.docs.map((d) => ({ uid, token: d.id }));
        } catch (err) {
          console.warn(`Failed to read tokens for user ${uid}:`, err);
          return [] as { uid: string; token: string }[];
        }
      });

      const tokenOwnersNested = await Promise.all(tokenOwnerPromises);
      const tokenOwners = tokenOwnersNested.flat();

      if (tokenOwners.length === 0) {
        console.log("No tokens found for any recipients");
        return null;
      }

      // Build payload
      const notification = {
        title: senderName,
        body: text.length > 120 ? text.slice(0, 120) + "…" : text || "New message",
      };

      const dataPayload: { [k: string]: string } = {
        threadId,
        messageId: event.params.messageId || "",
        senderId: senderId || "",
      };

      // Send in batches (max 500 tokens per sendMulticast)
      const BATCH = 500;
      for (let i = 0; i < tokenOwners.length; i += BATCH) {
        const batch = tokenOwners.slice(i, i + BATCH);
        const tokens = batch.map((b) => b.token);

        const multicastMessage: admin.messaging.MulticastMessage = {
          notification,
          data: dataPayload,
          tokens,
          android: { priority: "high" },
          apns: { headers: { "apns-priority": "10" } },
        };

        try {
          const resp = await admin.messaging().sendMulticast(multicastMessage);
          console.log(
            `Batch ${Math.floor(i / BATCH) + 1}: success=${resp.successCount} failure=${resp.failureCount}`
          );

          // Collect tokens to delete per uid for common invalid-token errors
          const tokensToRemoveByUid = new Map<string, string[]>();
          resp.responses.forEach((r, idx) => {
            if (!r.success) {
              const err = r.error;
              const failedToken = tokens[idx];
              const code = (err && (err as any).code) || "";

              if (
                code === "messaging/registration-token-not-registered" ||
                code === "messaging/invalid-registration-token" ||
                code === "messaging/invalid-argument"
              ) {
                const ownerUid = batch[idx].uid;
                const arr = tokensToRemoveByUid.get(ownerUid) || [];
                arr.push(failedToken);
                tokensToRemoveByUid.set(ownerUid, arr);
              } else {
                console.warn("FCM send error for token", failedToken, err);
              }
            }
          });

          // Delete invalid token docs
          for (const [uid, toks] of tokensToRemoveByUid.entries()) {
            await cleanupInvalidTokens(uid, toks);
          }
        } catch (err) {
          console.error("Error sending multicast:", err);
        }
      }

      console.log("Notification processing finished");
      return null;
    } catch (err) {
      console.error("Unexpected error in onMessageCreated:", err);
      return null;
    }
  }
);