import {initializeApp, getApps} from "firebase-admin/app";
import {FieldValue, getFirestore} from "firebase-admin/firestore";
import {FRUIT_COMMUNITIES} from "../constants/fruits";

if (getApps().length === 0) {
  initializeApp({projectId: process.env.GCLOUD_PROJECT || "iloveyou-dev"});
}

export async function seedFruitCommunities(): Promise<void> {
  const db = getFirestore();
  const batch = db.batch();

  for (const fruit of FRUIT_COMMUNITIES) {
    batch.set(db.collection("fruitCommunities").doc(fruit.id), {
      ...fruit,
      createdAt: FieldValue.serverTimestamp()
    }, {merge: true});
  }

  await batch.commit();
}

if (require.main === module) {
  seedFruitCommunities()
    .then(() => {
      console.log(`Seeded ${FRUIT_COMMUNITIES.length} fruit communities.`);
    })
    .catch((error) => {
      console.error(error);
      process.exitCode = 1;
    });
}
