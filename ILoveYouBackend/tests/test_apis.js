const axios = require("axios");
const FormData = require("form-data");

const BASE = "http://localhost:3000";
const ts = Date.now();

let passed = 0;
let failed = 0;

// Shared state
let userToken, userId;
let user2Token, user2Id;
let user3Token, user3Id;
let postId, commentId;

function ok(name) {
    console.log(`  ✅ PASS: ${name}`);
    passed++;
}

function fail(name, err) {
    const msg = err?.response?.data ? JSON.stringify(err.response.data) : err?.message ?? String(err);
    console.log(`  ❌ FAIL: ${name} — ${msg}`);
    failed++;
}

async function expect(name, fn) {
    try {
        await fn();
        ok(name);
    } catch (e) {
        fail(name, e);
    }
}

function auth(token) {
    return { headers: { Authorization: `Bearer ${token}` } };
}

function assert(condition, msg) {
    if (!condition) throw new Error(msg || "Assertion failed");
}

// ========================
// 1. Health
// ========================
async function testHealth() {
    console.log("\n=== 1. Health ===");

    await expect("GET /hello → 200", async () => {
        const r = await axios.get(`${BASE}/hello`);
        assert(r.status === 200);
        assert(r.data.message);
    });
}

// ========================
// 2. Signup
// ========================
async function testSignup() {
    console.log("\n=== 2. Signup ===");

    const base = {
        email: `user_${ts}@test.com`,
        username: `user_${ts}`,
        password: "password123",
        dateOfBirth: "2000-01-01",
        location: { latitude: 37.77, longitude: -122.41 },
        name: "Test User",
        pronouns: "they/them",
    };

    await expect("POST /signup — happy path → 201 with token + user", async () => {
        const r = await axios.post(`${BASE}/signup`, base);
        assert(r.status === 201);
        assert(r.data.token);
        assert(r.data.user?.id);
        userToken = r.data.token;
        userId = r.data.user.id;
    });

    await expect("POST /signup — duplicate email → 409", async () => {
        try {
            await axios.post(`${BASE}/signup`, base);
            throw new Error("Expected 409");
        } catch (e) {
            assert(e.response?.status === 409);
        }
    });

    await expect("POST /signup — missing required fields → 400 with missingFields", async () => {
        try {
            await axios.post(`${BASE}/signup`, { email: "only@test.com" });
            throw new Error("Expected 400");
        } catch (e) {
            assert(e.response?.status === 400);
            assert(Array.isArray(e.response?.data?.missingFields));
        }
    });

    await expect("POST /signup — invalid email format → 400", async () => {
        try {
            await axios.post(`${BASE}/signup`, { ...base, email: "notanemail", username: `inv1_${ts}` });
            throw new Error("Expected 400");
        } catch (e) {
            assert(e.response?.status === 400);
        }
    });

    await expect("POST /signup — password too short (< 8 chars) → 400", async () => {
        try {
            await axios.post(`${BASE}/signup`, { ...base, password: "short", email: `sh_${ts}@t.com`, username: `sh_${ts}` });
            throw new Error("Expected 400");
        } catch (e) {
            assert(e.response?.status === 400);
        }
    });

    await expect("POST /signup — non-numeric location → 400", async () => {
        try {
            await axios.post(`${BASE}/signup`, { ...base, location: { latitude: "bad", longitude: 0 }, email: `loc_${ts}@t.com`, username: `loc_${ts}` });
            throw new Error("Expected 400");
        } catch (e) {
            assert(e.response?.status === 400);
        }
    });

    await expect("POST /signup — create user2 for friends tests", async () => {
        const r = await axios.post(`${BASE}/signup`, {
            email: `user2_${ts}@test.com`,
            username: `user2_${ts}`,
            password: "password123",
            dateOfBirth: "1999-06-15",
            location: { latitude: 0, longitude: 0 },
            name: "User Two",
        });
        assert(r.status === 201);
        user2Token = r.data.token;
        user2Id = r.data.user.id;
    });

    await expect("POST /signup — create user3 for reject tests", async () => {
        const r = await axios.post(`${BASE}/signup`, {
            email: `user3_${ts}@test.com`,
            username: `user3_${ts}`,
            password: "password123",
            dateOfBirth: "1998-03-20",
            location: { latitude: 0, longitude: 0 },
        });
        assert(r.status === 201);
        user3Token = r.data.token;
        user3Id = r.data.user.id;
    });
}

