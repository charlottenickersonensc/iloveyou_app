import {FieldValue, Timestamp} from "firebase-admin/firestore";
import {failedPrecondition, invalidArgument, notFound} from "../utils/errors";
import {postLikesRef, postsRef, reportsRef, usersRef, firestore} from "../utils/firestoreRefs";
import {
  assertNoProtectedPostInput,
  validateContentText,
  validateImageUrls,
  validateInputObject,
  validateReportDetails,
  validateReportReason
} from "../validators/feedValidation";

type AppUserData = {
  id: string;
  username: string;
  displayUsername: string;
  avatarUrl?: string | null;
  fruitCommunityId: string;
};

export type AppPost = {
  id: string;
  authorId: string;
  authorUsername: string;
  authorDisplayUsername: string;
  authorAvatarUrl: string | null;
  fruitCommunityId: string;
  groupId: null;
  contentText: string;
  imageUrls: string[];
  visibility: "fruit";
  locationText: null;
  isAnonymous: false;
  pinned: false;
  pinnedBy: null;
  pinnedAt: null;
  likeCount: number;
  commentCount: number;
  reportCount: number;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  deletedAt: null;
};

export type AppComment = {
  id: string;
  postId: string;
  authorId: string;
  authorDisplayUsername: string;
  authorAvatarUrl: string | null;
  fruitCommunityId: string;
  contentText: string;
  reportCount: number;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  deletedAt: null;
};

export type CreatePostInput = unknown;
export type TogglePostLikeInput = unknown;
export type CreateCommentInput = unknown;
export type ReportContentInput = unknown;

export async function createPostForUid(uid: string, input: CreatePostInput): Promise<{post: AppPost}> {
  const data = validateInputObject(input);
  assertNoProtectedPostInput(data);
  const contentText = validateContentText(data.contentText, "contentText", 2000);
  const imageUrls = validateImageUrls(data.imageUrls);
  const user = await loadUser(uid);
  const postRef = postsRef().doc();
  const now = Timestamp.now();
  const post: AppPost = {
    id: postRef.id,
    authorId: uid,
    authorUsername: user.username,
    authorDisplayUsername: user.displayUsername,
    authorAvatarUrl: user.avatarUrl ?? null,
    fruitCommunityId: user.fruitCommunityId,
    groupId: null,
    contentText,
    imageUrls,
    visibility: "fruit",
    locationText: null,
    isAnonymous: false,
    pinned: false,
    pinnedBy: null,
    pinnedAt: null,
    likeCount: 0,
    commentCount: 0,
    reportCount: 0,
    createdAt: now,
    updatedAt: now,
    deletedAt: null
  };
  await postRef.set(post);
  return {post};
}

export async function togglePostLikeForUid(
  uid: string,
  input: TogglePostLikeInput
): Promise<{liked: boolean; likeCount: number}> {
  const data = validateInputObject(input);
  const postId = validateId(data.postId, "postId");
  const user = await loadUser(uid);
  const postRef = postsRef().doc(postId);
  const likeRef = postLikesRef().doc(`${postId}_${uid}`);

  return firestore().runTransaction(async (transaction) => {
    const [postSnapshot, likeSnapshot] = await Promise.all([
      transaction.get(postRef),
      transaction.get(likeRef)
    ]);
    const post = requireSameFruitPost(postSnapshot, user.fruitCommunityId);
    const existingCount = numberField(post.likeCount);

    if (likeSnapshot.exists) {
      const likeCount = Math.max(0, existingCount - 1);
      transaction.delete(likeRef);
      transaction.update(postRef, {
        likeCount,
        updatedAt: FieldValue.serverTimestamp()
      });
      return {liked: false, likeCount};
    }

    const likeCount = existingCount + 1;
    transaction.set(likeRef, {
      id: likeRef.id,
      postId,
      userId: uid,
      postAuthorId: post.authorId,
      fruitCommunityId: user.fruitCommunityId,
      createdAt: FieldValue.serverTimestamp()
    });
    transaction.update(postRef, {
      likeCount,
      updatedAt: FieldValue.serverTimestamp()
    });
    return {liked: true, likeCount};
  });
}

