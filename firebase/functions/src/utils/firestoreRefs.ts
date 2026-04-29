import {getFirestore} from "firebase-admin/firestore";

export const firestore = () => getFirestore();

export const fruitCommunitiesRef = () => firestore().collection("fruitCommunities");
export const usersRef = () => firestore().collection("users");
export const usernamesRef = () => firestore().collection("usernames");
