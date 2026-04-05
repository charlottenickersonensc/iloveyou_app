const { Client, Pool } = require("pg");
require("dotenv").config();

const pool = new Pool({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
});

const createDatabaseIfNotExists = async () => {
    const client = new Client({
        host: process.env.DB_HOST,
        port: process.env.DB_PORT,
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        database: "postgres",
    });

    await client.connect();

    const dbCheckQuery = `SELECT 1 FROM pg_database WHERE datname = '${process.env.DB_NAME}'`;
    const res = await client.query(dbCheckQuery);

    if (res.rowCount === 0) {
        await client.query(`CREATE DATABASE ${process.env.DB_NAME}`);
        console.log("Database created");
    } else {
        console.log("Database already exists");
    }

    await client.end();
};

async function ensurePgcrypto() {
    await pool.query(`CREATE EXTENSION IF NOT EXISTS pgcrypto`);
}

/** feed_schema.md — Prerequisites: fruit_communities */
async function ensureFruitCommunities() {
    await pool.query(`
    CREATE TABLE IF NOT EXISTS fruit_communities (
      id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      code       TEXT NOT NULL UNIQUE,
      name       TEXT NOT NULL,
      created_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )
  `);

    const fruits = [
        ["apple", "Apple"],
        ["banana", "Banana"],
        ["mango", "Mango"],
        ["orange", "Orange"],
        ["strawberry", "Strawberry"],
        ["pineapple", "Pineapple"],
        ["grapes", "Grapes"],
        ["watermelon", "Watermelon"],
        ["peach", "Peach"],
        ["cherry", "Cherry"],
        ["blueberry", "Blueberry"],
        ["raspberry", "Raspberry"],
    ];
    for (const [code, name] of fruits) {
        await pool.query(
            `INSERT INTO fruit_communities (code, name) VALUES ($1, $2)
       ON CONFLICT (code) DO NOTHING`,
            [code, name]
        );
    }
}

/** Legacy users table + migration to fruit_community_id (feed_schema users) */
async function ensureUsersTable() {
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
      interests TEXT[],
      phone_number VARCHAR(20),
      name VARCHAR(100),
      profile_picture_url VARCHAR(255),
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      is_private BOOLEAN DEFAULT false,
      is_deleted BOOLEAN DEFAULT false,
      delete_reason TEXT
    )
  `);

    const { rows } = await pool.query(`
    SELECT column_name FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'fruit_community_id'
  `);
    if (rows.length > 0) return;

    await pool.query(`
    ALTER TABLE users
    ADD COLUMN fruit_community_id UUID REFERENCES fruit_communities(id)
  `);

    await pool.query(`
    UPDATE users u
    SET fruit_community_id = fc.id
    FROM fruit_communities fc
    WHERE u.fruit_community_id IS NULL
      AND u.fruit IS NOT NULL
      AND (
        LOWER(TRIM(u.fruit)) = LOWER(fc.name)
        OR LOWER(TRIM(u.fruit)) = fc.code
      )
  `);

    await pool.query(`
    UPDATE users
    SET fruit_community_id = (SELECT id FROM fruit_communities WHERE code = 'apple' LIMIT 1)
    WHERE fruit_community_id IS NULL
  `);

    await pool.query(`
    ALTER TABLE users ALTER COLUMN fruit_community_id SET NOT NULL
  `);

    await pool.query(`ALTER TABLE users DROP COLUMN IF EXISTS fruit`);
}

async function ensureFriendsTable() {
    await pool.query(`
    CREATE TABLE IF NOT EXISTS friends (
      id UUID PRIMARY KEY,
      user_id UUID REFERENCES users(id),
      friend_id UUID REFERENCES users(id),
      status VARCHAR(20) DEFAULT 'pending',
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);
}

/** Minimal groups table so posts.group_id FK exists (feed_schema) */
async function ensureGroupsTable() {
    await pool.query(`
    CREATE TABLE IF NOT EXISTS groups (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      fruit_community_id UUID NOT NULL REFERENCES fruit_communities(id),
      name TEXT NOT NULL DEFAULT '',
      created_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )
  `);
}

/** feed_schema.md — Enums */
async function ensureFeedEnums() {
    await pool.query(`
    DO $$ BEGIN
      CREATE TYPE post_visibility AS ENUM ('fruit', 'friends', 'group');
    EXCEPTION
      WHEN duplicate_object THEN NULL;
    END $$
  `);
    await pool.query(`
    DO $$ BEGIN
      CREATE TYPE moderation_status AS ENUM ('ok', 'flagged', 'removed');
    EXCEPTION
      WHEN duplicate_object THEN NULL;
    END $$
  `);
    await pool.query(`
    DO $$ BEGIN
      CREATE TYPE report_reason AS ENUM ('spam', 'harassment', 'nudity', 'self_harm', 'other');
    EXCEPTION
      WHEN duplicate_object THEN NULL;
    END $$
  `);
}

