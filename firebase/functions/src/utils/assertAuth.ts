import {CallableRequest} from "firebase-functions/v2/https";
import {unauthenticated} from "./errors";

type CallableAuth = NonNullable<CallableRequest["auth"]>;

export function assertAuth(auth: CallableAuth | undefined): string {
  if (!auth?.uid) {
    throw unauthenticated("You must be signed in.");
  }
  return auth.uid;
}
