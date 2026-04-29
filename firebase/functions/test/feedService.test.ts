import {initializeApp, getApps, deleteApp} from "firebase-admin/app";
import {getFirestore, Timestamp} from "firebase-admin/firestore";
import {assertAuth} from "../src/utils/assertAuth";
import {
  createCommentForUid,
  createPostForUid,
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
    expect(result.post.deletedAt).toBeNull();
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
});
