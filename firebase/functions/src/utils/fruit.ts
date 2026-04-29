import {randomInt} from "crypto";
import {DocumentData, QueryDocumentSnapshot} from "firebase-admin/firestore";
import {failedPrecondition} from "./errors";
import {fruitCommunitiesRef} from "./firestoreRefs";

export type FruitCommunityDoc = {
  id: string;
  code: string;
  name: string;
  themeColorHex: string;
  badgeAssetName: string;
  wheelIndex: number;
};

export async function loadTwelveFruitCommunities(): Promise<QueryDocumentSnapshot<DocumentData>[]> {
  const snapshot = await fruitCommunitiesRef().get();
  const fruits = snapshot.docs;
  if (fruits.length !== 12) {
    throw failedPrecondition("Fruit communities must be seeded before signup.", {count: fruits.length});
  }
  const indexes = new Set(fruits.map((doc) => doc.data().wheelIndex));
  if (indexes.size !== 12) {
    throw failedPrecondition("Fruit community wheel indexes must be unique.");
  }
  return fruits;
}

export function chooseRandomFruit(fruits: QueryDocumentSnapshot<DocumentData>[]): FruitCommunityDoc {
  const selected = fruits[randomInt(0, fruits.length)];
  const data = selected.data();
  if (data.code !== selected.id) {
    throw failedPrecondition("Fruit community code must match document ID.", {fruitId: selected.id});
  }
  return {
    id: selected.id,
    code: data.code,
    name: data.name,
    themeColorHex: data.themeColorHex,
    badgeAssetName: data.badgeAssetName,
    wheelIndex: data.wheelIndex
  };
}
