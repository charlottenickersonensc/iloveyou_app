import {Timestamp} from "firebase-admin/firestore";
import {failedPrecondition, invalidArgument} from "../utils/errors";
import {dailyAffirmationsRef, firestore, moodCheckinsRef, usersRef} from "../utils/firestoreRefs";
import {validateInputObject} from "../validators/feedValidation";

const moods = new Set(["great", "good", "okay", "low", "hard"]);
const fallbackAffirmations = [
  "You are allowed to take up space.",
  "Small steps still count.",
  "Your feelings can be real without being permanent.",
  "You can be gentle with yourself today.",
  "Rest is part of staying steady.",
  "You do not have to solve everything at once.",
  "There is room for you here."
];

export type MoodCheckin = {
  id: string;
  userId: string;
  fruitCommunityId: string;
  date: string;
  mood: "great" | "good" | "okay" | "low" | "hard";
  note: string | null;
  createdAt: Timestamp;
  updatedAt: Timestamp;
};

export type DailyAffirmation = {
  id: string;
  date: string;
  text: string;
  active: boolean;
  source: "scheduled" | "fallback";
};

export type SubmitMoodCheckinInput = unknown;
export type GetTodayAffirmationInput = unknown;

export async function submitMoodCheckinForUid(
  uid: string,
  input: SubmitMoodCheckinInput
): Promise<{checkin: MoodCheckin}> {
  const data = validateInputObject(input);
  assertNoProtectedMoodInput(data);
  const date = validateTodayDate(data.date);
  const mood = validateMood(data.mood);
  const note = validateNote(data.note);
  const user = await loadUser(uid);
  const checkinRef = moodCheckinsRef().doc(`${uid}_${compactDateId(date)}`);
  const now = Timestamp.now();

  const checkin = await firestore().runTransaction(async (transaction) => {
    const existingSnapshot = await transaction.get(checkinRef);
    const existing = existingSnapshot.data();
    const createdAt = existingSnapshot.exists && existing?.createdAt instanceof Timestamp ?
      existing.createdAt :
      now;
    const saved: MoodCheckin = {
      id: checkinRef.id,
      userId: uid,
      fruitCommunityId: user.fruitCommunityId,
      date,
      mood,
      note,
      createdAt,
      updatedAt: now
    };
    transaction.set(checkinRef, saved);
    return saved;
  });

  return {checkin};
}

export async function getTodayAffirmationForUid(
  uid: string,
  input: GetTodayAffirmationInput
): Promise<{affirmation: DailyAffirmation}> {
  validateOptionalObject(input);
  await loadUser(uid);

  const date = todayDateId();
  const [datedSnapshot, compactSnapshot] = await Promise.all([
    dailyAffirmationsRef().doc(date).get(),
    dailyAffirmationsRef().doc(compactDateId(date)).get()
  ]);
  const scheduled = affirmationFromSnapshot(datedSnapshot, date) ??
    affirmationFromSnapshot(compactSnapshot, date);

  return {affirmation: scheduled ?? fallbackAffirmation(date)};
}

async function loadUser(uid: string): Promise<{fruitCommunityId: string}> {
  const snapshot = await usersRef().doc(uid).get();
  const data = snapshot.data();
  if (!snapshot.exists || !data || typeof data.fruitCommunityId !== "string") {
    throw failedPrecondition("Complete signup before using mental health check-ins.");
  }
  return {fruitCommunityId: data.fruitCommunityId};
}

function assertNoProtectedMoodInput(input: Record<string, unknown>): void {
  const protectedKeys = ["id", "userId", "fruitCommunityId", "createdAt", "updatedAt"];
  for (const key of protectedKeys) {
    if (Object.prototype.hasOwnProperty.call(input, key)) {
      throw invalidArgument("Protected mood fields are assigned by the server.", {field: key});
    }
  }
}

function validateTodayDate(value: unknown): string {
  const today = todayDateId();
  if (value == null || value === "") {
    return today;
  }
  if (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    throw invalidArgument("date must use YYYY-MM-DD.", {field: "date"});
  }
  if (value !== today) {
    throw invalidArgument("Mood check-ins are limited to today.", {field: "date"});
  }
  return value;
}

function validateMood(value: unknown): MoodCheckin["mood"] {
  if (typeof value !== "string" || !moods.has(value)) {
    throw invalidArgument("Choose a valid mood.", {field: "mood"});
  }
  return value as MoodCheckin["mood"];
}

function validateNote(value: unknown): string | null {
  if (value == null || value === "") {
    return null;
  }
  if (typeof value !== "string") {
    throw invalidArgument("note must be text.", {field: "note"});
  }
  const trimmed = value.trim();
  if (trimmed.length > 500) {
    throw invalidArgument("note must be 500 characters or fewer.", {field: "note"});
  }
  return trimmed.length === 0 ? null : trimmed;
}

function validateOptionalObject(value: unknown): void {
  if (value == null) {
    return;
  }
  validateInputObject(value);
}

function affirmationFromSnapshot(
  snapshot: FirebaseFirestore.DocumentSnapshot,
  date: string
): DailyAffirmation | null {
  const data = snapshot.data();
  if (!snapshot.exists || !data || data.active !== true || typeof data.text !== "string") {
    return null;
  }
  const text = data.text.trim();
  if (text.length === 0) {
    return null;
  }
  return {
    id: typeof data.id === "string" ? data.id : snapshot.id,
    date,
    text,
    active: true,
    source: "scheduled"
  };
}

function fallbackAffirmation(date: string): DailyAffirmation {
  const dayIndex = Math.floor(Date.parse(`${date}T00:00:00.000Z`) / 86_400_000);
  const text = fallbackAffirmations[Math.abs(dayIndex) % fallbackAffirmations.length];
  return {
    id: `fallback_${compactDateId(date)}`,
    date,
    text,
    active: true,
    source: "fallback"
  };
}

function todayDateId(): string {
  return new Date().toISOString().slice(0, 10);
}

function compactDateId(date: string): string {
  return date.replace(/-/g, "");
}
