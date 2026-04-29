import fs from "fs";
import path from "path";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment
} from "@firebase/rules-unit-testing";
import {doc, serverTimestamp, setDoc, updateDoc} from "firebase/firestore";

const projectId = "iloveyou-dev";
let testEnv: RulesTestEnvironment;

describe("Firestore fruit immutability rules", () => {
  beforeAll(async () => {
    testEnv = await initializeTestEnvironment({
      projectId,
      firestore: {
        rules: fs.readFileSync(path.resolve(__dirname, "../../firestore.rules"), "utf8")
      }
    });
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), "users/alice"), {
        id: "alice",
        email: "alice@example.com",
        username: "alice",
        displayUsername: "Alice",
        fruitCommunityId: "apple",
        fruitCode: "apple",
        role: "user",
        isCaptain: false,
        createdAt: serverTimestamp(),
        memberSince: serverTimestamp(),
        updatedAt: serverTimestamp(),
        profileCompleted: false
      });
    });
  });

  afterAll(async () => {
    await testEnv?.cleanup();
  });

  it("allows mutable profile updates", async () => {
    const db = testEnv.authenticatedContext("alice").firestore();
    await assertSucceeds(updateDoc(doc(db, "users/alice"), {
      bio: "Fresh bio",
      profileCompleted: true,
      updatedAt: serverTimestamp()
    }));
  });

  it("rejects client fruitCommunityId mutation", async () => {
    const db = testEnv.authenticatedContext("alice").firestore();
    await assertFails(updateDoc(doc(db, "users/alice"), {
      fruitCommunityId: "banana",
      fruitCode: "banana",
      updatedAt: serverTimestamp()
    }));
  });
});
