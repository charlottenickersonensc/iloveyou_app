const express = require("express");
const { pool } = require("../config/db");
const { authenticateToken } = require("../middleware/auth");
const { v4: uuidv4 } = require("uuid");

const router = express.Router();

router.post("/request", authenticateToken, async (req, res) => {
    try {
        const userId = req.user.id;
        const { friendId } = req.body;

        if (!friendId) {
            return res.status(400).json({ error: "friendId is required" });
        }
        if (userId === friendId) {
            return res.status(400).json({ error: "Cannot send friend request to yourself" });
        }

        const friendCheck = await pool.query("SELECT id FROM users WHERE id = $1 AND is_deleted = false", [friendId]);
        if (friendCheck.rows.length === 0) {
            return res.status(404).json({ error: "User not found" });
        }

        const existingRel = await pool.query(
            "SELECT * FROM friends WHERE (user_id = $1 AND friend_id = $2) OR (user_id = $2 AND friend_id = $1)",
            [userId, friendId]
        );

        if (existingRel.rows.length > 0) {
            return res.status(409).json({ error: "Friendship or request already exists" });
        }

        const requestId = uuidv4();
        await pool.query(
            "INSERT INTO friends (id, user_id, friend_id, status) VALUES ($1, $2, $3, 'pending')",
            [requestId, userId, friendId]
        );

        res.status(201).json({ message: "Friend request sent successfully" });
    } catch (error) {
        console.error("Friend Request Error:", error);
        res.status(500).json({ error: "Internal server error" });
    }
});

router.post("/accept", authenticateToken, async (req, res) => {
    try {
        const userId = req.user.id;
        const { friendId } = req.body;

        if (!friendId) {
            return res.status(400).json({ error: "friendId is required" });
        }

        const result = await pool.query(
            "UPDATE friends SET status = 'accepted' WHERE user_id = $1 AND friend_id = $2 AND status = 'pending' RETURNING *",
            [friendId, userId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: "Friend request not found or already processed" });
        }

        res.status(200).json({ message: "Friend request accepted" });
    } catch (error) {
        console.error("Accept Friend Request Error:", error);
        res.status(500).json({ error: "Internal server error" });
    }
});

router.post("/reject", authenticateToken, async (req, res) => {
    try {
        const userId = req.user.id;
        const { friendId } = req.body;

        if (!friendId) {
            return res.status(400).json({ error: "friendId is required" });
        }

        const result = await pool.query(
            "DELETE FROM friends WHERE (user_id = $1 AND friend_id = $2) OR (user_id = $2 AND friend_id = $1) RETURNING *",
            [userId, friendId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: "Friend relationship not found" });
        }

        res.status(200).json({ message: "Friend request rejected / Friend removed" });
    } catch (error) {
        console.error("Reject/Remove Friend Error:", error);
        res.status(500).json({ error: "Internal server error" });
    }
});

router.get("/", authenticateToken, async (req, res) => {
    try {
        const userId = req.user.id;

        const query = `
            SELECT u.id, u.username, u.name, u.fruit, u.pronouns
            FROM users u
            JOIN friends f ON (u.id = f.user_id OR u.id = f.friend_id)
            WHERE (f.user_id = $1 OR f.friend_id = $1)
              AND u.id != $1
              AND f.status = 'accepted'
              AND u.is_deleted = false
        `;

        const result = await pool.query(query, [userId]);
        res.status(200).json({ friends: result.rows });
    } catch (error) {
        console.error("Get Friends Error:", error);
        res.status(500).json({ error: "Internal server error" });
    }
});

router.get("/requests", authenticateToken, async (req, res) => {
    try {
        const userId = req.user.id;

        const query = `
            SELECT u.id, u.username, u.name, u.fruit, f.created_at
            FROM users u
            JOIN friends f ON u.id = f.user_id
            WHERE f.friend_id = $1
              AND f.status = 'pending'
              AND u.is_deleted = false
        `;

        const result = await pool.query(query, [userId]);
        res.status(200).json({ pendingRequests: result.rows });
    } catch (error) {
        console.error("Get Pending Requests Error:", error);
        res.status(500).json({ error: "Internal server error" });
    }
});

module.exports = router;
