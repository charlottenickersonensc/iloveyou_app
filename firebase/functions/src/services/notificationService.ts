import {FieldValue} from "firebase-admin/firestore";
import {failedPrecondition, invalidArgument, notFound} from "../utils/errors";
import {notificationsRef, usersRef} from "../utils/firestoreRefs";
import {validateInputObject} from "../validators/feedValidation";

export type MarkNotificationReadInput = unknown;

type AppUserData = {
  fruitCommunityId: string;
};

export async function markNotificationReadForUid(
  uid: string,
  input: MarkNotificationReadInput
): Promise<{notificationId: string; isRead: true}> {
  const data = validateInputObject(input);
  assertOnlyAllowedKeys(data, ["notificationId"]);
  const notificationId = validateId(data.notificationId, "notificationId");
  const user = await loadUser(uid);
  const notificationRef = notificationsRef().doc(notificationId);
  const snapshot = await notificationRef.get();

  if (!snapshot.exists) {
    throw notFound("Notification not found.");
  }
  const notification = snapshot.data();
  if (
    !notification ||
    notification.userId !== uid ||
    notification.fruitCommunityId !== user.fruitCommunityId
  ) {
    throw notFound("Notification not found.");
  }

  if (notification.isRead !== true) {
    await notificationRef.update({
      isRead: true,
      readAt: FieldValue.serverTimestamp()
    });
  }

  return {notificationId, isRead: true};
}

async function loadUser(uid: string): Promise<AppUserData> {
  const snapshot = await usersRef().doc(uid).get();
  const data = snapshot.data();
  if (!snapshot.exists || !data || typeof data.fruitCommunityId !== "string") {
    throw failedPrecondition("Complete signup before using notifications.");
  }
  return {fruitCommunityId: data.fruitCommunityId};
}

function assertOnlyAllowedKeys(input: Record<string, unknown>, allowedKeys: string[]): void {
  const allowed = new Set(allowedKeys);
  for (const key of Object.keys(input)) {
    if (!allowed.has(key)) {
      throw invalidArgument("Notification fields are assigned by the server.", {field: key});
    }
  }
}

function validateId(value: unknown, field: string): string {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw invalidArgument(`${field} is required.`, {field});
  }
  return value.trim();
}
