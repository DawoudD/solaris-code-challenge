const { Pool } = require("pg");
const {
  SecretsManagerClient,
  GetSecretValueCommand,
} = require("@aws-sdk/client-secrets-manager");

// Reused across warm Lambda invocations instead of reconnecting per request.
let pool;

// The RDS master password isn't available as a plain env var — it lives in
// Secrets Manager because the database was provisioned with
// manage_master_user_password = true. This fetches it at cold start.
async function getPassword() {
  const client = new SecretsManagerClient({});
  const response = await client.send(
    new GetSecretValueCommand({ SecretId: process.env.DB_SECRET_ARN })
  );
  const secret = JSON.parse(response.SecretString);
  return secret.password;
}

async function getPool() {
  if (pool) {
    return pool;
  }

  // RDS's "endpoint" attribute is formatted as "host:port".
  const [host, port] = process.env.DB_HOST.split(":");
  const password = await getPassword();

  pool = new Pool({
    host,
    port: port ? Number(port) : undefined,
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password,
    // RDS Postgres enforces SSL (rds.force_ssl) by default — connecting
    // without this raises "no pg_hba.conf entry ... no encryption".
    ssl: { rejectUnauthorized: false },
  });

  return pool;
}

module.exports = { getPool };
