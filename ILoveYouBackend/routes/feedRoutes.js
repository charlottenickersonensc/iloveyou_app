const express = require("express");
const { validate: uuidValidate } = require("uuid");
const { PutObjectCommand, S3Client } = require("@aws-sdk/client-s3");
const { getSignedUrl } = require("@aws-sdk/s3-request-presigner");
const { pool } = require("../config/db");
const { authenticateToken } = require("../middleware/auth");
const { assertNoBlockedWords } = require("../lib/blockedWords");

const router = express.Router();

const REPORT_REASONS = ["spam", "harassment", "nudity", "self_harm", "other"];

async function attachFruitCommunityId(req, res, next) {
    try {
        if (req.user.fruitCommunityId) return next();
        const { rows } = await pool.query(`SELECT fruit_community_id FROM users WHERE id = $1 AND is_deleted = false`, [
            req.user.id,
        ]);
        if (!rows.length) return res.status(401).json({ error: "User not found" });
        req.user.fruitCommunityId = rows[0].fruit_community_id;
        next();
    } catch (e) {
        next(e);
    }
}

const authFruit = [authenticateToken, attachFruitCommunityId];

function parseFeedCursor(cursor) {
    if (!cursor) return null;
    try {
        const o = JSON.parse(Buffer.from(cursor, "base64url").toString("utf8"));
        if (!o.t || !o.id || !uuidValidate(o.id)) return null;
        return { createdAt: o.t, id: o.id };
    } catch {
        return null;
    }
}

function encodeFeedCursor(row) {
    return Buffer.from(JSON.stringify({ t: row.created_at, id: row.id }), "utf8").toString("base64url");
}

function parseTrendingCursor(cursor) {
    if (!cursor) return null;
    try {
        const o = JSON.parse(Buffer.from(cursor, "base64url").toString("utf8"));
        if (o.trendingScore == null || !o.createdAt || !o.id || !uuidValidate(o.id)) return null;
        return { trendingScore: o.trendingScore, createdAt: o.createdAt, id: o.id };
    } catch {
        return null;
    }
}

function encodeTrendingCursor(row) {
    return Buffer.from(
        JSON.stringify({
            trendingScore: row.trending_score,
            createdAt: row.created_at,
            id: row.id,
        }),
        "utf8"
    ).toString("base64url");
}

async function loadAuthorSnapshot(userId) {
    const { rows } = await pool.query(
        `SELECT u.username, u.name, u.profile_picture_url, u.fruit_community_id
     FROM users u WHERE u.id = $1 AND u.is_deleted = false`,
        [userId]
    );
    return rows[0] || null;
}

async function selectPostWithImages(postId) {
    const { rows } = await pool.query(
        `SELECT p.*,
        COALESCE(
          (SELECT json_agg(json_build_object('id', pi.id, 'imageUrl', pi.image_url, 'displayOrder', pi.display_order) ORDER BY pi.display_order)
           FROM post_images pi WHERE pi.post_id = p.id),
          '[]'::json
        ) AS images
      FROM posts p WHERE p.id = $1`,
        [postId]
    );
    return rows[0] || null;
}

/** Same-fruit plus visibility rules (friends-only requires accepted friendship or author). */
async function canViewerAccessPost(viewerId, viewerFruitId, post) {
    if (!post || post.fruit_community_id !== viewerFruitId) return false;
    if (post.moderation_status !== "ok" && post.author_id !== viewerId) return false;

    const vis = post.visibility;
    if (vis === "fruit" || vis === "group") return true;
    if (vis === "friends") {
        if (post.author_id === viewerId) return true;
        const { rows } = await pool.query(
            `SELECT 1 FROM friends WHERE status = 'accepted' AND (
          (user_id = $1 AND friend_id = $2) OR (user_id = $2 AND friend_id = $1)
        )`,
            [viewerId, post.author_id]
        );
        return rows.length > 0;
    }
    return true;
}

async function canViewerInteractPost(viewerId, viewerFruitId, post) {
    if (!post || post.moderation_status !== "ok") return false;
    return canViewerAccessPost(viewerId, viewerFruitId, post);
}

