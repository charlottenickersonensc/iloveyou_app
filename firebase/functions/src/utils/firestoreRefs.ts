import {getFirestore} from "firebase-admin/firestore";

export const firestore = () => getFirestore();

export const fruitCommunitiesRef = () => firestore().collection("fruitCommunities");
export const usersRef = () => firestore().collection("users");
export const usernamesRef = () => firestore().collection("usernames");
export const postsRef = () => firestore().collection("posts");
export const postLikesRef = () => firestore().collection("postLikes");
export const reportsRef = () => firestore().collection("reports");