/** feed_schema.md — Tables */
async function ensureFeedTables() {
    await pool.query(`
    CREATE TABLE IF NOT EXISTS posts (
      id                         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      author_id                  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      author_username            TEXT NOT NULL,
      author_name                TEXT NOT NULL,
      author_profile_picture_url TEXT NULL,
      fruit_community_id         UUID NOT NULL REFERENCES fruit_communities(id),
      group_id                   UUID NULL REFERENCES groups(id) ON DELETE SET NULL,
      content_text               TEXT NOT NULL CHECK (char_length(content_text) BETWEEN 1 AND 2000),
      visibility                 post_visibility NOT NULL DEFAULT 'fruit',
      location_text              TEXT NULL,
      is_anonymous               BOOLEAN NOT NULL DEFAULT FALSE,
      like_count                 INTEGER NOT NULL DEFAULT 0 CHECK (like_count >= 0),
      comment_count              INTEGER NOT NULL DEFAULT 0 CHECK (comment_count >= 0),
      report_count               INTEGER NOT NULL DEFAULT 0 CHECK (report_count >= 0),
      trending_score             INTEGER NOT NULL DEFAULT 0 CHECK (trending_score >= 0),
      moderation_status          moderation_status NOT NULL DEFAULT 'ok',
      created_at                 TIMESTAMPTZ NOT NULL DEFAULT now(),
      updated_at                 TIMESTAMPTZ NOT NULL DEFAULT now()
    )
  `);

    await pool.query(`
    CREATE TABLE IF NOT EXISTS post_images (
      id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      post_id       UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
      image_url     TEXT NOT NULL,
      display_order SMALLINT NOT NULL DEFAULT 0,
      created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
      UNIQUE (post_id, display_order)
    )
  `);

    await pool.query(`
    CREATE TABLE IF NOT EXISTS post_likes (
      post_id    UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
      user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
      PRIMARY KEY (post_id, user_id)
    )
  `);

    await pool.query(`
    CREATE TABLE IF NOT EXISTS post_comments (
      id                         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      post_id                    UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
      author_id                  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      author_username            TEXT NOT NULL,
      author_name                TEXT NOT NULL,
      author_profile_picture_url TEXT NULL,
      content                    TEXT NOT NULL CHECK (char_length(content) BETWEEN 1 AND 500),
      created_at                 TIMESTAMPTZ NOT NULL DEFAULT now(),
      updated_at                 TIMESTAMPTZ NOT NULL DEFAULT now()
    )
  `);

    await pool.query(`
    CREATE TABLE IF NOT EXISTS post_reports (
      id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      post_id            UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
      reporter_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      fruit_community_id UUID NOT NULL REFERENCES fruit_communities(id),
      reason             report_reason NOT NULL,
      details            TEXT NULL,
      created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
      CHECK (reason = 'other' OR details IS NULL)
    )
  `);

    await pool.query(`
    CREATE UNIQUE INDEX IF NOT EXISTS idx_post_reports_one_per_day
      ON post_reports (post_id, reporter_id, ((created_at AT TIME ZONE 'UTC')::date))
  `);

    await pool.query(`
    CREATE TABLE IF NOT EXISTS blocked_words (
      id       SERIAL PRIMARY KEY,
      word     TEXT NOT NULL UNIQUE,
      added_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )
  `);
}

/** feed_schema.md — Indexes */
async function ensureFeedIndexes() {
    await pool.query(`
    CREATE INDEX IF NOT EXISTS idx_posts_fruit_vis_created
      ON posts(fruit_community_id, visibility, created_at DESC)
      WHERE moderation_status = 'ok'
  `);
    await pool.query(`
    CREATE INDEX IF NOT EXISTS idx_posts_fruit_trending
      ON posts(fruit_community_id, trending_score DESC, created_at DESC)
      WHERE moderation_status = 'ok'
  `);
    await pool.query(`
    CREATE INDEX IF NOT EXISTS idx_posts_author_created
      ON posts(author_id, created_at DESC)
  `);
    await pool.query(`
    CREATE INDEX IF NOT EXISTS idx_comments_post_created
      ON post_comments(post_id, created_at ASC)
  `);
    await pool.query(`
    CREATE INDEX IF NOT EXISTS idx_likes_user
      ON post_likes(user_id, post_id)
  `);
    await pool.query(`
    CREATE INDEX IF NOT EXISTS idx_reports_reporter
      ON post_reports(reporter_id, created_at DESC)
  `);
}

