import fs from "fs";
import path from "path";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment
} from "@firebase/rules-unit-testing";
import {
  collection,
  doc,
  getDoc,
  getDocs,
  limit,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where
} from "firebase/firestore";

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
      const db = context.firestore();
      await setDoc(doc(db, "users/alice"), {
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
      await setDoc(doc(db, "users/bob"), {
        id: "bob",
        email: "bob@example.com",
        username: "bob",
        displayUsername: "Bob",
        fruitCommunityId: "banana",
        fruitCode: "banana",
        role: "user",
        isCaptain: false,
        createdAt: serverTimestamp(),
        memberSince: serverTimestamp(),
        updatedAt: serverTimestamp(),
        profileCompleted: false
      });
      await setDoc(doc(db, "users/carol"), {
        id: "carol",
        email: "carol@example.com",
        username: "carol",
        displayUsername: "Carol",
        fruitCommunityId: "apple",
        fruitCode: "apple",
        role: "user",
        isCaptain: false,
        createdAt: serverTimestamp(),
        memberSince: serverTimestamp(),
        updatedAt: serverTimestamp(),
        profileCompleted: false
      });
      await setDoc(doc(db, "users/dana"), {
        id: "dana",
        email: "dana@example.com",
        username: "dana",
        displayUsername: "Dana",
        fruitCommunityId: "apple",
        fruitCode: "apple",
        role: "user",
        isCaptain: false,
        createdAt: serverTimestamp(),
        memberSince: serverTimestamp(),
        updatedAt: serverTimestamp(),
        profileCompleted: false
      });
      await setDoc(doc(db, "posts/apple_post"), {
        id: "apple_post",
        authorId: "alice",
        authorUsername: "alice",
        authorDisplayUsername: "Alice",
        authorAvatarUrl: null,
        fruitCommunityId: "apple",
        groupId: null,
        contentText: "Apple feed",
        imageUrls: [],
        visibility: "fruit",
        locationText: null,
        isAnonymous: false,
        pinned: false,
        pinnedBy: null,
        pinnedAt: null,
        likeCount: 0,
        commentCount: 0,
        reportCount: 0,
        trendingScore: 0,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
        deletedAt: null
      });
      await setDoc(doc(db, "posts/banana_post"), {
        id: "banana_post",
        authorId: "bob",
        authorUsername: "bob",
        authorDisplayUsername: "Bob",
        authorAvatarUrl: null,
        fruitCommunityId: "banana",
        groupId: null,
        contentText: "Banana feed",
        imageUrls: [],
        visibility: "fruit",
        locationText: null,
        isAnonymous: false,
        pinned: false,
        pinnedBy: null,
        pinnedAt: null,
        likeCount: 0,
        commentCount: 0,
        reportCount: 0,
        trendingScore: 0,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
        deletedAt: null
      });
      await setDoc(doc(db, "posts/dana_friends_post"), {
        id: "dana_friends_post",
        authorId: "dana",
        authorUsername: "dana",
        authorDisplayUsername: "Dana",
        authorAvatarUrl: null,
        fruitCommunityId: "apple",
        groupId: null,
        contentText: "Friends only",
        imageUrls: [],
        visibility: "friends",
        locationText: null,
        isAnonymous: false,
        pinned: false,
        pinnedBy: null,
        pinnedAt: null,
        likeCount: 2,
        commentCount: 1,
        reportCount: 0,
        trendingScore: 7,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
        deletedAt: null
      });
      await setDoc(doc(db, "posts/apple_post/comments/comment_1"), {
        id: "comment_1",
        postId: "apple_post",
        authorId: "alice",
        authorDisplayUsername: "Alice",
        authorAvatarUrl: null,
        fruitCommunityId: "apple",
        contentText: "Same fruit comment",
        reportCount: 0,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
        deletedAt: null
      });
      await setDoc(doc(db, "friendships/alice_carol"), {
        id: "alice_carol",
        userLowId: "alice",
        userHighId: "carol",
        requesterId: "alice",
        receiverId: "carol",
        participantIds: ["alice", "carol"],
        fruitCommunityId: "apple",
        status: "pending",
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
        acceptedAt: null,
        blockedAt: null
      });
      await setDoc(doc(db, "friendships/alice_dana"), {
        id: "alice_dana",
        userLowId: "alice",
        userHighId: "dana",
        requesterId: "alice",
        receiverId: "dana",
        participantIds: ["alice", "dana"],
        fruitCommunityId: "apple",
        status: "accepted",
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
        acceptedAt: serverTimestamp(),
        blockedAt: null
      });
      await setDoc(doc(db, "notifications/note_1"), {
        id: "note_1",
        userId: "alice",
        actorId: "carol",
        type: "friend_request",
        entityType: "friendship",
        entityId: "alice_carol",
        fruitCommunityId: "apple",
        title: "New friend request",
        body: "Carol sent you a friend request.",
        isRead: false,
        createdAt: serverTimestamp()
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

  it("allows same-fruit post reads and rejects cross-fruit post reads", async () => {
    const db = testEnv.authenticatedContext("alice").firestore();

    await assertSucceeds(getDoc(doc(db, "posts/apple_post")));
    await assertFails(getDoc(doc(db, "posts/banana_post")));
  });

  it("allows friends-only reads only for the author and accepted friends", async () => {
    const aliceDb = testEnv.authenticatedContext("alice").firestore();
    const carolDb = testEnv.authenticatedContext("carol").firestore();
    const danaDb = testEnv.authenticatedContext("dana").firestore();

    await assertSucceeds(getDoc(doc(aliceDb, "posts/dana_friends_post")));
    await assertSucceeds(getDoc(doc(danaDb, "posts/dana_friends_post")));
    await assertFails(getDoc(doc(carolDb, "posts/dana_friends_post")));
  });

  it("allows the fruit feed query shape", async () => {
    const db = testEnv.authenticatedContext("alice").firestore();
    const feedQuery = query(
      collection(db, "posts"),
      where("fruitCommunityId", "==", "apple"),
      where("visibility", "==", "fruit"),
      where("deletedAt", "==", null),
      orderBy("pinned", "desc"),
      orderBy("createdAt", "desc"),
      limit(25)
    );

    await assertSucceeds(getDocs(feedQuery));
  });

  it("allows accepted-friend post query shape and trending query shape", async () => {
    const db = testEnv.authenticatedContext("alice").firestore();
    const friendsQuery = query(
      collection(db, "posts"),
      where("fruitCommunityId", "==", "apple"),
      where("visibility", "==", "friends"),
      where("deletedAt", "==", null),
      where("authorId", "in", ["dana"]),
      orderBy("createdAt", "desc"),
      limit(25)
    );
    const trendingQuery = query(
      collection(db, "posts"),
      where("fruitCommunityId", "==", "apple"),
      where("visibility", "==", "fruit"),
      where("deletedAt", "==", null),
      orderBy("trendingScore", "desc"),
      orderBy("createdAt", "desc"),
      limit(25)
    );

    await assertSucceeds(getDocs(friendsQuery));
    await assertSucceeds(getDocs(trendingQuery));
  });

  it("allows visible same-fruit comment reads and rejects comments on deleted posts", async () => {
    const db = testEnv.authenticatedContext("alice").firestore();

    await assertSucceeds(getDoc(doc(db, "posts/apple_post/comments/comment_1")));

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const adminDb = context.firestore();
      await setDoc(doc(adminDb, "posts/deleted_post"), {
        id: "deleted_post",
        authorId: "alice",
        authorUsername: "alice",
        authorDisplayUsername: "Alice",
        authorAvatarUrl: null,
        fruitCommunityId: "apple",
        groupId: null,
        contentText: "Deleted feed",
        imageUrls: [],
        visibility: "fruit",
        locationText: null,
        isAnonymous: false,
        pinned: false,
        pinnedBy: null,
        pinnedAt: null,
        likeCount: 0,
        commentCount: 1,
        reportCount: 0,
        trendingScore: 0,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
        deletedAt: serverTimestamp()
      });
      await setDoc(doc(adminDb, "posts/deleted_post/comments/comment_1"), {
        id: "comment_1",
        postId: "deleted_post",
        authorId: "alice",
        authorDisplayUsername: "Alice",
        authorAvatarUrl: null,
        fruitCommunityId: "apple",
        contentText: "Hidden with parent",
        reportCount: 0,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
        deletedAt: null
      });
    });

    await assertFails(getDoc(doc(db, "posts/deleted_post/comments/comment_1")));
  });

  it("rejects direct client post creation and protected post field mutation", async () => {
    const db = testEnv.authenticatedContext("alice").firestore();

    await assertFails(setDoc(doc(db, "posts/client_post"), {
      id: "client_post",
      authorId: "alice",
      fruitCommunityId: "apple",
      contentText: "Client write",
      visibility: "fruit",
      deletedAt: null
    }));
    await assertFails(updateDoc(doc(db, "posts/apple_post"), {
      fruitCommunityId: "banana",
      likeCount: 10
    }));
  });

  it("rejects direct cross-fruit writes through post rules", async () => {
    const db = testEnv.authenticatedContext("alice").firestore();

    await assertFails(setDoc(doc(db, "posts/cross_fruit_post"), {
      id: "cross_fruit_post",
      authorId: "alice",
      fruitCommunityId: "banana",
      contentText: "Wrong fruit",
      visibility: "fruit",
      deletedAt: null
    }));
  });

  it("allows participant friendship reads and rejects direct friendship writes", async () => {
    const aliceDb = testEnv.authenticatedContext("alice").firestore();
    const carolDb = testEnv.authenticatedContext("carol").firestore();

    await assertSucceeds(getDoc(doc(aliceDb, "friendships/alice_carol")));
    await assertSucceeds(getDoc(doc(carolDb, "friendships/alice_carol")));
    await assertFails(setDoc(doc(aliceDb, "friendships/alice_new"), {
      id: "alice_new",
      requesterId: "alice",
      receiverId: "new",
      participantIds: ["alice", "new"],
      fruitCommunityId: "apple",
      status: "pending"
    }));
  });

  it("allows own notification reads and rejects direct notification writes", async () => {
    const aliceDb = testEnv.authenticatedContext("alice").firestore();
    const bobDb = testEnv.authenticatedContext("bob").firestore();

    await assertSucceeds(getDoc(doc(aliceDb, "notifications/note_1")));
    await assertFails(getDoc(doc(bobDb, "notifications/note_1")));
    await assertFails(setDoc(doc(aliceDb, "notifications/client_note"), {
      id: "client_note",
      userId: "alice",
      actorId: "bob",
      type: "friend_request",
      fruitCommunityId: "apple"
    }));
  });

});
