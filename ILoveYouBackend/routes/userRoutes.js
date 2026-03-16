const express = require("express");
const { pool } = require("../config/db");
const { authenticateToken } = require("../middleware/auth");
const upload = require("../middleware/upload");

const router = express.Router();

router.patch("/privacy", authenticateToken, async (req, res) => {
    try {
        const userId = req.user.id;
        const { isPrivate } = req.body;

        if (typeof isPrivate !== "boolean") {
            return res.status(400).json({
                error: "isPrivate must be a boolean value"
            });
        }

        const result = await pool.query(
            `UPDATE users
             SET is_private = $1,
                 updated_at = CURRENT_TIMESTAMP
             WHERE id = $2
             RETURNING id, username, is_private`,
            [isPrivate, userId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                error: "User not found"
            });
        }

        res.status(200).json({
            message: `Account is now ${isPrivate ? "private" : "public"}`,
            user: result.rows[0]
        });

    } catch (error) {
        console.error("Privacy Update Error:", error);
        res.status(500).json({ error: "Internal server error" });
    }
});

router.patch("/interests", authenticateToken, async (req, res) => {
    try {
        const userId = req.user.id;
        const { interests } = req.body;

        if (!Array.isArray(interests)) {
            return res.status(400).json({
                error: "interests must be an array of strings"
            });
        }

        const result = await pool.query(
            `UPDATE users
             SET interests = $1,
                 updated_at = CURRENT_TIMESTAMP
             WHERE id = $2
             RETURNING id, username, interests`,
            [interests, userId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                error: "User not found"
            });
        }

        res.status(200).json({
            message: "Interests updated successfully",
            user: result.rows[0]
        });

    } catch (error) {
        console.error("Interests Update Error:", error);
        res.status(500).json({ error: "Internal server error" });
    }
});

// =========================
// Profile Picture Upload
// =========================
router.post("/profile-picture", authenticateToken, upload.single("profileImage"), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: "No image file uploaded" });
        }

        const userId = req.user.id;
        const imageUrl = req.file.location;

        const result = await pool.query(
            `UPDATE users
             SET profile_picture_url = $1,
                 updated_at = CURRENT_TIMESTAMP
             WHERE id = $2
             RETURNING id, username, profile_picture_url`,
            [imageUrl, userId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: "User not found" });
        }

        res.status(200).json({
            message: "Profile picture updated successfully",
            user: result.rows[0],
            imageUrl: imageUrl
        });

    } catch (error) {
        console.error("Profile Picture Upload Error:", error);
        res.status(500).json({ error: "Internal server error" });
    }
});

module.exports = router;
