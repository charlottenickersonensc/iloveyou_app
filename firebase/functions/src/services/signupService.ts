import {getAuth} from "firebase-admin/auth";
import {FieldValue, Timestamp} from "firebase-admin/firestore";
import {alreadyExists, failedPrecondition} from "../utils/errors";
import {firestore, usernamesRef, usersRef} from "../utils/firestoreRefs";
import {chooseRandomFruit, loadTwelveFruitCommunities} from "../utils/fruit";
import {
  normalizeUsername,
  nullableTrimmedString,
  validateDateOfBirth,
  validateDisplayUsername,
  validateEmail,
  validateUsername
} from "../utils/validation";

export type CompleteSignupInput = {
  username?: unknown;
  displayUsername?: unknown;
  dateOfBirth?: unknown;
  pronouns?: unknown;
  locationText?: unknown;
};

export type AppUser = {
  id: string;
  email: string;
  username: string;
  displayUsername: string;
  dateOfBirth: string;
  pronouns: string | null;
  locationText: string | null;
  bio: string | null;
  avatarUrl: string | null;
  interests: string[];
  isPrivate: boolean;
  fruitCommunityId: string;
  fruitCode: string;
  role: "user" | "platformAdmin" | "fruitModerator";
  isCaptain: boolean;
  captainSince: null;
  memberSince: Timestamp;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  lastActiveAt: Timestamp;
  fcmTokens: string[];
  profileCompleted: boolean;
};

export async function completeUserSignupForUid(uid: string, input: CompleteSignupInput): Promise<{user: AppUser}> {
  const authUser = await getAuth().getUser(uid);
  if (!authUser.email) {
    throw failedPrecondition("Firebase Auth user must have an email address.", {field: "email"});
  }
  validateEmail(authUser.email);

  const username = normalizeUsername(input.username);
  validateUsername(username);
  const displayUsername = validateDisplayUsername(input.displayUsername);
  const dateOfBirth = validateDateOfBirth(input.dateOfBirth);
  const pronouns = nullableTrimmedString(input.pronouns, "pronouns", 40);
  const locationText = nullableTrimmedString(input.locationText, "locationText", 80);
  const fruits = await loadTwelveFruitCommunities();
  const fruit = chooseRandomFruit(fruits);

  const userRef = usersRef().doc(uid);
  const usernameRef = usernamesRef().doc(username);

  const user = await firestore().runTransaction(async (transaction) => {
    const existingUser = await transaction.get(userRef);
    if (existingUser.exists) {
      return existingUser.data() as AppUser;
    }

    const existingUsername = await transaction.get(usernameRef);
    if (existingUsername.exists) {
      throw alreadyExists("Username is already taken.", {field: "username"});
    }

    const now = Timestamp.now();
    const newUser: AppUser = {
      id: uid,
      email: authUser.email!,
      username,
      displayUsername,
      dateOfBirth,
      pronouns,
      locationText,
      bio: null,
      avatarUrl: null,
      interests: [],
      isPrivate: false,
      fruitCommunityId: fruit.id,
      fruitCode: fruit.code,
      role: "user",
      isCaptain: false,
      captainSince: null,
      memberSince: now,
      createdAt: now,
      updatedAt: now,
      lastActiveAt: now,
      fcmTokens: [],
      profileCompleted: false
    };

    transaction.set(usernameRef, {
      uid,
      username,
      createdAt: FieldValue.serverTimestamp()
    });
    transaction.set(userRef, newUser);
    return newUser;
  });

  await getAuth().setCustomUserClaims(uid, {
    fruitCommunityId: user.fruitCommunityId,
    role: user.role,
    isCaptain: user.isCaptain
  });

  return {user};
}