// ========================
// 3. Login
// ========================
async function testLogin() {
    console.log("\n=== 3. Login ===");

    await expect("POST /login — login with email → 200 with token", async () => {
        const r = await axios.post(`${BASE}/login`, { emailOrUsername: `user_${ts}@test.com`, password: "password123" });
        assert(r.status === 200);
        assert(r.data.token);
        userToken = r.data.token;
    });

    await expect("POST /login — login with username → 200", async () => {
        const r = await axios.post(`${BASE}/login`, { emailOrUsername: `user_${ts}`, password: "password123" });
        assert(r.status === 200);
        assert(r.data.token);
    });

    await expect("POST /login — wrong password → 401", async () => {
        try {
            await axios.post(`${BASE}/login`, { emailOrUsername: `user_${ts}@test.com`, password: "wrongpass" });
            throw new Error("Expected 401");
        } catch (e) {
            assert(e.response?.status === 401);
        }
    });

    await expect("POST /login — non-existent user → 401", async () => {
        try {
            await axios.post(`${BASE}/login`, { emailOrUsername: "ghost@test.com", password: "password123" });
            throw new Error("Expected 401");
        } catch (e) {
            assert(e.response?.status === 401);
        }
    });

    await expect("POST /login — missing password → 400", async () => {
        try {
            await axios.post(`${BASE}/login`, { emailOrUsername: `user_${ts}@test.com` });
            throw new Error("Expected 400");
        } catch (e) {
            assert(e.response?.status === 400);
        }
    });

    await expect("Malformed Bearer token on protected route → 403 (backend distinguishes no-token=401 vs bad-token=403)", async () => {
        try {
            await axios.get(`${BASE}/v1/feed`, { headers: { Authorization: "Bearer this.is.a.fake.token" } });
            throw new Error("Expected 403");
        } catch (e) {
            assert(e.response?.status === 403, `Expected 403, got ${e.response?.status}`);
        }
    });

    await expect("Missing Authorization header on protected route → 401", async () => {
        try {
            await axios.get(`${BASE}/v1/feed`); // GET /v1/feed requires auth
            throw new Error("Expected 401");
        } catch (e) {
            assert(e.response?.status === 401, `Expected 401, got ${e.response?.status}`);
        }
    });
}

// ========================
// 4. User Routes
// ========================
async function testUserRoutes() {
    console.log("\n=== 4. User Routes ===");

    await expect("PATCH /account/privacy — set true → 200", async () => {
        const r = await axios.patch(`${BASE}/account/privacy`, { isPrivate: true }, auth(userToken));
        assert(r.status === 200);
        assert(r.data.user.is_private === true);
    });

    await expect("PATCH /account/privacy — set false → 200", async () => {
        const r = await axios.patch(`${BASE}/account/privacy`, { isPrivate: false }, auth(userToken));
        assert(r.status === 200);
        assert(r.data.user.is_private === false);
    });

    await expect("PATCH /account/privacy — no auth → 401", async () => {
        try {
            await axios.patch(`${BASE}/account/privacy`, { isPrivate: true });
            throw new Error("Expected 401");
        } catch (e) {
            assert(e.response?.status === 401);
        }
    });

    await expect("PATCH /account/privacy — non-boolean isPrivate → 400", async () => {
        try {
            await axios.patch(`${BASE}/account/privacy`, { isPrivate: "yes" }, auth(userToken));
            throw new Error("Expected 400");
        } catch (e) {
            assert(e.response?.status === 400);
        }
    });

    await expect("PATCH /account/interests — update array → 200", async () => {
        const r = await axios.patch(`${BASE}/account/interests`, { interests: ["Gaming", "Music"] }, auth(userToken));
        assert(r.status === 200);
        assert(Array.isArray(r.data.user.interests));
    });

    await expect("PATCH /account/interests — empty array is valid → 200", async () => {
        const r = await axios.patch(`${BASE}/account/interests`, { interests: [] }, auth(userToken));
        assert(r.status === 200);
    });

    await expect("PATCH /account/interests — non-array → 400", async () => {
        try {
            await axios.patch(`${BASE}/account/interests`, { interests: "sports" }, auth(userToken));
            throw new Error("Expected 400");
        } catch (e) {
            assert(e.response?.status === 400);
        }
    });

    await expect("PATCH /account/interests — no auth → 401", async () => {
        try {
            await axios.patch(`${BASE}/account/interests`, { interests: [] });
            throw new Error("Expected 401");
        } catch (e) {
            assert(e.response?.status === 401);
        }
    });

    await expect("POST /account/profile-picture — no auth → 401", async () => {
        try {
            const form = new FormData();
            await axios.post(`${BASE}/account/profile-picture`, form, { headers: form.getHeaders() });
            throw new Error("Expected 401");
        } catch (e) {
            assert(e.response?.status === 401);
        }
    });

    await expect("POST /account/profile-picture — no file → 400 or 500 (multer-s3 parse error)", async () => {
        try {
            const form = new FormData();
            await axios.post(`${BASE}/account/profile-picture`, form, {
                headers: { ...auth(userToken).headers, ...form.getHeaders() },
            });
            throw new Error("Expected 4xx or 5xx");
        } catch (e) {
            assert([400, 500].includes(e.response?.status), `Expected 400 or 500, got ${e.response?.status}`);
        }
    });
}