export async function createCommentForUid(uid: string, input: CreateCommentInput): Promise<{comment: AppComment}> {
  const data = validateInputObject(input);
  const postId = validateId(data.postId, "postId");
  const contentText = validateContentText(data.contentText, "contentText", 1000);
  const user = await loadUser(uid);
  const postRef = postsRef().doc(postId);
  const commentRef = postRef.collection("comments").doc();
  const now = Timestamp.now();

  return firestore().runTransaction(async (transaction) => {
    const postSnapshot = await transaction.get(postRef);
    requireSameFruitPost(postSnapshot, user.fruitCommunityId);
    const comment: AppComment = {
      id: commentRef.id,
      postId,
      authorId: uid,
      authorDisplayUsername: user.displayUsername,
      authorAvatarUrl: user.avatarUrl ?? null,
      fruitCommunityId: user.fruitCommunityId,
      contentText,
      reportCount: 0,
      createdAt: now,
      updatedAt: now,
      deletedAt: null
    };
    transaction.set(commentRef, comment);
    transaction.update(postRef, {
      commentCount: FieldValue.increment(1),
      updatedAt: FieldValue.serverTimestamp()
    });
    return {comment};
  });
}

export async function reportContentForUid(
  uid: string,
  input: ReportContentInput
): Promise<{report: FirebaseFirestore.DocumentData; created: boolean}> {
  const data = validateInputObject(input);
  const targetType = data.targetType ?? "post";
  if (targetType !== "post") {
    throw invalidArgument("Sprint 2 supports post reports only.", {field: "targetType"});
  }
  const targetId = validateId(data.targetId, "targetId");
  const reason = validateReportReason(data.reason);
  const details = validateReportDetails(data.details);
  const user = await loadUser(uid);
  const postRef = postsRef().doc(targetId);
  const reportRef = reportsRef().doc(`post_${targetId}_${uid}`);

  return firestore().runTransaction(async (transaction) => {
    const [postSnapshot, reportSnapshot] = await Promise.all([
      transaction.get(postRef),
      transaction.get(reportRef)
    ]);
    const post = requireSameFruitPost(postSnapshot, user.fruitCommunityId);
    if (reportSnapshot.exists) {
      return {report: reportSnapshot.data() ?? {}, created: false};
    }
    const report = {
      id: reportRef.id,
      reporterId: uid,
      targetType: "post",
      targetId,
      targetOwnerId: post.authorId,
      fruitCommunityId: user.fruitCommunityId,
      reason,
      details,
      status: "open",
      createdAt: FieldValue.serverTimestamp(),
      resolvedAt: null,
      resolvedBy: null
    };
    transaction.set(reportRef, report);
    transaction.update(postRef, {
      reportCount: FieldValue.increment(1),
      updatedAt: FieldValue.serverTimestamp()
    });
    return {report, created: true};
  });
}

async function loadUser(uid: string): Promise<AppUserData> {
  const snapshot = await usersRef().doc(uid).get();
  if (!snapshot.exists) {
    throw failedPrecondition("Complete signup before using the feed.");
  }
  const data = snapshot.data();
  if (
    !data ||
    typeof data.username !== "string" ||
    typeof data.displayUsername !== "string" ||
    typeof data.fruitCommunityId !== "string"
  ) {
    throw failedPrecondition("User profile is missing required feed fields.");
  }
  return {
    id: uid,
    username: data.username,
    displayUsername: data.displayUsername,
    avatarUrl: typeof data.avatarUrl === "string" ? data.avatarUrl : null,
    fruitCommunityId: data.fruitCommunityId
  };
}

function validateId(value: unknown, field: string): string {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw invalidArgument(`${field} is required.`, {field});
  }
  return value.trim();
}

function requireSameFruitPost(
  snapshot: FirebaseFirestore.DocumentSnapshot,
  userFruitCommunityId: string
): FirebaseFirestore.DocumentData {
  if (!snapshot.exists) {
    throw notFound("Post not found.");
  }
  const post = snapshot.data();
  if (!post || post.deletedAt != null || post.visibility !== "fruit") {
    throw notFound("Post not found.");
  }
  if (post.fruitCommunityId !== userFruitCommunityId) {
    throw failedPrecondition("This post belongs to another fruit community.");
  }
  return post;
}

function numberField(value: unknown): number {
  return typeof value === "number" && Number.isFinite(value) ? value : 0;
}