/** GET /v1/feed */
router.get("/feed", authFruit, async (req, res) => {
    try {
        const limit = Math.min(Math.max(parseInt(String(req.query.limit || "20"), 10) || 20, 1), 50);
        const cursor = parseFeedCursor(req.query.cursor);

        let q = `
      SELECT p.*,
        COALESCE(
          (SELECT json_agg(json_build_object('id', pi.id, 'imageUrl', pi.image_url, 'displayOrder', pi.display_order) ORDER BY pi.display_order)
           FROM post_images pi WHERE pi.post_id = p.id),
          '[]'::json
        ) AS images
      FROM posts p
      WHERE p.fruit_community_id = $1
        AND p.visibility = 'fruit'::post_visibility
        AND p.moderation_status = 'ok'::moderation_status
    `;
        const params = [req.user.fruitCommunityId];
        if (cursor) {
            q += ` AND (p.created_at, p.id) < ($2::timestamptz, $3::uuid)`;
            params.push(cursor.createdAt, cursor.id);
        }
        q += ` ORDER BY p.created_at DESC, p.id DESC LIMIT $${params.length + 1}`;
        params.push(limit + 1);

        const { rows } = await pool.query(q, params);
        const hasMore = rows.length > limit;
        const page = hasMore ? rows.slice(0, limit) : rows;
        const nextCursor = hasMore && page.length ? encodeFeedCursor(page[page.length - 1]) : null;

        res.json({ posts: page, nextCursor });
    } catch (e) {
        console.error("GET /v1/feed", e);
        res.status(500).json({ error: "Internal server error" });
    }
});

/** GET /v1/feed/trending */
router.get("/feed/trending", authFruit, async (req, res) => {
    try {
        const limit = Math.min(Math.max(parseInt(String(req.query.limit || "20"), 10) || 20, 1), 50);
        const cursor = parseTrendingCursor(req.query.cursor);

        let q = `
      SELECT p.*,
        COALESCE(
          (SELECT json_agg(json_build_object('id', pi.id, 'imageUrl', pi.image_url, 'displayOrder', pi.display_order) ORDER BY pi.display_order)
           FROM post_images pi WHERE pi.post_id = p.id),
          '[]'::json
        ) AS images
      FROM posts p
      WHERE p.fruit_community_id = $1
        AND p.visibility = 'fruit'::post_visibility
        AND p.moderation_status = 'ok'::moderation_status
        AND p.created_at >= (now() AT TIME ZONE 'utc') - interval '7 days'
    `;
        const params = [req.user.fruitCommunityId];
        if (cursor) {
            q += ` AND (p.trending_score, p.created_at, p.id) < ($2::int, $3::timestamptz, $4::uuid)`;
            params.push(cursor.trendingScore, cursor.createdAt, cursor.id);
        }
        q += ` ORDER BY p.trending_score DESC, p.created_at DESC, p.id DESC LIMIT $${params.length + 1}`;
        params.push(limit + 1);

        const { rows } = await pool.query(q, params);
        const hasMore = rows.length > limit;
        const page = hasMore ? rows.slice(0, limit) : rows;
        const nextCursor = hasMore && page.length ? encodeTrendingCursor(page[page.length - 1]) : null;

        res.json({ posts: page, nextCursor });
    } catch (e) {
        console.error("GET /v1/feed/trending", e);
        res.status(500).json({ error: "Internal server error" });
    }
});