// ========================
// 5. Friend Routes
// ========================
async function testFriendRoutes() {
    console.log("\n=== 5. Friends ===");

    await expect("POST /friends/request — missing friendId → 400", async () => {
        try {
            await axios.post(`${BASE}/friends/request`, {}, auth(userToken));
            throw new Error("Expected 400");
        } catch (e) {
            assert(e.response?.status === 400);
        }
    });

    await expect("POST /friends/request — self request → 400", async () => {
        try {
            await axios.post(`${BASE}/friends/request`, { friendId: userId }, auth(userToken));
            throw new Error("Expected 400");
        } catch (e) {
            assert(e.response?.status === 400);
        }
    });

    await expect("POST /friends/request — non-existent user → 404", async () => {
        try {
            await axios.post(`${BASE}/friends/request`, { friendId: "00000000-0000-0000-0000-000000000000" }, auth(userToken));
            throw new Error("Expected 404");
        } catch (e) {
            assert(e.response?.status === 404);
        }
    });

    await expect("POST /friends/request — user → user2 → 201", async () => {
        const r = await axios.post(`${BASE}/friends/request`, { friendId: user2Id }, auth(userToken));
        assert(r.status === 201);
    });

    await expect("POST /friends/request — duplicate request → 409", async () => {
        try {
            await axios.post(`${BASE}/friends/request`, { friendId: user2Id }, auth(userToken));
            throw new Error("Expected 409");
        } catch (e) {
            assert(e.response?.status === 409);
        }
    });

    await expect("POST /friends/request — no auth → 401", async () => {
        try {
            await axios.post(`${BASE}/friends/request`, { friendId: user2Id });
            throw new Error("Expected 401");
        } catch (e) {
            assert(e.response?.status === 401);
        }
    });

    await expect("GET /friends/requests — user2 sees pending request → 200", async () => {
        const r = await axios.get(`${BASE}/friends/requests`, auth(user2Token));
        assert(r.status === 200);
        assert(Array.isArray(r.data.pendingRequests));
        assert(r.data.pendingRequests.some((p) => p.id === userId));
    });

    await expect("GET /friends/requests — no auth → 401", async () => {
        try {
            await axios.get(`${BASE}/friends/requests`);
            throw new Error("Expected 401");
        } catch (e) {
            assert(e.response?.status === 401);
        }
    });

    await expect("POST /friends/accept — non-existent request → 404", async () => {
        try {
            await axios.post(`${BASE}/friends/accept`, { friendId: user3Id }, auth(user2Token));
            throw new Error("Expected 404");
        } catch (e) {
            assert(e.response?.status === 404);
        }
    });

    await expect("POST /friends/accept — user2 accepts user → 200", async () => {
        const r = await axios.post(`${BASE}/friends/accept`, { friendId: userId }, auth(user2Token));
        assert(r.status === 200);
    });

    await expect("POST /friends/accept — already accepted → 404", async () => {
        try {
            await axios.post(`${BASE}/friends/accept`, { friendId: userId }, auth(user2Token));
            throw new Error("Expected 404");
        } catch (e) {
            assert(e.response?.status === 404);
        }
    });

    await expect("POST /friends/accept — missing friendId → 400", async () => {
        try {
            await axios.post(`${BASE}/friends/accept`, {}, auth(user2Token));
            throw new Error("Expected 400");
        } catch (e) {
            assert(e.response?.status === 400);
        }
    });

    await expect("GET /friends/ — user sees user2 in friends list → 200", async () => {
        const r = await axios.get(`${BASE}/friends/`, auth(userToken));
        assert(r.status === 200);
        assert(r.data.friends.some((f) => f.id === user2Id));
    });

    await expect("GET /friends/ — user2 also sees user (bidirectional) → 200", async () => {
        const r = await axios.get(`${BASE}/friends/`, auth(user2Token));
        assert(r.status === 200);
        assert(r.data.friends.some((f) => f.id === userId), "Bidirectional: user2 should see user1 in friends");
    });

    await expect("GET /friends/ — no auth → 401", async () => {
        try {
            await axios.get(`${BASE}/friends/`);
            throw new Error("Expected 401");
        } catch (e) {
            assert(e.response?.status === 401);
        }
    });

    // Reject flow with user3
    await expect("POST /friends/request — user → user3 → 201", async () => {
        const r = await axios.post(`${BASE}/friends/request`, { friendId: user3Id }, auth(userToken));
        assert(r.status === 201);
    });

    await expect("POST /friends/reject — user3 rejects request → 200", async () => {
        const r = await axios.post(`${BASE}/friends/reject`, { friendId: userId }, auth(user3Token));
        assert(r.status === 200);
    });

    await expect("POST /friends/reject — missing friendId → 400", async () => {
        try {
            await axios.post(`${BASE}/friends/reject`, {}, auth(user3Token));
            throw new Error("Expected 400");
        } catch (e) {
            assert(e.response?.status === 400);
        }
    });

    await expect("POST /friends/reject — no relationship left → 404", async () => {
        try {
            await axios.post(`${BASE}/friends/reject`, { friendId: userId }, auth(user3Token));
            throw new Error("Expected 404");
        } catch (e) {
            assert(e.response?.status === 404);
        }
    });
}

