const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs');

const dbPath = process.env.DATABASE_PATH || './data/syncn.db';

// Ensure data directory exists
const dataDir = path.dirname(dbPath);
if (!fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir, { recursive: true });
}

const db = new sqlite3.Database(dbPath);

const initializeDatabase = () => {
  return new Promise((resolve, reject) => {
    db.serialize(() => {
      // Users table
      db.run(`
        CREATE TABLE IF NOT EXISTS users (
          id TEXT PRIMARY KEY,
          email TEXT UNIQUE NOT NULL,
          password_hash TEXT NOT NULL,
          name TEXT NOT NULL,
          is_email_verified BOOLEAN DEFAULT 0,
          is_account_active BOOLEAN DEFAULT 1,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          last_login_at DATETIME
        )
      `);

      // User profiles table
      db.run(`
        CREATE TABLE IF NOT EXISTS user_profiles (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          birth_date DATE,
          cycle_length INTEGER,
          last_period_start DATE,
          average_period_length INTEGER,
          fitness_level TEXT,
          goals TEXT,
          cycle_type TEXT,
          cycle_flow TEXT,
          has_recurring_symptoms BOOLEAN,
          last_symptoms_start DATE,
          average_symptom_days INTEGER,
          has_history_of_eating_disorder BOOLEAN DEFAULT 0,
          current_symptoms TEXT,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      `);

      // User sessions table
      db.run(`
        CREATE TABLE IF NOT EXISTS user_sessions (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          token TEXT UNIQUE NOT NULL,
          refresh_token TEXT UNIQUE NOT NULL,
          device_info TEXT,
          ip_address TEXT,
          expires_at DATETIME NOT NULL,
          refresh_expires_at DATETIME NOT NULL,
          is_active BOOLEAN DEFAULT 1,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      `);

      // Password reset tokens table
      db.run(`
        CREATE TABLE IF NOT EXISTS password_reset_tokens (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          token TEXT UNIQUE NOT NULL,
          expires_at DATETIME NOT NULL,
          is_used BOOLEAN DEFAULT 0,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      `);

      // Email verification tokens table
      db.run(`
        CREATE TABLE IF NOT EXISTS email_verification_tokens (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          token TEXT UNIQUE NOT NULL,
          expires_at DATETIME NOT NULL,
          is_used BOOLEAN DEFAULT 0,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      `);

      // User data sync table
      db.run(`
        CREATE TABLE IF NOT EXISTS user_data_sync (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          data_type TEXT NOT NULL,
          data_json TEXT NOT NULL,
          last_synced_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      `);

      // Create indexes for better performance
      db.run(`CREATE INDEX IF NOT EXISTS idx_users_email ON users (email)`);
      db.run(`CREATE INDEX IF NOT EXISTS idx_users_active ON users (is_account_active)`);
      db.run(`CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON user_sessions (user_id)`);
      db.run(`CREATE INDEX IF NOT EXISTS idx_sessions_token ON user_sessions (token)`);
      db.run(`CREATE INDEX IF NOT EXISTS idx_sessions_active ON user_sessions (is_active)`);
      db.run(`CREATE INDEX IF NOT EXISTS idx_sessions_expires ON user_sessions (expires_at)`);
      db.run(`CREATE INDEX IF NOT EXISTS idx_reset_tokens_user_id ON password_reset_tokens (user_id)`);
      db.run(`CREATE INDEX IF NOT EXISTS idx_reset_tokens_token ON password_reset_tokens (token)`);
      db.run(`CREATE INDEX IF NOT EXISTS idx_verification_tokens_user_id ON email_verification_tokens (user_id)`);
      db.run(`CREATE INDEX IF NOT EXISTS idx_verification_tokens_token ON email_verification_tokens (token)`);
      db.run(`CREATE INDEX IF NOT EXISTS idx_sync_user_id ON user_data_sync (user_id)`);
      db.run(`CREATE INDEX IF NOT EXISTS idx_sync_data_type ON user_data_sync (data_type)`);

      // Clean up expired tokens and sessions (run on startup)
      db.run(`DELETE FROM user_sessions WHERE expires_at < datetime('now')`);
      db.run(`DELETE FROM password_reset_tokens WHERE expires_at < datetime('now')`);
      db.run(`DELETE FROM email_verification_tokens WHERE expires_at < datetime('now')`);

      console.log('✅ Database tables created successfully');
      resolve();
    });
  });
};

const getDatabase = () => db;

module.exports = {
  initializeDatabase,
  getDatabase
};
