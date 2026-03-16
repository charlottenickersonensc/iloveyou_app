const express = require("express");
require("dotenv").config();

const { createDatabaseIfNotExists, initTables } = require("./config/db");

const authRoutes = require("./routes/authRoutes");
const userRoutes = require("./routes/userRoutes");
const friendRoutes = require("./routes/friendRoutes");

const app = express();
app.use(express.json());

const init = async () => {
    await createDatabaseIfNotExists();
    await initTables();
    console.log("Database initialized and tables ready");
};

init().then(() => {
    app.listen(process.env.PORT, () => {
        console.log(`Server running on port ${process.env.PORT}`);
    });
}).catch(err => {
    console.error("Failed to initialize database:", err);
});

// =========================
// Test Route
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
// API Routes
// =========================
app.use("/", authRoutes);
app.use("/account", userRoutes);
app.use("/friends", friendRoutes);