/** feed_schema.md — Triggers */
async function ensureFeedTriggers() {
    await pool.query(`
    CREATE OR REPLACE FUNCTION set_updated_at() RETURNS TRIGGER AS $$
    BEGIN NEW.updated_at = now(); RETURN NEW; END;
    $$ LANGUAGE plpgsql
  `);

    await pool.query(`DROP TRIGGER IF EXISTS trg_posts_updated_at ON posts`);
    await pool.query(`
    CREATE TRIGGER trg_posts_updated_at
    BEFORE UPDATE ON posts FOR EACH ROW EXECUTE PROCEDURE set_updated_at()
  `);

    await pool.query(`DROP TRIGGER IF EXISTS trg_comments_updated_at ON post_comments`);
    await pool.query(`
    CREATE TRIGGER trg_comments_updated_at
    BEFORE UPDATE ON post_comments FOR EACH ROW EXECUTE PROCEDURE set_updated_at()
  `);

    await pool.query(`
    CREATE OR REPLACE FUNCTION trg_post_likes_counter() RETURNS TRIGGER AS $$
    BEGIN
      IF TG_OP = 'INSERT' THEN
        UPDATE posts SET
          like_count     = like_count + 1,
          trending_score = (like_count + 1) + (comment_count * 3),
          updated_at     = now()
        WHERE id = NEW.post_id;
      ELSIF TG_OP = 'DELETE' THEN
        UPDATE posts SET
          like_count     = GREATEST(like_count - 1, 0),
          trending_score = GREATEST(like_count - 1, 0) + (comment_count * 3),
          updated_at     = now()
        WHERE id = OLD.post_id;
      END IF;
      RETURN NULL;
    END;
    $$ LANGUAGE plpgsql
  `);

    await pool.query(`DROP TRIGGER IF EXISTS trg_post_likes ON post_likes`);
    await pool.query(`
    CREATE TRIGGER trg_post_likes
    AFTER INSERT OR DELETE ON post_likes
    FOR EACH ROW EXECUTE PROCEDURE trg_post_likes_counter()
  `);

    await pool.query(`
    CREATE OR REPLACE FUNCTION trg_post_comments_counter() RETURNS TRIGGER AS $$
    BEGIN
      IF TG_OP = 'INSERT' THEN
        UPDATE posts SET
          comment_count  = comment_count + 1,
          trending_score = like_count + ((comment_count + 1) * 3),
          updated_at     = now()
        WHERE id = NEW.post_id;
      ELSIF TG_OP = 'DELETE' THEN
        UPDATE posts SET
          comment_count  = GREATEST(comment_count - 1, 0),
          trending_score = like_count + (GREATEST(comment_count - 1, 0) * 3),
          updated_at     = now()
        WHERE id = OLD.post_id;
      END IF;
      RETURN NULL;
    END;
    $$ LANGUAGE plpgsql
  `);

    await pool.query(`DROP TRIGGER IF EXISTS trg_post_comments ON post_comments`);
    await pool.query(`
    CREATE TRIGGER trg_post_comments
    AFTER INSERT OR DELETE ON post_comments
    FOR EACH ROW EXECUTE PROCEDURE trg_post_comments_counter()
  `);

    await pool.query(`
    CREATE OR REPLACE FUNCTION trg_post_reports_counter() RETURNS TRIGGER AS $$
    BEGIN
      IF TG_OP = 'INSERT' THEN
        UPDATE posts SET report_count = report_count + 1, updated_at = now() WHERE id = NEW.post_id;
      ELSIF TG_OP = 'DELETE' THEN
        UPDATE posts SET report_count = GREATEST(report_count - 1, 0), updated_at = now() WHERE id = OLD.post_id;
      END IF;
      RETURN NULL;
    END;
    $$ LANGUAGE plpgsql
  `);

    await pool.query(`DROP TRIGGER IF EXISTS trg_post_reports ON post_reports`);
    await pool.query(`
    CREATE TRIGGER trg_post_reports
    AFTER INSERT OR DELETE ON post_reports
    FOR EACH ROW EXECUTE PROCEDURE trg_post_reports_counter()
  `);
}

async function seedBlockedWords() {
    const seeds = ["blockedtestword"];
    for (const word of seeds) {
        await pool.query(`INSERT INTO blocked_words (word) VALUES ($1) ON CONFLICT (word) DO NOTHING`, [word]);
    }
}

const initTables = async () => {
    await ensurePgcrypto();
    await ensureFruitCommunities();
    await ensureUsersTable();
    await ensureFriendsTable();
    await ensureGroupsTable();
    await ensureFeedEnums();
    await ensureFeedTables();
    await ensureFeedIndexes();
    await ensureFeedTriggers();
    await seedBlockedWords();
};

module.exports = { pool, createDatabaseIfNotExists, initTables };
