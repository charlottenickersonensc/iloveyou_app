const { Client } = require("pg");
require("dotenv").config();

const createDatabaseIfNotExists = async () => {
    const client = new Client({
        host: process.env.DB_HOST,
        port: process.env.DB_PORT,
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        database: "postgres", // connect to default db first
    });

    await client.connect();

    const dbCheckQuery = `
    SELECT 1 FROM pg_database WHERE datname = '${process.env.DB_NAME}'
  `;

    const res = await client.query(dbCheckQuery);

    if (res.rowCount === 0) {
        await client.query(`CREATE DATABASE ${process.env.DB_NAME}`);
        console.log("Database created");
    } else {
        console.log("Database already exists");
    }

    await client.end();
};

module.exports = { createDatabaseIfNotExists };