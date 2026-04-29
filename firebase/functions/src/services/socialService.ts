import {Timestamp} from "firebase-admin/firestore";
import {failedPrecondition, invalidArgument, notFound} from "../utils/errors";
import {firestore, friendshipsRef, usersRef} from "../utils/firestoreRefs";
import {buildNotification, notificationRef} from "../utils/notifications";
import {validateInputObject} from "../validators/feedValidation";

type AppUserData = {
  id: string;
  displayUsername: string;
  fruitCommunityId: string;
};

export type Friendship = {
  id: string;
  userLowId: string;
  userHighId: string;
  requesterId: string;
  receiverId: string;
  participantIds: string[];
  fruitCommunityId: string;
  status: "pending" | "accepted" | "blocked";
  createdAt: Timestamp;
  updatedAt: Timestamp;
  acceptedAt: Timestamp | null;
  blockedAt: Timestamp | null;
};

export type SendFriendRequestInput = unknown;
export type RespondToFriendRequestInput = unknown;

export async function sendFriendRequestForUid(
  uid: string,
  input: SendFriendRequestInput
): Promise<{friendship: FirebaseFirestore.DocumentData | Friendship; created: boolean}> {
  const data = validateInputObject(input);
  const receiverId = validateId(data.receiverId, "receiverId");
  if (receiverId === uid) {
    throw invalidArgument("You cannot send a friend request to yourself.", {field: "receiverId"});
  }

  const requesterRef = usersRef().doc(uid);
  const receiverRef = usersRef().doc(receiverId);
  const friendshipId = friendshipIdFor(uid, receiverId);
  const friendshipRef = friendshipsRef().doc(friendshipId);
  const now = Timestamp.now();

  return firestore().runTransaction(async (transaction) => {
    const [requesterSnapshot, receiverSnapshot, friendshipSnapshot] = await Promise.all([
      transaction.get(requesterRef),
      transaction.get(receiverRef),
      transaction.get(friendshipRef)
    ]);
    const requester = requireUser(requesterSnapshot, uid);
    const receiver = requireUser(receiverSnapshot, receiverId);
    if (requester.fruitCommunityId !== receiver.fruitCommunityId) {
      throw failedPrecondition("Friend requests are limited to your fruit community.");
    }

    if (friendshipSnapshot.exists) {
      const existing = friendshipSnapshot.data() ?? {};
      if (existing.status === "blocked") {
        throw failedPrecondition("This friendship is blocked.");
      }
      return {friendship: existing, created: false};
    }

    const [userLowId, userHighId] = uid < receiverId ? [uid, receiverId] : [receiverId, uid];
    const friendship: Friendship = {
      id: friendshipId,
      userLowId,
      userHighId,
      requesterId: uid,
      receiverId,
      participantIds: [userLowId, userHighId],
      fruitCommunityId: requester.fruitCommunityId,
      status: "pending",
      createdAt: now,
      updatedAt: now,
      acceptedAt: null,
      blockedAt: null
    };
    transaction.set(friendshipRef, friendship);

    const ref = notificationRef();
    transaction.set(ref, buildNotification(ref.id, {
      userId: receiverId,
      actorId: uid,
      type: "friend_request",
      entityType: "friendship",
      entityId: friendshipId,
      fruitCommunityId: requester.fruitCommunityId,
      title: "New friend request",
      body: `${requester.displayUsername} sent you a friend request.`
    }));

    return {friendship, created: true};
  });
}

export async function respondToFriendRequestForUid(
  uid: string,
  input: RespondToFriendRequestInput
): Promise<{friendship?: FirebaseFirestore.DocumentData; friendshipId: string; accepted: boolean}> {
  const data = validateInputObject(input);
  const friendshipId = validateId(data.friendshipId, "friendshipId");
  const action = validateFriendAction(data.action);
  const friendshipRef = friendshipsRef().doc(friendshipId);
  const now = Timestamp.now();

  return firestore().runTransaction(async (transaction) => {
    const friendshipSnapshot = await transaction.get(friendshipRef);
    if (!friendshipSnapshot.exists) {
      throw notFound("Friend request not found.");
    }
    const friendship = friendshipSnapshot.data() ?? {};
    if (friendship.receiverId !== uid) {
      throw failedPrecondition("Only the receiver can respond to this friend request.");
    }
    if (friendship.status !== "pending") {
      throw failedPrecondition("This friend request is no longer pending.");
    }

    if (action === "decline") {
      transaction.delete(friendshipRef);
      return {friendshipId, accepted: false};
    }

    const updated = {
      ...friendship,
      status: "accepted",
      updatedAt: now,
      acceptedAt: now
    };
    transaction.update(friendshipRef, {
      status: "accepted",
      updatedAt: now,
      acceptedAt: now
    });

    return {friendship: updated, friendshipId, accepted: true};
  });
}

function requireUser(snapshot: FirebaseFirestore.DocumentSnapshot, uid: string): AppUserData {
  if (!snapshot.exists) {
    throw notFound("User not found.", {uid});
  }
  const data = snapshot.data();
  if (
    !data ||
    typeof data.displayUsername !== "string" ||
    typeof data.fruitCommunityId !== "string"
  ) {
    throw failedPrecondition("User profile is missing required social fields.", {uid});
  }
  return {
    id: uid,
    displayUsername: data.displayUsername,
    fruitCommunityId: data.fruitCommunityId
  };
}

function friendshipIdFor(uidA: string, uidB: string): string {
  const [userLowId, userHighId] = uidA < uidB ? [uidA, uidB] : [uidB, uidA];
  return `${userLowId}_${userHighId}`;
}

function validateId(value: unknown, field: string): string {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw invalidArgument(`${field} is required.`, {field});
  }
  return value.trim();
}

function validateFriendAction(value: unknown): "accept" | "decline" {
  if (value !== "accept" && value !== "decline") {
    throw invalidArgument("Choose a valid friend request action.", {field: "action"});
  }
  return value;
}