// ========================
// 6. Feed — Read + Create Posts
// ========================
async function testFeedAndPosts() {
    console.log("\n=== 6. Feed + Create Posts ===");

    await expect("GET /v1/feed — no auth → 401", async () => {
        try {
            await axios.get(`${BASE}/v1/feed`);
            throw new Error("Expected 401");
        } catch (e) {
            assert(e.response?.status === 401);
        }
    });

    await expect("GET /v1/feed — authenticated, returns posts array → 200", async () => {
        const r = await axios.get(`${BASE}/v1/feed`, auth(userToken));
        assert(r.status === 200);
        assert(Array.isArray(r.data.posts));
    });

    await expect("POST /v1/posts — no auth → 401", async () => {
        try {
            await axios.post(`${BASE}/v1/posts`, { contentText: "hi" });
            throw new Error("Expected 401");
        } catch (e) {
            assert(e.response?.status === 401);
        }
    });

    await expect("POST /v1/posts — missing contentText → 400", async () => {
        try {
            await axios.post(`${BASE}/v1/posts`, {}, auth(userToken));
            throw new Error("Expected 400");
        } catch (e) {
            assert(e.response?.status === 400);
        }
    });

    await expect("POST /v1/posts — whitespace-only contentText → 400", async () => {
        try {
            await axios.post(`${BASE}/v1/posts`, { contentText: "   " }, auth(userToken));
            throw new Error("Expected 400");
        } catch (e) {
            assert(e.response?.status === 400);
        }
    });

    await expect("POST /v1/posts — contentText over 2000 chars → 400", async () => {
        try {
            await axios.post(`${BASE}/v1/posts`, { contentText: "a".repeat(2001) }, auth(userToken));
            throw new Error("Expected 400");
        } catch (e) {
            assert(e.response?.status === 400);
        }
    });

    await expect("POST /v1/posts — invalid visibility → 400", async () => {
        try {
            await axios.post(`${BASE}/v1/posts`, { contentText: "hi", visibility: "everyone" }, auth(userToken));
            throw new Error("Expected 400");
        } catch (e) {
            assert(e.response?.status === 400);
        }
    });

    await expect("POST /v1/posts — group visibility without groupId → 400", async () => {
        try {
            await axios.post(`${BASE}/v1/posts`, { contentText: "hi", visibility: "group" }, auth(userToken));
            throw new Error("Expected 400");
        } catch (e) {
            assert(e.response?.status === 400);
        }
    });

    await expect("POST /v1/posts — blocked word in content → 400", async () => {
        try {
            await axios.post(`${BASE}/v1/posts`, { contentText: "contains blockedtestword here" }, auth(userToken));
            throw new Error("Expected 400");
        } catch (e) {
            assert(e.response?.status === 400);
        }
    });

    await expect("POST /v1/posts — valid fruit post → 201 with post + images array", async () => {
        const r = await axios.post(`${BASE}/v1/posts`, { contentText: "Hello feed! First post.", visibility: "fruit" }, auth(userToken));
        assert(r.status === 201);
        assert(r.data.post?.id);
        assert(Array.isArray(r.data.post?.images));
        postId = r.data.post.id;
    });

    await expect("POST /v1/posts — friends-only post → 201", async () => {
        const r = await axios.post(`${BASE}/v1/posts`, { contentText: "Just for friends.", visibility: "friends" }, auth(userToken));
        assert(r.status === 201);
        assert(r.data.post?.id);
    });

    await expect("GET /v1/feed — friends-only post does NOT appear in fruit feed", async () => {
        const r = await axios.get(`${BASE}/v1/feed`, auth(userToken));
        assert(r.status === 200);
        const friendsPost = r.data.posts.find((p) => p.visibility === "friends");
        assert(!friendsPost, "Friends-only post must not appear in the fruit community feed");
    });

    await expect("POST /v1/posts — with imageUrls → 201, images array populated", async () => {
        const r = await axios.post(`${BASE}/v1/posts`, {
            contentText: "Post with two images!",
            visibility: "fruit",
            imageUrls: [
                "https://example.com/img1.jpg",
                "https://example.com/img2.jpg",
            ],
        }, auth(userToken));
        assert(r.status === 201);
        assert(r.data.post?.images?.length === 2, `Expected 2 images, got ${r.data.post?.images?.length}`);
        assert(r.data.post.images[0].imageUrl === "https://example.com/img1.jpg");
        assert(r.data.post.images[1].imageUrl === "https://example.com/img2.jpg");
        assert(r.data.post.images[0].displayOrder === 0);
        assert(r.data.post.images[1].displayOrder === 1);
    });

    await expect("GET /v1/feed — after post creation, returns ≥ 1 post", async () => {
        const r = await axios.get(`${BASE}/v1/feed`, auth(userToken));
        assert(r.status === 200);
        assert(r.data.posts.length >= 1);
    });

    await expect("GET /v1/feed — limit param respected", async () => {
        const r = await axios.get(`${BASE}/v1/feed?limit=1`, auth(userToken));
        assert(r.status === 200);
        assert(r.data.posts.length <= 1);
    });

    await expect("GET /v1/feed — cursor pagination: page 2 has different posts than page 1", async () => {
        const page1 = await axios.get(`${BASE}/v1/feed?limit=1`, auth(userToken));
        assert(page1.status === 200);
        if (page1.data.nextCursor && page1.data.posts.length === 1) {
            const firstPostId = page1.data.posts[0].id;
            const page2 = await axios.get(`${BASE}/v1/feed?limit=1&cursor=${page1.data.nextCursor}`, auth(userToken));
            assert(page2.status === 200);
            assert(Array.isArray(page2.data.posts));
            const overlap = page2.data.posts.find((p) => p.id === firstPostId);
            assert(!overlap, "Page 2 must not contain posts from page 1");
        }
        // If no nextCursor, only 1 post exists — cursor pagination N/A, pass
    });

    await expect("GET /v1/feed — nextCursor present when more pages exist", async () => {
        const r = await axios.get(`${BASE}/v1/feed?limit=1`, auth(userToken));
        if (r.data.posts.length === 1) {
            assert(r.data.nextCursor !== undefined);
        }
    });
}

