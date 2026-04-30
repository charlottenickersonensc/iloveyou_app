import {BLOCKED_WORDS} from "../constants/blockedWords";
import {invalidArgument} from "../utils/errors";

const allowedReportReasons = new Set([
  "harassment",
  "hate",
  "self_harm",
  "sexual_content",
  "spam",
  "violence",
  "other"
]);

export function validateInputObject(value: unknown): Record<string, unknown> {
  if (value == null || typeof value !== "object" || Array.isArray(value)) {
    throw invalidArgument("Request data must be an object.");
  }
  return value as Record<string, unknown>;
}

export function assertNoProtectedPostInput(input: Record<string, unknown>): void {
  const protectedKeys = [
    "fruitCommunityId",
    "authorId",
    "authorUsername",
    "authorDisplayUsername",
    "authorAvatarUrl",
    "pinned",
    "pinnedBy",
    "pinnedAt",
    "likeCount",
    "commentCount",
    "reportCount",
    "trendingScore",
    "createdAt",
    "updatedAt",
    "deletedAt"
  ];
  for (const key of protectedKeys) {
    if (Object.prototype.hasOwnProperty.call(input, key)) {
      throw invalidArgument("Protected post fields are assigned by the server.", {field: key});
    }
  }
}

export function validatePostVisibility(value: unknown): "fruit" | "friends" {
  if (value == null) {
    return "fruit";
  }
  if (value === "fruit" || value === "friends") {
    return value;
  }
  throw invalidArgument("Choose a valid post visibility.", {field: "visibility"});
}

export function validateContentText(value: unknown, field: string, maxLength: number): string {
  if (typeof value !== "string") {
    throw invalidArgument(`${field} is required.`, {field});
  }
  const trimmed = value.trim();
  if (trimmed.length < 1 || trimmed.length > maxLength) {
    throw invalidArgument(`${field} must be 1 to ${maxLength} characters.`, {field});
  }
  rejectBlockedWords(trimmed, field);
  return trimmed;
}

export function validateImageUrls(value: unknown): string[] {
  if (value == null) {
    return [];
  }
  if (!Array.isArray(value) || value.length > 4) {
    throw invalidArgument("Add no more than 4 images.", {field: "imageUrls"});
  }
  return value.map((item) => {
    if (typeof item !== "string") {
      throw invalidArgument("Each image URL must be text.", {field: "imageUrls"});
    }
    const trimmed = item.trim();
    if (trimmed.length < 1 || trimmed.length > 2000) {
      throw invalidArgument("Each image URL must be 1 to 2000 characters.", {field: "imageUrls"});
    }
    return trimmed;
  });
}

export function validateReportReason(value: unknown): string {
  if (typeof value !== "string" || !allowedReportReasons.has(value)) {
    throw invalidArgument("Choose a valid report reason.", {field: "reason"});
  }
  return value;
}

export function validateReportDetails(value: unknown): string | null {
  if (value == null || value === "") {
    return null;
  }
  if (typeof value !== "string") {
    throw invalidArgument("Report details must be text.", {field: "details"});
  }
  const trimmed = value.trim();
  if (trimmed.length > 1000) {
    throw invalidArgument("Report details are too long.", {field: "details"});
  }
  return trimmed.length === 0 ? null : trimmed;
}

function rejectBlockedWords(text: string, field: string): void {
  const normalized = text.toLowerCase().replace(/\s+/g, " ");
  const blocked = BLOCKED_WORDS.find((word) => normalized.includes(word));
  if (blocked) {
    throw invalidArgument("This content includes blocked language.", {field, blockedWord: blocked});
  }
}
