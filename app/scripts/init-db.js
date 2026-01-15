// Database initialization script for Docker
// Runs Drizzle migrations on startup

const Database = require('better-sqlite3');
const fs = require('fs');
const path = require('path');

const dbPath = process.env.DATABASE_URL || '/app/data/sqlite.db';
const migrationsDir = path.join(__dirname, '..', 'drizzle');

console.log(`Initializing database at: ${dbPath}`);

// Ensure database directory exists
const dbDir = path.dirname(dbPath);
if (!fs.existsSync(dbDir)) {
  fs.mkdirSync(dbDir, { recursive: true });
}

// Open database
const db = new Database(dbPath);

// Create migrations table if not exists
db.exec(`
  CREATE TABLE IF NOT EXISTS __drizzle_migrations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    hash TEXT NOT NULL,
    created_at INTEGER NOT NULL
  );
`);

// Get applied migrations
const applied = db.prepare('SELECT hash FROM __drizzle_migrations').all().map(r => r.hash);
console.log(`Applied migrations: ${applied.length}`);

// Read and apply pending migrations
const migrationFiles = fs.readdirSync(migrationsDir)
  .filter(f => f.endsWith('.sql'))
  .sort();

for (const file of migrationFiles) {
  const hash = file.replace('.sql', '');

  if (applied.includes(hash)) {
    console.log(`Skipping already applied: ${file}`);
    continue;
  }

  console.log(`Applying migration: ${file}`);
  const sql = fs.readFileSync(path.join(migrationsDir, file), 'utf-8');

  // Split by statement-breakpoint and execute each statement
  const statements = sql.split('--> statement-breakpoint');

  for (const statement of statements) {
    const trimmed = statement.trim();
    if (trimmed) {
      try {
        db.exec(trimmed);
      } catch (err) {
        // Ignore "table already exists" errors for idempotency
        if (!err.message.includes('already exists')) {
          console.error(`Error executing: ${trimmed.substring(0, 100)}...`);
          throw err;
        }
      }
    }
  }

  // Record migration
  db.prepare('INSERT INTO __drizzle_migrations (hash, created_at) VALUES (?, ?)').run(hash, Date.now());
  console.log(`Applied: ${file}`);
}

db.close();
console.log('Database initialization complete');
