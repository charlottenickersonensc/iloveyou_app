import {initializeApp, getApps, deleteApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {getFirestore} from "firebase-admin/firestore";
import {FRUIT_COMMUNITIES} from "../src/constants/fruits";
import {completeUserSignupForUid} from "../src/services/signupService";

const projectId = "iloveyou-dev";

function ensureAdminApp() {
  if (getApps().length === 0) {
    initializeApp({projectId});
  }
}

async function clearFirestore() {
  const db = getFirestore();
  const collections = await db.listCollections();
  for (const collection of collections) {
    const docs = await collection.listDocuments();
    await Promise.all(docs.map((doc) => doc.delete()));
  }
}

async function seedFruits() {
  const db = getFirestore();
  const batch = db.batch();
  for (const fruit of FRUIT_COMMUNITIES) {
    batch.set(db.collection("fruitCommunities").doc(fruit.id), fruit);
  }
  await batch.commit();
}

async function clearAuthUsers() {
  const auth = getAuth();
  const users = await auth.listUsers();
  if (users.users.length > 0) {
    await auth.deleteUsers(users.users.map((user) => user.uid));
  }
}

describe("completeUserSignupForUid", () => {
  beforeAll(() => {
    process.env.GCLOUD_PROJECT = projectId;
    ensureAdminApp();
  });

  beforeEach(async () => {
    await clearAuthUsers();
    await clearFirestore();
    await seedFruits();
  });

  afterAll(async () => {
    await Promise.all(getApps().map((app) => deleteApp(app)));
  });

  it("assigns exactly one seeded fruit to a new authenticated user", async () => {
    const uid = "signup_user_a";
    await getAuth().createUser({uid, email: "a@example.com", password: "abc123!"});

    const result = await completeUserSignupForUid(uid, {
      username: "fruitfan",
      displayUsername: "Fruit Fan",
      dateOfBirth: "2000-01-01"
    });

    expect(FRUIT_COMMUNITIES.map((fruit) => fruit.id)).toContain(result.user.fruitCommunityId);
    expect(result.user.fruitCommunityId).toBe(result.user.fruitCode);
    expect(result.user.profileCompleted).toBe(false);
  });

  it("rejects duplicate usernames", async () => {
    await getAuth().createUser({uid: "signup_user_b", email: "b@example.com", password: "abc123!"});
    await getAuth().createUser({uid: "signup_user_c", email: "c@example.com", password: "abc123!"});

    await completeUserSignupForUid("signup_user_b", {
      username: "taken_name",
      displayUsername: "Taken One",
      dateOfBirth: "2000-01-01"
    });

    await expect(completeUserSignupForUid("signup_user_c", {
      username: "taken_name",
      displayUsername: "Taken Two",
      dateOfBirth: "2000-01-01"
    })).rejects.toMatchObject({code: "already-exists"});
  });

  it("does not change fruit on a repeated signup call for the same uid", async () => {
    const uid = "signup_user_d";
    await getAuth().createUser({uid, email: "d@example.com", password: "abc123!"});

    const first = await completeUserSignupForUid(uid, {
      username: "repeat_user",
      displayUsername: "Repeat User",
      dateOfBirth: "2000-01-01"
    });
    const second = await completeUserSignupForUid(uid, {
      username: "new_name",
      displayUsername: "Changed Name",
      dateOfBirth: "2000-01-01"
    });

    expect(second.user.fruitCommunityId).toBe(first.user.fruitCommunityId);
    expect(second.user.username).toBe("repeat_user");
  });
});
