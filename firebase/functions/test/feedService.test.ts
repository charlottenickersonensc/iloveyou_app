import {initializeApp, getApps, deleteApp} from "firebase-admin/app";
import {getFirestore, Timestamp} from "firebase-admin/firestore";
import {assertAuth} from "../src/utils/assertAuth";
import {
  createCommentForUid,
  createPostForUid,
  pinPostForUid,
  reportContentForUid,
  togglePostLikeForUid
} from "../src/services/feedService";

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

async function seedUser(uid: string, fruitCommunityId: string, isCaptain = false) {
  await getFirestore().collection("users").doc(uid).set({
    id: uid,
    email: `${uid}@example.com`,
    username: uid,
    displayUsername: uid.replace("_", " "),
    avatarUrl: null,
    fruitCommunityId,
    fruitCode: fruitCommunityId,
    role: "user",
    isCaptain,
    createdAt: Timestamp.now(),
    memberSince: Timestamp.now(),
    updatedAt: Timestamp.now(),
    profileCompleted: true
  });
}

async function seedFriendship(uidA: string, uidB: string, fruitCommunityId: string, status: "pending" | "accepted") {
  const [userLowId, userHighId] = uidA < uidB ? [uidA, uidB] : [uidB, uidA];
  const now = Timestamp.now();
  await getFirestore().collection("friendships").doc(`${userLowId}_${userHighId}`).set({
    id: `${userLowId}_${userHighId}`,
    userLowId,
    userHighId,
    requesterId: uidA,
    receiverId: uidB,
    participantIds: [userLowId, userHighId],
    fruitCommunityId,
    status,
    createdAt: now,
    updatedAt: now,
    acceptedAt: status === "accepted" ? now : null,
    blockedAt: null
  });
}

