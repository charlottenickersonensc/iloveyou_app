const express = require("express");
const { Pool } = require("pg");
const bcrypt = require("bcrypt");
const { v4: uuidv4 } = require("uuid");
const { createDatabaseIfNotExists } = require("./db");
require("dotenv").config();
const jwt = require("jsonwebtoken");

const app = express();
app.use(express.json());

let pool;

// =========================
// 1️⃣ Initialize DB and tables
// =========================
const init = async () => {
    await createDatabaseIfNotExists();

    pool = new Pool({
        host: process.env.DB_HOST,
        port: process.env.DB_PORT,
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        database: process.env.DB_NAME,
    });

    // Users table
    await pool.query(`
    CREATE TABLE IF NOT EXISTS users (
      id UUID PRIMARY KEY,
      username VARCHAR(100) UNIQUE NOT NULL,
      email VARCHAR(255) UNIQUE NOT NULL,
      password TEXT NOT NULL,
      date_of_birth DATE NOT NULL,
      pronouns VARCHAR(50),
      latitude DOUBLE PRECISION,
      longitude DOUBLE PRECISION,
      fruit VARCHAR(100),
      phone_number VARCHAR(20),
      name VARCHAR(100),
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      is_private BOOLEAN DEFAULT false,
      is_deleted BOOLEAN DEFAULT false,
      delete_reason TEXT
    )
  `);

    // Optional: Friends table for relational friend management
    await pool.query(`
    CREATE TABLE IF NOT EXISTS friends (
      id UUID PRIMARY KEY,
      user_id UUID REFERENCES users(id),
      friend_id UUID REFERENCES users(id),
      status VARCHAR(20) DEFAULT 'pending', -- pending / accepted
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);

    console.log("Database initialized and tables ready");
};

// Start server after initialization
init().then(() => {
    app.listen(process.env.PORT, () => {
        console.log(`Server running on port ${process.env.PORT}`);
    });
});

// =========================
// 2️⃣ Test Route
// =========================
app.get("/hello", async (req, res) => {
    try {
        res.status(200).json({ message: "Hello, ILoveYou is live!" });
    } catch (error) {
        console.error("Hello Error:", error);
        res.status(500).json({ error: "Internal server error" });
    }
});

// =========================
// 3️⃣ Signup Route
// =========================
app.post("/signup", async (req, res) => {
    try {
        const { email, username, password, dateOfBirth, pronouns, location, name, phoneNumber } = req.body;

        // -------------------------
        // 1️⃣ Validate required fields
        // -------------------------
        const missingFields = [];
        if (!email) missingFields.push("email");
        if (!username) missingFields.push("username");
        if (!password) missingFields.push("password");
        if (!dateOfBirth) missingFields.push("dateOfBirth");
        if (!location) missingFields.push("location");

        if (missingFields.length > 0) {
            return res.status(400).json({ error: "Missing required fields", missingFields });
        }

        // -------------------------
        // 2️⃣ Validate email
        // -------------------------
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
            return res.status(400).json({ error: "Invalid email format" });
        }

        // -------------------------
        // 3️⃣ Validate password
        // -------------------------
        if (password.length < 8) {
            return res.status(400).json({ error: "Password must be at least 8 characters long" });
        }

        // -------------------------
        // 4️⃣ Validate location
        // -------------------------
        if (typeof location.latitude !== "number" || typeof location.longitude !== "number") {
            return res.status(400).json({ error: "Location must include numeric latitude and longitude" });
        }

        // -------------------------
        // 5️⃣ Check existing user
        // -------------------------
        const existingUser = await pool.query(
            "SELECT * FROM users WHERE email = $1 OR username = $2",
            [email, username]
        );
        if (existingUser.rows.length > 0) {
            return res.status(409).json({ error: "Email or username already exists" });
        }

        // -------------------------
        // 6️⃣ Assign random fruit
        // -------------------------
        const fruits = ["Apple", "Banana", "Mango", "Orange", "Strawberry", "Pineapple", "Grapes", "Watermelon", "Peach", "Cherry"];
        const randomFruit = fruits[Math.floor(Math.random() * fruits.length)];

        // -------------------------
        // 7️⃣ Hash password
        // -------------------------
        const hashedPassword = await bcrypt.hash(password, 10);
        const userId = uuidv4();

        // -------------------------
        // 8️⃣ Insert user
        // -------------------------
        const query = `
      INSERT INTO users (
        id, username, email, password, date_of_birth, pronouns,
        latitude, longitude, fruit, name, phone_number
      )
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
      RETURNING id, username, email, fruit, created_at
    `;

        const values = [
            userId, username, email, hashedPassword, dateOfBirth,
            pronouns || null, location.latitude, location.longitude,
            randomFruit, name || null, phoneNumber || null
        ];

        const result = await pool.query(query, values);
        const user = result.rows[0];

        // -------------------------
        // 9️⃣ Generate JWT
        // -------------------------
        const token = jwt.sign(
            { id: user.id, email: user.email, username: user.username },
            process.env.JWT_SECRET,
            { expiresIn: process.env.JWT_EXPIRES_IN }
        );

        // -------------------------
        // 🔟 Send response
        // -------------------------
        res.status(201).json({ message: "User created successfully", token, user });

    } catch (error) {
        console.error("Signup Error:", error);
        res.status(500).json({ error: "Internal server error" });
    }
});

// =========================
// Login Route - Minimal User Info
// =========================
app.post("/login", async (req, res) => {
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

        const token = jwt.sign(
            { id: user.id, email: user.email, username: user.username },
            process.env.JWT_SECRET,
            { expiresIn: process.env.JWT_EXPIRES_IN }
        );

        // Only return the necessary properties
        const minimalUser = {
            id: user.id,
            username: user.username,
            email: user.email,
            fruit: user.fruit,
            pronouns: user.pronouns
        };

        res.status(200).json({
            message: "Login successful",
            token,
            user: minimalUser
        });

    } catch (error) {
        console.error("Login Error:", error);
        res.status(500).json({ error: "Internal server error" });
    }
});