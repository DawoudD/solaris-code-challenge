// SQL parameterization ($1, $2, ...) only covers values, not identifiers —
// a table/column name can't be safely parameterized the normal way. These
// functions check requested identifiers against the database's own
// information_schema before they're ever used to build a query, so only
// identifiers that genuinely exist in the database get interpolated.

async function tableExists(pool, table) {
  const result = await pool.query(
    `SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = $1`,
    [table]
  );
  return result.rowCount > 0;
}

async function getColumns(pool, table) {
  const result = await pool.query(
    `SELECT column_name FROM information_schema.columns WHERE table_schema = 'public' AND table_name = $1`,
    [table]
  );
  return result.rows.map((row) => row.column_name);
}

module.exports = { tableExists, getColumns };
