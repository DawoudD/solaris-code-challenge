const express = require("express");
const { getPool } = require("../db");
const { tableExists, getColumns } = require("../schema");

const router = express.Router();

// Generic CRUD over any table — the API doesn't hardcode a schema, since
// what data it stores isn't known ahead of time. Every table is assumed to
// have an "id" primary key column, which is the one schema convention this
// code relies on.

async function requireTable(req, res, next) {
  const pool = await getPool();
  const { table } = req.params;

  const exists = await tableExists(pool, table);
  if (!exists) {
    return res.status(404).json({ error: `Table "${table}" not found` });
  }

  req.pool = pool;
  next();
}

router.get("/:table", requireTable, async (req, res) => {
  const { table } = req.params;
  const result = await req.pool.query(`SELECT * FROM "${table}"`);
  res.json(result.rows);
});

router.get("/:table/:id", requireTable, async (req, res) => {
  const { table, id } = req.params;
  const result = await req.pool.query(`SELECT * FROM "${table}" WHERE id = $1`, [id]);

  if (result.rowCount === 0) {
    return res.status(404).json({ error: "Not found" });
  }

  res.json(result.rows[0]);
});

router.post("/:table", requireTable, async (req, res) => {
  const { table } = req.params;
  const columns = await getColumns(req.pool, table);
  const fields = Object.keys(req.body).filter((key) => columns.includes(key));

  if (fields.length === 0) {
    return res.status(400).json({ error: "No valid columns in request body" });
  }

  const columnList = fields.map((field) => `"${field}"`).join(", ");
  const placeholders = fields.map((_, index) => `$${index + 1}`).join(", ");
  const values = fields.map((field) => req.body[field]);

  const result = await req.pool.query(
    `INSERT INTO "${table}" (${columnList}) VALUES (${placeholders}) RETURNING *`,
    values
  );

  res.status(201).json(result.rows[0]);
});

router.put("/:table/:id", requireTable, async (req, res) => {
  const { table, id } = req.params;
  const columns = await getColumns(req.pool, table);
  const fields = Object.keys(req.body).filter((key) => columns.includes(key));

  if (fields.length === 0) {
    return res.status(400).json({ error: "No valid columns in request body" });
  }

  const assignments = fields.map((field, index) => `"${field}" = $${index + 1}`).join(", ");
  const values = fields.map((field) => req.body[field]);

  const result = await req.pool.query(
    `UPDATE "${table}" SET ${assignments} WHERE id = $${fields.length + 1} RETURNING *`,
    [...values, id]
  );

  if (result.rowCount === 0) {
    return res.status(404).json({ error: "Not found" });
  }

  res.json(result.rows[0]);
});

router.delete("/:table/:id", requireTable, async (req, res) => {
  const { table, id } = req.params;
  const result = await req.pool.query(`DELETE FROM "${table}" WHERE id = $1 RETURNING *`, [id]);

  if (result.rowCount === 0) {
    return res.status(404).json({ error: "Not found" });
  }

  res.status(204).send();
});

module.exports = router;