// ========================
// 7. Single Post
// ========================
async function testSinglePost() {
    console.log("\n=== 7. Single Post GET ===");

    await expect("GET /v1/posts/:postId — valid → 200 with post", async () => {
        const r = await axios.get(`${BASE}/v1/posts/${postId}`, auth(userToken));
        assert(r.status === 200);
        assert(r.data.post?.id === postId);
        assert(Array.isArray(r.data.post?.images));
    });

    await expect("GET /v1/posts/:postId — invalid UUID → 400", async () => {
        try {
            await axios.get(`${BASE}/v1/posts/not-a-uuid`, auth(userToken));
            throw new Error("Expected 400");
        } catch (e) {
            assert(e.response?.status === 400);
        }
    });

    await expect("GET /v1/posts/:postId — non-existent UUID → 404", async () => {
        try {
            await axios.get(`${BASE}/v1/posts/00000000-0000-0000-0000-000000000000`, auth(userToken));
            throw new Error("Expected 404");
        } catch (e) {
            assert(e.response?.status === 404);
        }
    });

    await expect("GET /v1/posts/:postId — no auth → 401", async () => {
        try {
            await axios.get(`${BASE}/v1/posts/${postId}`);
            throw new Error("Expected 401");
        } catch (e) {
            assert(e.response?.status === 401);
        }
    });
}

// ========================
// 8. Likes
// ========================
async function testLikes() {
    console.log("\n=== 8. Likes ===");

    await expect("POST likes/toggle — like post → liked:true, likeCount:1", async () => {
        const r = await axios.post(`${BASE}/v1/posts/${postId}/likes/toggle`, {}, auth(userToken));
        assert(r.status === 200);
        assert(r.data.liked === true);
        assert(r.data.likeCount === 1);
    });

    await expect("POST likes/toggle — unlike same post → liked:false, likeCount:0", async () => {
        const r = await axios.post(`${BASE}/v1/posts/${postId}/likes/toggle`, {}, auth(userToken));
        assert(r.status === 200);
        assert(r.data.liked === false);
        assert(r.data.likeCount === 0);
    });

    await expect("POST likes/toggle — like again (for trending score)", async () => {
        const r = await axios.post(`${BASE}/v1/posts/${postId}/likes/toggle`, {}, auth(userToken));
        assert(r.data.liked === true);
    });

    await expect("POST likes/toggle — invalid postId UUID → 400", async () => {
        try {
            await axios.post(`${BASE}/v1/posts/bad-id/likes/toggle`, {}, auth(userToken));
            throw new Error("Expected 400");
        } catch (e) {
            assert(e.response?.status === 400);
        }
    });

    await expect("POST likes/toggle — non-existent post → 404", async () => {
        try {
            await axios.post(`${BASE}/v1/posts/00000000-0000-0000-0000-000000000000/likes/toggle`, {}, auth(userToken));
            throw new Error("Expected 404");
        } catch (e) {
            assert(e.response?.status === 404);
        }
    });

    await expect("POST likes/toggle — no auth → 401", async () => {
        try {
            await axios.post(`${BASE}/v1/posts/${postId}/likes/toggle`, {});
            throw new Error("Expected 401");
        } catch (e) {
            assert(e.response?.status === 401);
        }
    });
}

