const axios = require("axios");
const FormData = require("form-data");
const fs = require("fs");

const BASE_URL = "http://localhost:3000";

async function testAllEndpoints() {
    console.log("Starting Backend API Tests...\n");
    let token = "";
    let userId = "";

    try {
        // 1. Test Server Health
        console.log("1. Testing GET /hello...");
        const helloRes = await axios.get(`${BASE_URL}/hello`);
        console.log("   Success:", helloRes.data);

        // 2. Test Signup
        const testUser = {
            email: `test_${Date.now()}@example.com`,
            username: `tester_${Date.now()}`,
            password: "password123",
            dateOfBirth: "2000-01-01",
            location: { latitude: 37.77, longitude: -122.41 },
            name: "Test User",
            pronouns: "they/them"
        };
        console.log("\n2. Testing POST /signup...");
        const signupRes = await axios.post(`${BASE_URL}/signup`, testUser);
        console.log("   Success! Created user:", signupRes.data.user.username);

        // 3. Test Login
        console.log("\n3. Testing POST /login...");
        const loginRes = await axios.post(`${BASE_URL}/login`, {
            emailOrUsername: testUser.email,
            password: "password123"
        });
        token = loginRes.data.token;
        userId = loginRes.data.user.id;
        console.log("   Success! Got JWT Token:", token.substring(0, 20) + "...");

        const authConfig = { headers: { Authorization: `Bearer ${token}` } };

        // 4. Test Update Privacy
        console.log("\n4. Testing PATCH /account/privacy...");
        const privacyRes = await axios.patch(`${BASE_URL}/account/privacy`, { isPrivate: true }, authConfig);
        console.log("   Success! is_private is now:", privacyRes.data.user.is_private);

        // 5. Test Update Interests
        console.log("\n5. Testing PATCH /account/interests...");
        const interestsRes = await axios.patch(`${BASE_URL}/account/interests`, { interests: ["Tech", "Anime"] }, authConfig);
        console.log("   Success! interests are now:", interestsRes.data.user.interests);

        // 6. Test Friends API
        console.log("\n6. Testing Friends API (Creating a dummy friend to request)...");
        // Create dummy friend
        const dummyRes = await axios.post(`${BASE_URL}/signup`, {
            email: `friend_${Date.now()}@example.com`,
            username: `dummy_${Date.now()}`,
            password: "password123",
            dateOfBirth: "1999-01-01",
            location: { latitude: 0, longitude: 0 }
        });
        const dummyId = dummyRes.data.user.id;
        
        console.log("   Sending Friend Request...");
        const reqRes = await axios.post(`${BASE_URL}/friends/request`, { friendId: dummyId }, authConfig);
        console.log("   Success! Request sent.");
        
        console.log("   Getting outgoing requests (from Dummy perspective)...");
        const dummyToken = dummyRes.data.token;
        const dummyReqs = await axios.get(`${BASE_URL}/friends/requests`, { headers: { Authorization: `Bearer ${dummyToken}` } });
        console.log("   Success! Dummy has pending requests from:", dummyReqs.data.pendingRequests.map(r => r.username));

        // 7. Test S3 Profile Picture Upload
        console.log("\n7. Testing POST /account/profile-picture...");
        
        const dummyImagePath = "./dummy_image.jpg";
        fs.writeFileSync(dummyImagePath, "fake image content for testing");
        
        const form = new FormData();
        form.append("profileImage", fs.createReadStream(dummyImagePath));
        
        const uploadRes = await axios.post(`${BASE_URL}/account/profile-picture`, form, {
            headers: {
                ...authConfig.headers,
                ...form.getHeaders()
            }
        });
        
        console.log("   Success! Uploaded to S3 URL:", uploadRes.data.imageUrl);
        
        // Clean up dummy file
        fs.unlinkSync(dummyImagePath);
        
        console.log("\nALL TESTS PASSED!");

    } catch (error) {
        console.error("\nTEST FAILED:", error.response ? error.response.data : error.message);
    }
}

testAllEndpoints();