/** POST /v1/posts */
router.post("/posts", authFruit, async (req, res) => {
    try {
        const { contentText, imageUrls, visibility, groupId } = req.body;
        if (contentText == null || typeof contentText !== "string") {
            return res.status(400).json({ error: "contentText is required" });
        }
        const text = contentText.trim();
        if (text.length < 1 || text.length > 2000) {
            return res.status(400).json({ error: "contentText must be between 1 and 2000 characters" });
        }

        const vis = (visibility || "fruit").toLowerCase();
        if (!["fruit", "friends", "group"].includes(vis)) {
            return res.status(400).json({ error: "Invalid visibility" });
        }
        if (vis === "group" && (!groupId || !uuidValidate(groupId))) {
            return res.status(400).json({ error: "groupId is required when visibility is group" });
        }

        const blocked = await assertNoBlockedWords(pool, text);
        if (!blocked.ok) {
            return res.status(400).json({ error: blocked.message });
        }

        const author = await loadAuthorSnapshot(req.user.id);
        if (!author || author.fruit_community_id !== req.user.fruitCommunityId) {
            return res.status(403).json({ error: "Invalid author context" });
        }

        const authorName = (author.name && String(author.name).trim()) || author.username;

        if (vis === "group") {
            const g = await pool.query(`SELECT id FROM groups WHERE id = $1 AND fruit_community_id = $2`, [
                groupId,
                req.user.fruitCommunityId,
            ]);
            if (!g.rows.length) return res.status(400).json({ error: "Invalid group" });
        }

        let urls = [];
        if (Array.isArray(imageUrls)) {
            urls = imageUrls.filter((u) => typeof u === "string" && u.length > 0 && u.length <= 2048).slice(0, 10);
        }

        const client = await pool.connect();
        try {
            await client.query("BEGIN");

            const insertPost = await client.query(
                `INSERT INTO posts (
            author_id, author_username, author_name, author_profile_picture_url,
            fruit_community_id, group_id, content_text, visibility
          ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8::post_visibility)
          RETURNING id`,
                [
                    req.user.id,
                    author.username,
                    authorName,
                    author.profile_picture_url || null,
                    req.user.fruitCommunityId,
                    vis === "group" ? groupId : null,
                    text,
                    vis,
                ]
            );

            const postId = insertPost.rows[0].id;
            for (let i = 0; i < urls.length; i++) {
                await client.query(`INSERT INTO post_images (post_id, image_url, display_order) VALUES ($1,$2,$3)`, [
                    postId,
                    urls[i],
                    i,
                ]);
            }

            await client.query("COMMIT");

            const post = await selectPostWithImages(postId);
            res.status(201).json({ post });
        } catch (e) {
            await client.query("ROLLBACK").catch(() => {});
            throw e;
        } finally {
            client.release();
        }
    } catch (e) {
        console.error("POST /v1/posts", e);
        res.status(500).json({ error: "Internal server error" });
    }
});

/** GET /v1/posts/:postId */
router.get("/posts/:postId", authFruit, async (req, res) => {
    try {
        const { postId } = req.params;
        if (!uuidValidate(postId)) return res.status(400).json({ error: "Invalid postId" });

        const post = await selectPostWithImages(postId);
        if (!post) return res.status(404).json({ error: "Post not found" });
        const ok = await canViewerAccessPost(req.user.id, req.user.fruitCommunityId, post);
        if (!ok) return res.status(404).json({ error: "Post not found" });

        res.json({ post });
    } catch (e) {
        console.error("GET /v1/posts/:postId", e);
        res.status(500).json({ error: "Internal server error" });
    }
});

/** DELETE /v1/posts/:postId — soft-delete (author only): moderation_status removed */
router.delete("/posts/:postId", authFruit, async (req, res) => {
    try {
        const { postId } = req.params;
        if (!uuidValidate(postId)) return res.status(400).json({ error: "Invalid postId" });

        const { rows } = await pool.query(
            `UPDATE posts SET moderation_status = 'removed'::moderation_status, updated_at = now()
       WHERE id = $1 AND author_id = $2 AND fruit_community_id = $3
       RETURNING id`,
            [postId, req.user.id, req.user.fruitCommunityId]
        );
        if (!rows.length) return res.status(404).json({ error: "Post not found or not allowed" });
        res.json({ ok: true });
    } catch (e) {
        console.error("DELETE /v1/posts/:postId", e);
        res.status(500).json({ error: "Internal server error" });
    }
});