// ========================
// 9. Comments
// ========================
async function testComments() {
    console.log("\n=== 9. Comments ===");

    await expect("POST comments — missing content → 400", async () => {
        try {
            await axios.post(`${BASE}/v1/posts/${postId}/comments`, {}, auth(userToken));
            throw new Error("Expected 400");
        } catch (e) {
            assert(e.response?.status === 400);
        }
    });

    await expect("POST comments — whitespace-only content → 400", async () => {
        try {
            await axios.post(`${BASE}/v1/posts/${postId}/comments`, { content: "   " }, auth(userToken));
            throw new Error("Expected 400");
        } catch (e) {
            assert(e.response?.status === 400);
        }
    });

    await expect("POST comments — content over 500 chars → 400", async () => {
        try {
            await axios.post(`${BASE}/v1/posts/${postId}/comments`, { content: "a".repeat(501) }, auth(userToken));
            throw new Error("Expected 400");
        } catch (e) {
            assert(e.response?.status === 400);
        }
    });

    await expect("POST comments — blocked word → 400", async () => {
        try {
            await axios.post(`${BASE}/v1/posts/${postId}/comments`, { content: "here is blockedtestword" }, auth(userToken));
            throw new Error("Expected 400");
        } catch (e) {
            assert(e.response?.status === 400);
        }
    });

    await expect("POST comments — valid comment → 201", async () => {
        const r = await axios.post(`${BASE}/v1/posts/${postId}/comments`, { content: "Great post!" }, auth(userToken));
        assert(r.status === 201);
        assert(r.data.comment?.id);
        commentId = r.data.comment.id;
    });

    await expect("POST comments — second comment → 201 (comment_count increments)", async () => {
        const r = await axios.post(`${BASE}/v1/posts/${postId}/comments`, { content: "Another one!" }, auth(userToken));
        assert(r.status === 201);
    });

    await expect("POST comments — no auth → 401", async () => {
        try {
            await axios.post(`${BASE}/v1/posts/${postId}/comments`, { content: "hi" });
            throw new Error("Expected 401");
        } catch (e) {
            assert(e.response?.status === 401);
        }
    });

    await expect("GET comments — returns array with ≥ 2 → 200", async () => {
        const r = await axios.get(`${BASE}/v1/posts/${postId}/comments`, auth(userToken));
        assert(r.status === 200);
        assert(Array.isArray(r.data.comments));
        assert(r.data.comments.length >= 2);
    });

    await expect("GET comments — limit param respected", async () => {
        const r = await axios.get(`${BASE}/v1/posts/${postId}/comments?limit=1&offset=0`, auth(userToken));
        assert(r.status === 200);
        assert(r.data.comments.length <= 1);
    });

    await expect("GET comments — invalid postId → 400", async () => {
        try {
            await axios.get(`${BASE}/v1/posts/not-valid/comments`, auth(userToken));
            throw new Error("Expected 400");
        } catch (e) {
            assert(e.response?.status === 400);
        }
    });

    await expect("GET comments — non-existent post → 404", async () => {
        try {
            await axios.get(`${BASE}/v1/posts/00000000-0000-0000-0000-000000000000/comments`, auth(userToken));
            throw new Error("Expected 404");
        } catch (e) {
            assert(e.response?.status === 404);
        }
    });

    await expect("GET comments — no auth → 401", async () => {
        try {
            await axios.get(`${BASE}/v1/posts/${postId}/comments`);
            throw new Error("Expected 401");
        } catch (e) {
            assert(e.response?.status === 401);
        }
    });

    await expect("DELETE comment — invalid commentId UUID → 400", async () => {
        try {
            await axios.delete(`${BASE}/v1/posts/${postId}/comments/bad-id`, auth(userToken));
            throw new Error("Expected 400");
        } catch (e) {
            assert(e.response?.status === 400);
        }
    });

    await expect("DELETE comment — wrong author (user2) → 404", async () => {
        try {
            await axios.delete(`${BASE}/v1/posts/${postId}/comments/${commentId}`, auth(user2Token));
            throw new Error("Expected 404");
        } catch (e) {
            assert(e.response?.status === 404);
        }
    });

    await expect("DELETE comment — no auth → 401", async () => {
        try {
            await axios.delete(`${BASE}/v1/posts/${postId}/comments/${commentId}`);
            throw new Error("Expected 401");
        } catch (e) {
            assert(e.response?.status === 401);
        }
    });

    await expect("DELETE comment — valid delete by author → 200", async () => {
        const r = await axios.delete(`${BASE}/v1/posts/${postId}/comments/${commentId}`, auth(userToken));
        assert(r.status === 200);
        assert(r.data.ok === true);
    });

    await expect("DELETE comment — already deleted → 404", async () => {
        try {
            await axios.delete(`${BASE}/v1/posts/${postId}/comments/${commentId}`, auth(userToken));
            throw new Error("Expected 404");
        } catch (e) {
            assert(e.response?.status === 404);
        }
    });
}

