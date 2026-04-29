import {FieldValue} from "firebase-admin/firestore";
import {failedPrecondition, invalidArgument, notFound} from "../utils/errors";
import {usersRef} from "../utils/firestoreRefs";
import {
  nullableTrimmedString,
  validateBio,
  validateBoolean,
  validateDisplayUsername,
  validateInterests
} from "../utils/validation";

const forbiddenProfileKeys = new Set([
  "fruitCommunityId",
  "fruitCode",
  "role",
  "isCaptain",
  "email",
  "createdAt",
  "memberSince",
  "dateOfBirth",
  "username"
]);

export type UpdateProfileInput = Record<string, unknown>;

export async function updateProfileForUid(
  uid: string,
  input: UpdateProfileInput
): Promise<{user: FirebaseFirestore.DocumentData}> {
  for (const key of Object.keys(input)) {
    if (forbiddenProfileKeys.has(key)) {
      throw failedPrecondition("This profile field cannot be changed.", {field: key});
    }
  }

  const userRef = usersRef().doc(uid);
  const userSnapshot = await userRef.get();
  if (!userSnapshot.exists) {
    throw notFound("Complete signup before updating your profile.");
  }

  const existing = userSnapshot.data();
  if (!existing) {
    throw invalidArgument("User profile is invalid.");
  }

  const displayUsername = input.displayUsername == null
    ? existing.displayUsername
    : validateDisplayUsername(input.displayUsername);

  const update = {
    displayUsername,
    pronouns: nullableTrimmedString(input.pronouns ?? existing.pronouns, "pronouns", 40),
    locationText: nullableTrimmedString(input.locationText ?? existing.locationText, "locationText", 80),
    bio: validateBio(input.bio ?? existing.bio),
    avatarUrl: nullableTrimmedString(input.avatarUrl ?? existing.avatarUrl, "avatarUrl", 2000),
    interests: validateInterests(input.interests ?? existing.interests ?? []),
    isPrivate: validateBoolean(input.isPrivate, Boolean(existing.isPrivate)),
    profileCompleted: true,
    updatedAt: FieldValue.serverTimestamp()
  };

  await userRef.update(update);
  const updated = await userRef.get();
  return {user: updated.data() ?? {}};
}