/** POST /v1/posts/:postId/likes/toggle */
router.post("/posts/:postId/likes/toggle", authFruit, async (req, res) => {
    try {
        const { postId } = req.params;
        if (!uuidValidate(postId)) return res.status(400).json({ error: "Invalid postId" });

        const full = await selectPostWithImages(postId);
        if (!full || !(await canViewerInteractPost(req.user.id, req.user.fruitCommunityId, full))) {
            return res.status(404).json({ error: "Post not found" });
        }

        const existing = await pool.query(`SELECT 1 FROM post_likes WHERE post_id = $1 AND user_id = $2`, [
            postId,
            req.user.id,
        ]);

        if (existing.rows.length) {
            await pool.query(`DELETE FROM post_likes WHERE post_id = $1 AND user_id = $2`, [postId, req.user.id]);
        } else {
            await pool.query(`INSERT INTO post_likes (post_id, user_id) VALUES ($1, $2)`, [postId, req.user.id]);
        }

        const liked = existing.rows.length === 0;
        const counts = await pool.query(`SELECT like_count FROM posts WHERE id = $1`, [postId]);
        res.json({ liked, likeCount: counts.rows[0]?.like_count ?? 0 });
    } catch (e) {
        console.error("POST likes/toggle", e);
        res.status(500).json({ error: "Internal server error" });
    }
});

/** GET /v1/posts/:postId/comments */
router.get("/posts/:postId/comments", authFruit, async (req, res) => {
    try {
        const { postId } = req.params;
        if (!uuidValidate(postId)) return res.status(400).json({ error: "Invalid postId" });

        const post = await selectPostWithImages(postId);
        if (!post || !(await canViewerAccessPost(req.user.id, req.user.fruitCommunityId, post))) {
            return res.status(404).json({ error: "Post not found" });
        }

        const limit = Math.min(Math.max(parseInt(String(req.query.limit || "30"), 10) || 30, 1), 100);
        const offset = Math.max(parseInt(String(req.query.offset || "0"), 10) || 0, 0);

        const { rows } = await pool.query(
            `SELECT * FROM post_comments WHERE post_id = $1 ORDER BY created_at ASC, id ASC LIMIT $2 OFFSET $3`,
            [postId, limit, offset]
        );
        res.json({ comments: rows });
    } catch (e) {
        console.error("GET comments", e);
        res.status(500).json({ error: "Internal server error" });
    }
});

/** POST /v1/posts/:postId/comments */
router.post("/posts/:postId/comments", authFruit, async (req, res) => {
    try {
        const { postId } = req.params;
        if (!uuidValidate(postId)) return res.status(400).json({ error: "Invalid postId" });

        const { content } = req.body;
        if (content == null || typeof content !== "string") {
            return res.status(400).json({ error: "content is required" });
        }
        const text = content.trim();
        if (text.length < 1 || text.length > 500) {
            return res.status(400).json({ error: "content must be between 1 and 500 characters" });
        }

        const blocked = await assertNoBlockedWords(pool, text);
        if (!blocked.ok) return res.status(400).json({ error: blocked.message });

        const post = await selectPostWithImages(postId);
        if (!post || !(await canViewerInteractPost(req.user.id, req.user.fruitCommunityId, post))) {
            return res.status(404).json({ error: "Post not found" });
        }

        const author = await loadAuthorSnapshot(req.user.id);
        if (!author) return res.status(403).json({ error: "Forbidden" });
        const authorName = (author.name && String(author.name).trim()) || author.username;

        const { rows } = await pool.query(
            `INSERT INTO post_comments (
            post_id, author_id, author_username, author_name, author_profile_picture_url, content
          ) VALUES ($1,$2,$3,$4,$5,$6)
          RETURNING *`,
            [postId, req.user.id, author.username, authorName, author.profile_picture_url || null, text]
        );

        res.status(201).json({ comment: rows[0] });
    } catch (e) {
        console.error("POST comment", e);
        res.status(500).json({ error: "Internal server error" });
    }
});

