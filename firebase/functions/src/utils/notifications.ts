import {FieldValue} from "firebase-admin/firestore";
import {notificationsRef} from "./firestoreRefs";

type NotificationType = "friend_request" | "like" | "comment";
type EntityType = "friendship" | "post";

type NotificationInput = {
  userId: string;
  actorId: string;
  type: NotificationType;
  entityType: EntityType;
  entityId: string;
  fruitCommunityId: string;
  title: string;
  body: string;
};

export function notificationRef() {
  return notificationsRef().doc();
}

export function buildNotification(id: string, input: NotificationInput) {
  return {
    id,
    userId: input.userId,
    actorId: input.actorId,
    type: input.type,
    entityType: input.entityType,
    entityId: input.entityId,
    fruitCommunityId: input.fruitCommunityId,
    title: input.title,
    body: input.body,
    isRead: false,
    createdAt: FieldValue.serverTimestamp()
  };
}
