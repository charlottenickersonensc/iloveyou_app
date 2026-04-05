const express = require("express");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const { v4: uuidv4 } = require("uuid");
const { pool } = require("../config/db");

const router = express.Router();

async function pickRandomFruitCommunityId() {
    const { rows } = await pool.query(`SELECT id FROM fruit_communities ORDER BY random() LIMIT 1`);
    if (!rows.length) throw new Error("fruit_communities seed missing");
    return rows[0].id;
}

async function fruitPayload(fruitCommunityId) {
    const { rows } = await pool.query(`SELECT id, code, name FROM fruit_communities WHERE id = $1`, [fruitCommunityId]);
    const fc = rows[0];
    if (!fc) return { fruitCommunityId, fruit: null };
    return {
        fruitCommunityId,
        fruit: { id: fc.id, code: fc.code, name: fc.name },
        fruitCode: fc.code,
        fruitName: fc.name,
    };
}

// =========================
// Signup Route
// =========================
router.post("/signup", async (req, res) => {
    try {
        const { email, username, password, dateOfBirth, pronouns, location, name, phoneNumber } = req.body;

        const missingFields = [];
        if (!email) missingFields.push("email");
        if (!username) missingFields.push("username");
        if (!password) missingFields.push("password");
        if (!dateOfBirth) missingFields.push("dateOfBirth");
        if (!location) missingFields.push("location");

        if (missingFields.length > 0) {
            return res.status(400).json({ error: "Missing required fields", missingFields });
        }

        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
            return res.status(400).json({ error: "Invalid email format" });
        }

        if (password.length < 8) {
            return res.status(400).json({ error: "Password must be at least 8 characters long" });
        }

        if (typeof location.latitude !== "number" || typeof location.longitude !== "number") {
            return res.status(400).json({ error: "Location must include numeric latitude and longitude" });
        }

        const existingUser = await pool.query("SELECT * FROM users WHERE email = $1 OR username = $2", [
            email,
            username,
        ]);
        if (existingUser.rows.length > 0) {
            return res.status(409).json({ error: "Email or username already exists" });
        }

        const fruitCommunityId = await pickRandomFruitCommunityId();
        const hashedPassword = await bcrypt.hash(password, 10);
        const userId = uuidv4();

        const query = `
      INSERT INTO users (
        id, username, email, password, date_of_birth, pronouns,
        latitude, longitude, fruit_community_id, phone_number, name
      )
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
      RETURNING id, username, email, fruit_community_id, created_at
    `;

        const values = [
            userId,
            username,
            email,
            hashedPassword,
            dateOfBirth,
            pronouns || null,
            location.latitude,
            location.longitude,
            fruitCommunityId,
            phoneNumber || null,
            name || null,
        ];

        const result = await pool.query(query, values);
        const userRow = result.rows[0];
        const fp = await fruitPayload(userRow.fruit_community_id);

        const token = jwt.sign(
            {
                id: userRow.id,
                email: userRow.email,
                username: userRow.username,
                fruitCommunityId: userRow.fruit_community_id,
            },
            process.env.JWT_SECRET,
            { expiresIn: process.env.JWT_EXPIRES_IN }
        );

        const user = {
            id: userRow.id,
            username: userRow.username,
            email: userRow.email,
            created_at: userRow.created_at,
            ...fp,
        };

        res.status(201).json({ message: "User created successfully", token, user });
    } catch (error) {
        console.error("Signup Error:", error);
        res.status(500).json({ error: "Internal server error" });
    }
});

// =========================
// Login Route
// =========================
router.post("/login", async (req, res) => {
    try {
        const { emailOrUsername, password } = req.body;

        if (!emailOrUsername || !password) {
            return res.status(400).json({ error: "Email/Username and password are required" });
        }

        const query = "SELECT * FROM users WHERE email = $1 OR username = $1";
        const result = await pool.query(query, [emailOrUsername]);
        const user = result.rows[0];

        if (!user || user.is_deleted) {
            return res.status(401).json({ error: "Invalid credentials" });
        }

        const passwordMatch = await bcrypt.compare(password, user.password);
        if (!passwordMatch) {
            return res.status(401).json({ error: "Invalid credentials" });
        }

        const fp = await fruitPayload(user.fruit_community_id);

        const token = jwt.sign(
            {
                id: user.id,
                email: user.email,
                username: user.username,
                fruitCommunityId: user.fruit_community_id,
            },
            process.env.JWT_SECRET,
            { expiresIn: process.env.JWT_EXPIRES_IN }
        );

        const minimalUser = {
            id: user.id,
            username: user.username,
            email: user.email,
            pronouns: user.pronouns,
            ...fp,
        };

        res.status(200).json({
            message: "Login successful",
            token,
            user: minimalUser,
        });
    } catch (error) {
        console.error("Login Error:", error);
        res.status(500).json({ error: "Internal server error" });
    }
});

module.exports = router;
