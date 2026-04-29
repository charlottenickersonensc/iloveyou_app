import fs from "fs";
import path from "path";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment
} from "@firebase/rules-unit-testing";
import {ref, uploadBytes} from "firebase/storage";

const projectId = "iloveyou-dev";
let testEnv: RulesTestEnvironment;

describe("Storage post image rules", () => {
  beforeAll(async () => {
    testEnv = await initializeTestEnvironment({
      projectId,
      storage: {
        rules: fs.readFileSync(path.resolve(__dirname, "../../storage.rules"), "utf8")
      }
    });
  });

  beforeEach(async () => {
    await testEnv.clearStorage();
  });

  afterAll(async () => {
    await testEnv?.cleanup();
  });

  it("allows owner image upload under postImages and rejects wrong uid or content type", async () => {
    const storage = testEnv.authenticatedContext("alice").storage();
    const bytes = new Uint8Array([1, 2, 3]);

    await assertSucceeds(uploadBytes(
      ref(storage, "postImages/alice/draft-1/image.jpg"),
      bytes,
      {contentType: "image/jpeg"}
    ));
    await assertFails(uploadBytes(
      ref(storage, "postImages/bob/draft-1/image.jpg"),
      bytes,
      {contentType: "image/jpeg"}
    ));
    await assertFails(uploadBytes(
      ref(storage, "postImages/alice/draft-1/file.txt"),
      bytes,
      {contentType: "text/plain"}
    ));
  });
});
