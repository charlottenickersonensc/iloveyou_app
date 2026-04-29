import {invalidArgument} from "./errors";

const usernameRegex = /^[a-z0-9_]{3,20}$/;
const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
const symbolRegex = /[!@#$%^&*()_+\-=[\]{};' :"\\|,.<>/?`]/;

export function normalizeUsername(username: unknown): string {
  if (typeof username !== "string") {
    throw invalidArgument("Username is required.", {field: "username"});
  }
  return username.trim().toLowerCase();
}

export function validateEmail(email: string): void {
  if (!emailRegex.test(email)) {
    throw invalidArgument("Enter a valid email address.", {field: "email"});
  }
}

export function validateUsername(username: string): void {
  if (!usernameRegex.test(username)) {
    throw invalidArgument("Username must be 3 to 20 lowercase letters, numbers, or underscores.", {
      field: "username"
    });
  }
}

export function validatePassword(password: string): void {
  if (password.length < 3 || password.length > 20 || !symbolRegex.test(password)) {
    throw invalidArgument("Password must be 3 to 20 characters and include at least one symbol.", {
      field: "password"
    });
  }
}

export function validateDisplayUsername(value: unknown): string {
  if (typeof value !== "string") {
    throw invalidArgument("Display name is required.", {field: "displayUsername"});
  }
  const trimmed = value.trim();
  if (trimmed.length < 1 || trimmed.length > 30) {
    throw invalidArgument("Display name must be 1 to 30 characters.", {field: "displayUsername"});
  }
  return trimmed;
}

export function validateDateOfBirth(value: unknown): string {
  if (typeof value !== "string" || !dateRegex.test(value)) {
    throw invalidArgument("Date of birth must use YYYY-MM-DD.", {field: "dateOfBirth"});
  }
  const date = new Date(`${value}T00:00:00.000Z`);
  if (Number.isNaN(date.valueOf()) || date.toISOString().slice(0, 10) !== value) {
    throw invalidArgument("Enter a real date of birth.", {field: "dateOfBirth"});
  }
  const now = new Date();
  const age = now.getUTCFullYear() - date.getUTCFullYear();
  if (age < 13 || age > 120 || date > now) {
    throw invalidArgument("Enter a plausible date of birth.", {field: "dateOfBirth"});
  }
  return value;
}

export function nullableTrimmedString(value: unknown, field: string, maxLength: number): string | null {
  if (value == null || value === "") {
    return null;
  }
  if (typeof value !== "string") {
    throw invalidArgument(`${field} must be text.`, {field});
  }
  const trimmed = value.trim();
  if (trimmed.length > maxLength) {
    throw invalidArgument(`${field} is too long.`, {field});
  }
  return trimmed.length === 0 ? null : trimmed;
}

export function validateBio(value: unknown): string | null {
  return nullableTrimmedString(value, "bio", 300);
}

export function validateInterests(value: unknown): string[] {
  if (value == null) {
    return [];
  }
  if (!Array.isArray(value) || value.length > 20) {
    throw invalidArgument("Add no more than 20 interests.", {field: "interests"});
  }
  return value.map((item) => {
    if (typeof item !== "string") {
      throw invalidArgument("Each interest must be text.", {field: "interests"});
    }
    const normalized = item.trim().toLowerCase();
    if (!/^#[a-z0-9_]{1,29}$/.test(normalized)) {
      throw invalidArgument("Each interest must start with # and be 30 characters or fewer.", {
        field: "interests"
      });
    }
    return normalized;
  });
}

export function validateBoolean(value: unknown, fallback: boolean): boolean {
  if (value == null) {
    return fallback;
  }
  if (typeof value !== "boolean") {
    throw invalidArgument("Expected a true or false value.");
  }
  return value;
}
