import {initializeApp, getApps, deleteApp} from "firebase-admin/app";
import {getFirestore, Timestamp} from "firebase-admin/firestore";
import {markNotificationReadForUid} from "../src/services/notificationService";

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
    displayUsername: uid,
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

async function seedNotification(
  id: string,
  userId: string,
  fruitCommunityId: string,
  isRead = false
) {
  await getFirestore().collection("notifications").doc(id).set({
    id,
    userId,
    actorId: "actor",
    type: "like",
    entityType: "post",
    entityId: "post_1",
    fruitCommunityId,
    title: "New like",
    body: "Someone liked your post.",
    isRead,
    readAt: null,
    createdAt: Timestamp.now()
  });
}

describe("notification service", () => {
  beforeAll(() => {
    process.env.GCLOUD_PROJECT = projectId;
    ensureAdminApp();
  });

  beforeEach(async () => {
    await clearFirestore();
    await seedUser("apple_user", "apple");
    await seedUser("banana_user", "banana");
    await seedNotification("note_1", "apple_user", "apple");
  });

  afterAll(async () => {
    await Promise.all(getApps().map((app) => deleteApp(app)));
  });

  it("marks the authenticated user's same-fruit notification read", async () => {
    const result = await markNotificationReadForUid("apple_user", {notificationId: "note_1"});

    const saved = await getFirestore().collection("notifications").doc("note_1").get();
    expect(result).toEqual({notificationId: "note_1", isRead: true});
    expect(saved.data()?.isRead).toBe(true);
    expect(saved.data()?.readAt).toBeTruthy();
    expect(saved.data()?.fruitCommunityId).toBe("apple");
  });

  it("rejects protected client fields", async () => {
    await expect(markNotificationReadForUid("apple_user", {
      notificationId: "note_1",
      fruitCommunityId: "banana"
    })).rejects.toMatchObject({code: "invalid-argument"});
  });

  it("rejects another user's or cross-fruit notification", async () => {
    await seedNotification("wrong_fruit", "apple_user", "banana");

    await expect(markNotificationReadForUid("banana_user", {notificationId: "note_1"}))
      .rejects.toMatchObject({code: "not-found"});
    await expect(markNotificationReadForUid("apple_user", {notificationId: "wrong_fruit"}))
      .rejects.toMatchObject({code: "not-found"});
  });
});
