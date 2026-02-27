const express = require("express");
const { Pool } = require("pg");
const bcrypt = require("bcrypt");
const { v4: uuidv4 } = require("uuid");
const { createDatabaseIfNotExists } = require("./db");
require("dotenv").config();

const app = express();
app.use(express.json());

let pool;

// Initialize DB and table
const init = async () => {
    await createDatabaseIfNotExists();

    pool = new Pool({
        host: process.env.DB_HOST,
        port: process.env.DB_PORT,
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        database: process.env.DB_NAME,
    });

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
      posts_collection_id VARCHAR(255),
      activities_collection_id VARCHAR(255),
      invited_events_collection_id VARCHAR(255),
      notifications_collection_id VARCHAR(255),
      friend_ids TEXT[],
      friend_requests_collection_id VARCHAR(255),
      groups_collection_id VARCHAR(255),
      chats_collection_id VARCHAR(255),
      is_private BOOLEAN DEFAULT false,
      is_deleted BOOLEAN DEFAULT false,
      delete_reason TEXT
    )
  `);

    console.log("Users table ready");
};


init().then(() => {
    app.listen(process.env.PORT, () => {
        console.log(`Server running on port ${process.env.PORT}`);
    });
});

const jwt = require("jsonwebtoken");

app.post("/signup", async (req, res) => {
    try {
        const { email, username, password, dateOfBirth, pronouns, location } = req.body;

        // =========================
        // 1️⃣ Field Validation
        // =========================
        const missingFields = [];

        if (!email) missingFields.push("email");
        if (!username) missingFields.push("username");
        if (!password) missingFields.push("password");
        if (!dateOfBirth) missingFields.push("dateOfBirth");
        if (!location) missingFields.push("location");

        if (missingFields.length > 0) {
            return res.status(400).json({
                error: "Missing required fields",
                missingFields
            });
        }

        // =========================
        // 2️⃣ Email Validation
        // =========================
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
            return res.status(400).json({
                error: "Invalid email format"
            });
        }

        // =========================
        // 3️⃣ Password Validation
        // =========================
        if (password.length < 8) {
            return res.status(400).json({
                error: "Password must be at least 8 characters long"
            });
        }

        // =========================
        // 4️⃣ Location Validation
        // =========================
        if (
            typeof location.latitude !== "number" ||
            typeof location.longitude !== "number"
        ) {
            return res.status(400).json({
                error: "Location must include numeric latitude and longitude"
            });
        }

        // =========================
        // 5️⃣ Check Existing User
        // =========================
        const existingUser = await pool.query(
            "SELECT * FROM users WHERE email = $1 OR username = $2",
            [email, username]
        );

        if (existingUser.rows.length > 0) {
            return res.status(409).json({
                error: "Email or username already exists"
            });
        }

        // =========================
        // 6️⃣ Generate Random Fruit
        // =========================
        const fruits = [
            "Apple",
            "Banana",
            "Mango",
            "Orange",
            "Strawberry",
            "Pineapple",
            "Grapes",
            "Watermelon",
            "Peach",
            "Cherry"
        ];

        const randomFruit = fruits[Math.floor(Math.random() * fruits.length)];

        // =========================
        // 7️⃣ Hash Password
        // =========================
        const hashedPassword = await bcrypt.hash(password, 10);
        const userId = uuidv4();

        // =========================
        // 8️⃣ Insert User
        // =========================
        const query = `
      INSERT INTO users (
        id,
        username,
        email,
        password,
        date_of_birth,
        pronouns,
        latitude,
        longitude,
        fruit
      )
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
      RETURNING id, username, email, fruit, created_at
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
            randomFruit
        ];

        const result = await pool.query(query, values);
        const user = result.rows[0];

        // =========================
        // 9️⃣ Generate JWT Token
        // =========================
        const token = jwt.sign(
            {
                id: user.id,
                email: user.email,
                username: user.username
            },
            process.env.JWT_SECRET,
            { expiresIn: process.env.JWT_EXPIRES_IN }
        );

        // =========================
        // 🔟 Response
        // =========================
        res.status(201).json({
            message: "User created successfully",
            token,
            user
        });

    } catch (error) {
        console.error("Signup Error:", error);

        res.status(500).json({
            error: "Internal server error"
        });
    }
});