// ========================
// 10. Reports
// ========================
async function testReports() {
    console.log("\n=== 10. Reports ===");

    await expect("POST reports — missing reason → 400", async () => {
        try {
            await axios.post(`${BASE}/v1/posts/${postId}/reports`, {}, auth(userToken));
            throw new Error("Expected 400");
        } catch (e) {
            assert(e.response?.status === 400);
        }
    });

    await expect("POST reports — invalid reason → 400", async () => {
        try {
            await axios.post(`${BASE}/v1/posts/${postId}/reports`, { reason: "bad_reason" }, auth(userToken));
            throw new Error("Expected 400");
        } catch (e) {
            assert(e.response?.status === 400);
        }
    });

    await expect("POST reports — reason=other with no details → 400", async () => {
        try {
            await axios.post(`${BASE}/v1/posts/${postId}/reports`, { reason: "other" }, auth(userToken));
            throw new Error("Expected 400");
        } catch (e) {
            assert(e.response?.status === 400);
        }
    });

    await expect("POST reports — reason=other with empty details → 400", async () => {
        try {
            await axios.post(`${BASE}/v1/posts/${postId}/reports`, { reason: "other", details: "  " }, auth(userToken));
            throw new Error("Expected 400");
        } catch (e) {
            assert(e.response?.status === 400);
        }
    });

    await expect("POST reports — valid spam report → 201", async () => {
        const r = await axios.post(`${BASE}/v1/posts/${postId}/reports`, { reason: "spam" }, auth(userToken));
        assert(r.status === 201);
        assert(r.data.report?.id);
    });

    await expect("POST reports — duplicate report same day → 409", async () => {
        try {
            await axios.post(`${BASE}/v1/posts/${postId}/reports`, { reason: "harassment" }, auth(userToken));
            throw new Error("Expected 409");
        } catch (e) {
            assert(e.response?.status === 409);
        }
    });

    await expect("POST reports — reason=other with valid details → 201", async () => {
        // Create a fresh post to avoid the same-day duplicate constraint
        const np = await axios.post(`${BASE}/v1/posts`, { contentText: "Another post to report." }, auth(userToken));
        const newPostId = np.data.post.id;
        const r = await axios.post(`${BASE}/v1/posts/${newPostId}/reports`, {
            reason: "other",
            details: "This is a specific reason for reporting.",
        }, auth(userToken));
        assert(r.status === 201);
    });

    await expect("POST reports — non-existent post → 404", async () => {
        try {
            await axios.post(`${BASE}/v1/posts/00000000-0000-0000-0000-000000000000/reports`, { reason: "spam" }, auth(userToken));
            throw new Error("Expected 404");
        } catch (e) {
            assert(e.response?.status === 404);
        }
    });

    await expect("POST reports — no auth → 401", async () => {
        try {
            await axios.post(`${BASE}/v1/posts/${postId}/reports`, { reason: "spam" });
            throw new Error("Expected 401");
        } catch (e) {
            assert(e.response?.status === 401);
        }
    });
}

// ========================
// 11. Trending Feed
// ========================
async function testTrending() {
    console.log("\n=== 11. Trending Feed ===");

    await expect("GET /v1/feed/trending — no auth → 401", async () => {
        try {
            await axios.get(`${BASE}/v1/feed/trending`);
            throw new Error("Expected 401");
        } catch (e) {
            assert(e.response?.status === 401);
        }
    });

    await expect("GET /v1/feed/trending — returns posts array → 200", async () => {
        const r = await axios.get(`${BASE}/v1/feed/trending`, auth(userToken));
        assert(r.status === 200);
        assert(Array.isArray(r.data.posts));
    });

    await expect("GET /v1/feed/trending — limit param respected", async () => {
        const r = await axios.get(`${BASE}/v1/feed/trending?limit=5`, auth(userToken));
        assert(r.status === 200);
        assert(r.data.posts.length <= 5);
    });

    await expect("GET /v1/feed/trending — nextCursor field present in response", async () => {
        const r = await axios.get(`${BASE}/v1/feed/trending`, auth(userToken));
        assert("nextCursor" in r.data);
    });
}

