import {initializeApp} from "firebase-admin/app";
import {onCall} from "firebase-functions/v2/https";
import {completeUserSignupForUid} from "./services/signupService";
import {updateProfileForUid} from "./services/profileService";
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
