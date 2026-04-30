import {initializeApp} from "firebase-admin/app";
import {onCall} from "firebase-functions/v2/https";
import {completeUserSignupForUid} from "./services/signupService";
import {updateProfileForUid} from "./services/profileService";
import {
  createCommentForUid,
  createPostForUid,
  reportContentForUid,
  togglePostLikeForUid
} from "./services/feedService";
import {
  respondToFriendRequestForUid,
  sendFriendRequestForUid
} from "./services/socialService";
import {
  getTodayAffirmationForUid,
  submitMoodCheckinForUid
} from "./services/mentalHealthService";
import {markNotificationReadForUid} from "./services/notificationService";
import {assertAuth} from "./utils/assertAuth";

initializeApp();

export const completeUserSignup = onCall(async (request) => {
  const uid = assertAuth(request.auth);
  return completeUserSignupForUid(uid, request.data);
});

export const updateProfile = onCall(async (request) => {
  const uid = assertAuth(request.auth);
  return updateProfileForUid(uid, request.data);
});

export const createPost = onCall(async (request) => {
  const uid = assertAuth(request.auth);
  return createPostForUid(uid, request.data);
});

export const togglePostLike = onCall(async (request) => {
  const uid = assertAuth(request.auth);
  return togglePostLikeForUid(uid, request.data);
});

export const createComment = onCall(async (request) => {
  const uid = assertAuth(request.auth);
  return createCommentForUid(uid, request.data);
});

export const reportContent = onCall(async (request) => {
  const uid = assertAuth(request.auth);
  return reportContentForUid(uid, request.data);
});

export const sendFriendRequest = onCall(async (request) => {
  const uid = assertAuth(request.auth);
  return sendFriendRequestForUid(uid, request.data);
});

export const respondToFriendRequest = onCall(async (request) => {
  const uid = assertAuth(request.auth);
  return respondToFriendRequestForUid(uid, request.data);
});

export const submitMoodCheckin = onCall(async (request) => {
  const uid = assertAuth(request.auth);
  return submitMoodCheckinForUid(uid, request.data);
});

export const getTodayAffirmation = onCall(async (request) => {
  const uid = assertAuth(request.auth);
  return getTodayAffirmationForUid(uid, request.data);
});

export const markNotificationRead = onCall(async (request) => {
  const uid = assertAuth(request.auth);
  return markNotificationReadForUid(uid, request.data);
});
