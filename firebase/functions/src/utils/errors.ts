import {HttpsError} from "firebase-functions/v2/https";

type ErrorDetails = Record<string, unknown>;

export function unauthenticated(message: string, details?: ErrorDetails): HttpsError {
  return new HttpsError("unauthenticated", message, details);
}

export function invalidArgument(message: string, details?: ErrorDetails): HttpsError {
  return new HttpsError("invalid-argument", message, details);
}

export function failedPrecondition(message: string, details?: ErrorDetails): HttpsError {
  return new HttpsError("failed-precondition", message, details);
}

export function permissionDenied(message: string, details?: ErrorDetails): HttpsError {
  return new HttpsError("permission-denied", message, details);
}

export function alreadyExists(message: string, details?: ErrorDetails): HttpsError {
  return new HttpsError("already-exists", message, details);
}

export function notFound(message: string, details?: ErrorDetails): HttpsError {
  return new HttpsError("not-found", message, details);
}
