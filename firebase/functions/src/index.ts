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