// ========================
// 12. Image Presign
// ========================
async function testPresign() {
    console.log("\n=== 12. Image Presign URL ===");

    await expect("POST /v1/posts/images/presign — no auth → 401", async () => {
        try {
            await axios.post(`${BASE}/v1/posts/images/presign`, { draftId: "11111111-1111-1111-1111-111111111111" });
            throw new Error("Expected 401");
        } catch (e) {
            assert(e.response?.status === 401);
        }
    });

    await expect("POST /v1/posts/images/presign — missing draftId → 400", async () => {
        try {
            await axios.post(`${BASE}/v1/posts/images/presign`, { filename: "photo.jpg" }, auth(userToken));
            throw new Error("Expected 400");
        } catch (e) {
            assert(e.response?.status === 400);
        }
    });

    await expect("POST /v1/posts/images/presign — invalid draftId (not UUID) → 400", async () => {
        try {
            await axios.post(`${BASE}/v1/posts/images/presign`, { draftId: "not-a-valid-uuid", filename: "photo.jpg" }, auth(userToken));
            throw new Error("Expected 400");
        } catch (e) {
            assert(e.response?.status === 400);
        }
    });

    await expect("POST /v1/posts/images/presign — valid request → 200 with uploadUrl or 503 if S3 not configured", async () => {
        // Use a proper RFC 4122 v4 UUID (variant bits must be 8/9/a/b in 17th char)
        const validDraftId = "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11";
        const r = await axios.post(
            `${BASE}/v1/posts/images/presign`,
            { draftId: validDraftId, filename: "photo.jpg" },
            auth(userToken)
        ).catch(e => e.response);
        assert([200, 503].includes(r.status), `Expected 200 or 503, got ${r.status}`);
        if (r.status === 200) {
            assert(r.data.uploadUrl, "uploadUrl missing");
            assert(r.data.key, "key missing");
        }
    });
}

// ========================
// 13. Delete Post (last — affects other tests)
// ========================
async function testDeletePost() {
    console.log("\n=== 13. Delete Post ===");

    await expect("DELETE /v1/posts/:postId — invalid UUID → 400", async () => {
        try {
            await axios.delete(`${BASE}/v1/posts/not-a-uuid`, auth(userToken));
            throw new Error("Expected 400");
        } catch (e) {
            assert(e.response?.status === 400);
        }
    });

    await expect("DELETE /v1/posts/:postId — non-existent UUID → 404", async () => {
        try {
            await axios.delete(`${BASE}/v1/posts/00000000-0000-0000-0000-000000000000`, auth(userToken));
            throw new Error("Expected 404");
        } catch (e) {
            assert(e.response?.status === 404);
        }
    });

    await expect("DELETE /v1/posts/:postId — no auth → 401", async () => {
        try {
            await axios.delete(`${BASE}/v1/posts/${postId}`);
            throw new Error("Expected 401");
        } catch (e) {
            assert(e.response?.status === 401);
        }
    });

    await expect("DELETE /v1/posts/:postId — wrong user (user2) → 404", async () => {
        try {
            await axios.delete(`${BASE}/v1/posts/${postId}`, auth(user2Token));
            throw new Error("Expected 404");
        } catch (e) {
            assert(e.response?.status === 404);
        }
    });

    await expect("DELETE /v1/posts/:postId — author deletes own post → 200", async () => {
        const r = await axios.delete(`${BASE}/v1/posts/${postId}`, auth(userToken));
        assert(r.status === 200);
        assert(r.data.ok === true);
    });

    await expect("GET /v1/feed — deleted post no longer appears in feed", async () => {
        const r = await axios.get(`${BASE}/v1/feed`, auth(userToken));
        assert(r.status === 200);
        const found = r.data.posts.find((p) => p.id === postId);
        assert(!found, "Deleted post should not appear in feed");
    });

    await expect("POST likes/toggle — on deleted post → 404 (moderation blocks interaction)", async () => {
        try {
            await axios.post(`${BASE}/v1/posts/${postId}/likes/toggle`, {}, auth(userToken));
            throw new Error("Expected 404");
        } catch (e) {
            assert(e.response?.status === 404);
        }
    });

    await expect("POST comments — on deleted post → 404 (moderation blocks interaction)", async () => {
        try {
            await axios.post(`${BASE}/v1/posts/${postId}/comments`, { content: "Can I still comment?" }, auth(userToken));
            throw new Error("Expected 404");
        } catch (e) {
            assert(e.response?.status === 404);
        }
    });
}

// ========================
// MAIN
// ========================
async function runAll() {
    console.log("==============================================");
    console.log("   iloveyou Backend — Full API Test Suite");
    console.log("==============================================");

    await testHealth();
    await testSignup();
    await testLogin();
    await testUserRoutes();
    await testFriendRoutes();
    await testFeedAndPosts();
    await testSinglePost();
    await testLikes();
    await testComments();
    await testReports();
    await testTrending();
    await testPresign();
    await testDeletePost(); // Always last — deletes shared postId

    console.log("\n==============================================");
    console.log(`   Results: ✅ ${passed} passed   ❌ ${failed} failed`);
    console.log(`   Total: ${passed + failed} tests`);
    console.log("==============================================\n");

    if (failed > 0) process.exit(1);
}

runAll();
