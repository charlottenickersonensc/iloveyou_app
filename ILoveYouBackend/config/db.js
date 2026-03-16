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
        database: "postgres", // connect to default db first
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

const initTables = async () => {
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

    // Friends table
    await pool.query(`
    CREATE TABLE IF NOT EXISTS friends (
      id UUID PRIMARY KEY,
      user_id UUID REFERENCES users(id),
      friend_id UUID REFERENCES users(id),
      status VARCHAR(20) DEFAULT 'pending',
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);
};

module.exports = { pool, createDatabaseIfNotExists, initTables };
