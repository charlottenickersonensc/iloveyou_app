/**
 * Shared normalization for blocked-word checks (lowercase, strip punctuation).
 * @param {string} text
 * @returns {string}
 */
function normalizeForBlockedWordScan(text) {
    if (!text || typeof text !== "string") return "";
    return text.toLowerCase().replace(/[^a-z0-9]+/g, "");
}

/**
 * @param {import("pg").Pool} pool
 * @param {string} text
 * @returns {Promise<{ ok: true } | { ok: false, message: string }>}
 */
async function assertNoBlockedWords(pool, text) {
    const { rows } = await pool.query(`SELECT word FROM blocked_words`);
    const folded = normalizeForBlockedWordScan(text);
    for (const { word } of rows) {
        if (!word) continue;
        const w = word.toLowerCase().replace(/[^a-z0-9]+/g, "");
        if (w.length === 0) continue;
        if (folded.includes(w)) {
            return { ok: false, message: "This content is not allowed." };
        }
    }
    return { ok: true };
}

module.exports = { normalizeForBlockedWordScan, assertNoBlockedWords };