/** DELETE /v1/posts/:postId/comments/:commentId */
router.delete("/posts/:postId/comments/:commentId", authFruit, async (req, res) => {
    try {
        const { postId, commentId } = req.params;
        if (!uuidValidate(postId) || !uuidValidate(commentId)) {
            return res.status(400).json({ error: "Invalid id" });
        }

        const { rows } = await pool.query(
            `DELETE FROM post_comments c
       USING posts p
       WHERE c.id = $1 AND c.post_id = $2 AND p.id = c.post_id
         AND p.fruit_community_id = $3
         AND c.author_id = $4
       RETURNING c.id`,
            [commentId, postId, req.user.fruitCommunityId, req.user.id]
        );
        if (!rows.length) return res.status(404).json({ error: "Comment not found or not allowed" });
        res.json({ ok: true });
    } catch (e) {
        console.error("DELETE comment", e);
        res.status(500).json({ error: "Internal server error" });
    }
});

/** POST /v1/posts/:postId/reports */
router.post("/posts/:postId/reports", authFruit, async (req, res) => {
    try {
        const { postId } = req.params;
        if (!uuidValidate(postId)) return res.status(400).json({ error: "Invalid postId" });

        const { reason, details } = req.body;
        if (!reason || !REPORT_REASONS.includes(String(reason).toLowerCase())) {
            return res.status(400).json({ error: "Invalid or missing reason" });
        }
        const r = String(reason).toLowerCase();
        let d = details != null ? String(details).trim() : null;
        if (r !== "other" && d) d = null;
        if (r === "other" && (!d || d.length < 1)) {
            return res.status(400).json({ error: "details required when reason is other" });
        }
        if (d && d.length > 2000) return res.status(400).json({ error: "details too long" });

        const post = await selectPostWithImages(postId);
        if (!post || !(await canViewerAccessPost(req.user.id, req.user.fruitCommunityId, post))) {
            return res.status(404).json({ error: "Post not found" });
        }

        try {
            const ins = await pool.query(
                `INSERT INTO post_reports (post_id, reporter_id, fruit_community_id, reason, details)
         VALUES ($1, $2, $3, $4::report_reason, $5)
         RETURNING id, created_at`,
                [postId, req.user.id, req.user.fruitCommunityId, r, d]
            );
            res.status(201).json({ report: ins.rows[0] });
        } catch (e) {
            if (e.code === "23505") {
                return res.status(409).json({ error: "You already reported this post today" });
            }
            throw e;
        }
    } catch (e) {
        console.error("POST report", e);
        res.status(500).json({ error: "Internal server error" });
    }
});

function s3Client() {
    if (!process.env.AWS_REGION || !process.env.AWS_S3_BUCKET_NAME) return null;
    if (!process.env.AWS_ACCESS_KEY_ID || !process.env.AWS_SECRET_ACCESS_KEY) return null;
    return new S3Client({
        region: process.env.AWS_REGION,
        credentials: {
            accessKeyId: process.env.AWS_ACCESS_KEY_ID,
            secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
        },
    });
}

/** POST /v1/posts/images/presign */
router.post("/posts/images/presign", authFruit, async (req, res) => {
    try {
        const client = s3Client();
        if (!client) {
            return res.status(503).json({ error: "S3 upload is not configured" });
        }

        const { draftId, filename } = req.body;
        if (!draftId || !uuidValidate(draftId)) {
            return res.status(400).json({ error: "draftId must be a valid UUID" });
        }
        const safeName = (filename && String(filename).replace(/[^a-zA-Z0-9._-]/g, "")) || "image.jpg";
        const key = `postImages/${req.user.fruitCommunityId}/${req.user.id}/${draftId}/${safeName}`;

        const cmd = new PutObjectCommand({
            Bucket: process.env.AWS_S3_BUCKET_NAME,
            Key: key,
            ContentType: "image/jpeg",
        });
        const uploadUrl = await getSignedUrl(client, cmd, { expiresIn: 300 });
        const publicBase = process.env.S3_PUBLIC_BASE_URL || "";
        const imageUrl = publicBase ? `${publicBase.replace(/\/$/, "")}/${key}` : null;

        res.json({
            uploadUrl,
            key,
            imageUrl,
            expiresInSeconds: 300,
        });
    } catch (e) {
        console.error("POST presign", e);
        res.status(500).json({ error: "Internal server error" });
    }
});

module.exports = router;
