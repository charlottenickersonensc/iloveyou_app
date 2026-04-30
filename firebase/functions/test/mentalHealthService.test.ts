import {initializeApp, getApps, deleteApp} from "firebase-admin/app";
import {getFirestore, Timestamp} from "firebase-admin/firestore";
import {
  getTodayAffirmationForUid,
  submitMoodCheckinForUid
} from "../src/services/mentalHealthService";

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

function todayDateId(): string {
  return new Date().toISOString().slice(0, 10);
}

function compactDateId(date: string): string {
  return date.replace(/-/g, "");
}

describe("mental health service", () => {
  beforeAll(() => {
    process.env.GCLOUD_PROJECT = projectId;
    ensureAdminApp();
  });

  beforeEach(async () => {
    await clearFirestore();
    await seedUser("apple_alice", "apple");
  });

  afterAll(async () => {
    await Promise.all(getApps().map((app) => deleteApp(app)));
  });

  it("upserts today's mood check-in with server-owned fruit scope", async () => {
    const today = todayDateId();
    const first = await submitMoodCheckinForUid("apple_alice", {
      date: today,
      mood: "okay",
      note: "  Holding steady  "
    });

    expect(first.checkin.id).toBe(`apple_alice_${compactDateId(today)}`);
    expect(first.checkin.userId).toBe("apple_alice");
    expect(first.checkin.fruitCommunityId).toBe("apple");
    expect(first.checkin.note).toBe("Holding steady");

    const second = await submitMoodCheckinForUid("apple_alice", {
      date: today,
      mood: "good",
      note: null
    });
    expect(second.checkin.id).toBe(first.checkin.id);
    expect(second.checkin.mood).toBe("good");
    expect(second.checkin.note).toBeNull();

    const saved = await getFirestore().collection("moodCheckins").doc(first.checkin.id).get();
    expect(saved.data()?.mood).toBe("good");
    expect(saved.data()?.fruitCommunityId).toBe("apple");
  });

  it("rejects protected mood fields, invalid moods, and non-today dates", async () => {
    const today = todayDateId();

    await expect(submitMoodCheckinForUid("apple_alice", {
      date: today,
      mood: "okay",
      fruitCommunityId: "banana"
    })).rejects.toMatchObject({code: "invalid-argument"});

    await expect(submitMoodCheckinForUid("apple_alice", {
      date: today,
      mood: "angry"
    })).rejects.toMatchObject({code: "invalid-argument"});

    await expect(submitMoodCheckinForUid("apple_alice", {
      date: "2020-01-01",
      mood: "okay"
    })).rejects.toMatchObject({code: "invalid-argument"});
  });

  it("returns scheduled affirmation when active and fallback when missing", async () => {
    const today = todayDateId();
    await getFirestore().collection("dailyAffirmations").doc(today).set({
      id: today,
      text: "You are grounded.",
      active: true,
      createdAt: Timestamp.now()
    });

    const scheduled = await getTodayAffirmationForUid("apple_alice", {});
    expect(scheduled.affirmation.text).toBe("You are grounded.");
    expect(scheduled.affirmation.source).toBe("scheduled");

    await getFirestore().collection("dailyAffirmations").doc(today).delete();
    const fallback = await getTodayAffirmationForUid("apple_alice", {});
    expect(fallback.affirmation.text.length).toBeGreaterThan(0);
    expect(fallback.affirmation.source).toBe("fallback");
  });
});