describe("feed service", () => {
  beforeAll(() => {
    process.env.GCLOUD_PROJECT = projectId;
    ensureAdminApp();
  });

  beforeEach(async () => {
    await clearFirestore();
    await seedUser("apple_user", "apple");
    await seedUser("banana_user", "banana");
  });

  afterAll(async () => {
    await Promise.all(getApps().map((app) => deleteApp(app)));
  });

  it("creates a valid post with the authenticated user's fruit", async () => {
    const result = await createPostForUid("apple_user", {
      contentText: "Hello apple feed",
      imageUrls: ["https://example.com/one.jpg"]
    });

    expect(result.post.fruitCommunityId).toBe("apple");
    expect(result.post.visibility).toBe("fruit");
    expect(result.post.likeCount).toBe(0);
    expect(result.post.commentCount).toBe(0);
    expect(result.post.reportCount).toBe(0);
    expect(result.post.trendingScore).toBe(0);
    expect(result.post.deletedAt).toBeNull();
  });

  it("creates a friends-only post without accepting client fruit fields", async () => {
    const result = await createPostForUid("apple_user", {
      contentText: "Hello close friends",
      visibility: "friends"
    });

    expect(result.post.fruitCommunityId).toBe("apple");
    expect(result.post.visibility).toBe("friends");

    await expect(createPostForUid("apple_user", {
      contentText: "Trying to choose score",
      trendingScore: 99
    })).rejects.toMatchObject({code: "invalid-argument"});
    await expect(createPostForUid("apple_user", {
      contentText: "Trying group visibility",
      visibility: "group"
    })).rejects.toMatchObject({code: "invalid-argument"});
  });

  it("rejects client-supplied fruitCommunityId", async () => {
    await expect(createPostForUid("apple_user", {
      contentText: "Trying to choose fruit",
      fruitCommunityId: "banana"
    })).rejects.toMatchObject({code: "invalid-argument"});
  });

  it("rejects malformed callable payloads", async () => {
    await expect(createPostForUid("apple_user", null)).rejects.toMatchObject({
      code: "invalid-argument"
    });
    await expect(togglePostLikeForUid("apple_user", [])).rejects.toMatchObject({
      code: "invalid-argument"
    });
    await expect(createCommentForUid("apple_user", null)).rejects.toMatchObject({
      code: "invalid-argument"
    });
    await expect(reportContentForUid("apple_user", [])).rejects.toMatchObject({
      code: "invalid-argument"
    });
  });

  it("rejects empty, overlong, and blocked posts", async () => {
    await expect(createPostForUid("apple_user", {contentText: "   "})).rejects.toMatchObject({
      code: "invalid-argument"
    });
    await expect(createPostForUid("apple_user", {contentText: "a".repeat(2001)})).rejects.toMatchObject({
      code: "invalid-argument"
    });
    await expect(createPostForUid("apple_user", {contentText: "This has BlockedWord inside."}))
      .rejects.toMatchObject({code: "invalid-argument"});
  });

  it("rejects unauthenticated create at the callable auth boundary", () => {
    expect(() => assertAuth(undefined)).toThrow(expect.objectContaining({code: "unauthenticated"}));
  });

  it("toggles same-fruit likes and rejects cross-fruit likes", async () => {
    const post = (await createPostForUid("apple_user", {contentText: "Likeable"})).post;

    await expect(togglePostLikeForUid("banana_user", {postId: post.id}))
      .rejects.toMatchObject({code: "failed-precondition"});

    const liked = await togglePostLikeForUid("apple_user", {postId: post.id});
    expect(liked).toEqual({liked: true, likeCount: 1});

    const unliked = await togglePostLikeForUid("apple_user", {postId: post.id});
    expect(unliked).toEqual({liked: false, likeCount: 0});

    const likedAgain = await togglePostLikeForUid("apple_user", {postId: post.id});
    expect(likedAgain).toEqual({liked: true, likeCount: 1});
  });

  it("creates a like notification for the post author", async () => {
    const post = (await createPostForUid("apple_user", {contentText: "Notify like"})).post;
    await seedUser("apple_friend", "apple");

    await togglePostLikeForUid("apple_friend", {postId: post.id});

    const notifications = await getFirestore().collection("notifications")
      .where("userId", "==", "apple_user")
      .where("type", "==", "like")
      .get();
    expect(notifications.size).toBe(1);
    expect(notifications.docs[0].data().fruitCommunityId).toBe("apple");
  });

  it("creates same-fruit comments and rejects empty, blocked, and cross-fruit comments", async () => {
    const post = (await createPostForUid("apple_user", {contentText: "Commentable"})).post;

    const comment = await createCommentForUid("apple_user", {
      postId: post.id,
      contentText: "A useful comment"
    });
    expect(comment.comment.fruitCommunityId).toBe("apple");

    await expect(createCommentForUid("apple_user", {postId: post.id, contentText: ""}))
      .rejects.toMatchObject({code: "invalid-argument"});
    await expect(createCommentForUid("apple_user", {postId: post.id, contentText: "blockedword"}))
      .rejects.toMatchObject({code: "invalid-argument"});
    await expect(createCommentForUid("banana_user", {postId: post.id, contentText: "Wrong fruit"}))
      .rejects.toMatchObject({code: "failed-precondition"});

    const savedPost = await getFirestore().collection("posts").doc(post.id).get();
    expect(savedPost.data()?.commentCount).toBe(1);
    expect(savedPost.data()?.trendingScore).toBe(3);
  });

  it("limits friends-only post interactions to the author and accepted same-fruit friends", async () => {
    await seedUser("apple_friend", "apple");
    await seedUser("apple_pending", "apple");
    await seedUser("apple_stranger", "apple");
    await seedFriendship("apple_user", "apple_friend", "apple", "accepted");
    await seedFriendship("apple_user", "apple_pending", "apple", "pending");
    const post = (await createPostForUid("apple_user", {
      contentText: "Friends only",
      visibility: "friends"
    })).post;

    await expect(togglePostLikeForUid("apple_stranger", {postId: post.id}))
      .rejects.toMatchObject({code: "not-found"});
    await expect(createCommentForUid("apple_pending", {
      postId: post.id,
      contentText: "Pending should not see this"
    })).rejects.toMatchObject({code: "not-found"});
    await expect(reportContentForUid("apple_stranger", {
      targetType: "post",
      targetId: post.id,
      reason: "spam"
    })).rejects.toMatchObject({code: "not-found"});

    const like = await togglePostLikeForUid("apple_friend", {postId: post.id});
    expect(like).toEqual({liked: true, likeCount: 1});
    const comment = await createCommentForUid("apple_friend", {
      postId: post.id,
      contentText: "Accepted friend can comment"
    });
    expect(comment.comment.fruitCommunityId).toBe("apple");

    const savedPost = await getFirestore().collection("posts").doc(post.id).get();
    expect(savedPost.data()?.likeCount).toBe(1);
    expect(savedPost.data()?.commentCount).toBe(1);
    expect(savedPost.data()?.trendingScore).toBe(5);
  });

  it("creates a comment notification for the post author", async () => {
    const post = (await createPostForUid("apple_user", {contentText: "Notify comment"})).post;
    await seedUser("apple_friend", "apple");

    await createCommentForUid("apple_friend", {
      postId: post.id,
      contentText: "Notification comment"
    });

    const notifications = await getFirestore().collection("notifications")
      .where("userId", "==", "apple_user")
      .where("type", "==", "comment")
      .get();
    expect(notifications.size).toBe(1);
    expect(notifications.docs[0].data().fruitCommunityId).toBe("apple");
  });

  it("reports posts once per reporter and rejects cross-fruit reports", async () => {
    const post = (await createPostForUid("apple_user", {contentText: "Reportable"})).post;

    await expect(reportContentForUid("banana_user", {
      targetType: "post",
      targetId: post.id,
      reason: "spam"
    })).rejects.toMatchObject({code: "failed-precondition"});

    const first = await reportContentForUid("apple_user", {
      targetType: "post",
      targetId: post.id,
      reason: "spam",
      details: "Repeated content"
    });
    const second = await reportContentForUid("apple_user", {
      targetType: "post",
      targetId: post.id,
      reason: "spam"
    });

    expect(first.created).toBe(true);
    expect(second.created).toBe(false);
    expect(second.report.id).toBe(first.report.id);

    const savedPost = await getFirestore().collection("posts").doc(post.id).get();
    expect(savedPost.data()?.reportCount).toBe(1);
  });

  it("lets a fruit captain pin and unpin a same-fruit post", async () => {
    await seedUser("apple_captain", "apple", true);
    const post = (await createPostForUid("apple_user", {contentText: "Pin worthy"})).post;

    const pinned = await pinPostForUid("apple_captain", {
      postId: post.id,
      pinned: true
    });

    expect(pinned.post.fruitCommunityId).toBe("apple");
    expect(pinned.post.pinned).toBe(true);
    expect(pinned.post.pinnedBy).toBe("apple_captain");
    expect(pinned.post.pinnedAt).toBeInstanceOf(Timestamp);

    let savedPost = await getFirestore().collection("posts").doc(post.id).get();
    expect(savedPost.data()?.pinned).toBe(true);
    expect(savedPost.data()?.pinnedBy).toBe("apple_captain");
    expect(savedPost.data()?.pinnedAt).toBeInstanceOf(Timestamp);

    const unpinned = await pinPostForUid("apple_captain", {
      postId: post.id,
      pinned: false
    });

    expect(unpinned.post.pinned).toBe(false);
    expect(unpinned.post.pinnedBy).toBeNull();
    expect(unpinned.post.pinnedAt).toBeNull();

    savedPost = await getFirestore().collection("posts").doc(post.id).get();
    expect(savedPost.data()?.pinned).toBe(false);
    expect(savedPost.data()?.pinnedBy).toBeNull();
    expect(savedPost.data()?.pinnedAt).toBeNull();
  });

  it("rejects non-captain pin attempts", async () => {
    const post = (await createPostForUid("apple_user", {contentText: "No pin"})).post;

    await expect(pinPostForUid("apple_user", {
      postId: post.id,
      pinned: true
    })).rejects.toMatchObject({code: "permission-denied"});
  });

  it("rejects captain pin attempts for cross-fruit posts", async () => {
    await seedUser("apple_captain", "apple", true);
    const post = (await createPostForUid("banana_user", {contentText: "Other fruit"})).post;

    await expect(pinPostForUid("apple_captain", {
      postId: post.id,
      pinned: true
    })).rejects.toMatchObject({code: "failed-precondition"});
  });
});
