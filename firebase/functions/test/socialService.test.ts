import {initializeApp, getApps, deleteApp} from "firebase-admin/app";
import {getFirestore, Timestamp} from "firebase-admin/firestore";
import {
  respondToFriendRequestForUid,
  sendFriendRequestForUid
} from "../src/services/socialService";

const projectId = "iloveyou-dev";

function ensureAdminApp() {
  if (getApps().length === 0) {
    initializeApp({projectId});
  }
}

async function clearFirestore() {
  const db = getFirestore();
  const collections = await db.listCollections();
  await Promise.all(collections.map((collection) => db.recursiveDelete(collection)));
}

async function seedUser(uid: string, fruitCommunityId: string) {
  await getFirestore().collection("users").doc(uid).set({
    id: uid,
    email: `${uid}@example.com`,
    username: uid,
    displayUsername: uid.replace("_", " "),
    avatarUrl: null,
    fruitCommunityId,
    fruitCode: fruitCommunityId,
    role: "user",
    isCaptain: false,
    createdAt: Timestamp.now(),
    memberSince: Timestamp.now(),
    updatedAt: Timestamp.now(),
    profileCompleted: true
  });
}

describe("social service", () => {
  beforeAll(() => {
    process.env.GCLOUD_PROJECT = projectId;
    ensureAdminApp();
  });

  beforeEach(async () => {
    await clearFirestore();
    await seedUser("apple_alice", "apple");
    await seedUser("apple_bob", "apple");
    await seedUser("banana_bea", "banana");
  });

  afterAll(async () => {
    await Promise.all(getApps().map((app) => deleteApp(app)));
  });

  it("creates a same-fruit pending friendship and notification", async () => {
    const result = await sendFriendRequestForUid("apple_alice", {receiverId: "apple_bob"});

    expect(result.created).toBe(true);
    expect(result.friendship.fruitCommunityId).toBe("apple");
    expect(result.friendship.status).toBe("pending");
    expect(result.friendship.participantIds).toEqual(["apple_alice", "apple_bob"]);

    const notifications = await getFirestore().collection("notifications")
      .where("userId", "==", "apple_bob")
      .where("type", "==", "friend_request")
      .get();
    expect(notifications.size).toBe(1);
    expect(notifications.docs[0].data().fruitCommunityId).toBe("apple");
  });

  it("rejects self and cross-fruit friend requests", async () => {
    await expect(sendFriendRequestForUid("apple_alice", {receiverId: "apple_alice"}))
      .rejects.toMatchObject({code: "invalid-argument"});
    await expect(sendFriendRequestForUid("apple_alice", {receiverId: "banana_bea"}))
      .rejects.toMatchObject({code: "failed-precondition"});
  });

  it("accepts and declines only by the receiver", async () => {
    const request = await sendFriendRequestForUid("apple_alice", {receiverId: "apple_bob"});

    await expect(respondToFriendRequestForUid("apple_alice", {
      friendshipId: request.friendship.id,
      action: "accept"
    })).rejects.toMatchObject({code: "failed-precondition"});

    const accepted = await respondToFriendRequestForUid("apple_bob", {
      friendshipId: request.friendship.id,
      action: "accept"
    });
    expect(accepted.accepted).toBe(true);
    expect(accepted.friendship?.status).toBe("accepted");

    const secondRequest = await sendFriendRequestForUid("apple_bob", {receiverId: "apple_alice"});
    expect(secondRequest.created).toBe(false);
  });

  it("deletes a pending friendship on decline", async () => {
    const request = await sendFriendRequestForUid("apple_alice", {receiverId: "apple_bob"});

    const declined = await respondToFriendRequestForUid("apple_bob", {
      friendshipId: request.friendship.id,
      action: "decline"
    });

    expect(declined.accepted).toBe(false);
    const saved = await getFirestore().collection("friendships").doc(request.friendship.id).get();
    expect(saved.exists).toBe(false);
  });
});
