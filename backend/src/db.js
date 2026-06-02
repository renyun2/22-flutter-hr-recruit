const Database = require('better-sqlite3');
const fs = require('fs');
const path = require('path');

const dataDir = path.join(__dirname, '..', 'data');
if (!fs.existsSync(dataDir)) fs.mkdirSync(dataDir, { recursive: true });

const dbPath = process.env.HR_DB_PATH || path.join(dataDir, 'hr.db');
const db = new Database(dbPath);
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

function initSchema() {
  db.exec(`
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      username TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      password TEXT NOT NULL DEFAULT '123456',
      role TEXT NOT NULL CHECK(role IN ('hr','interviewer','candidate','hiring_manager')),
      email TEXT DEFAULT '',
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS sessions (
      token TEXT PRIMARY KEY,
      user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS jobs (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      department TEXT NOT NULL DEFAULT '',
      location TEXT NOT NULL DEFAULT '',
      description TEXT NOT NULL DEFAULT '',
      requirements TEXT NOT NULL DEFAULT '',
      salary_min REAL NOT NULL DEFAULT 0,
      salary_max REAL NOT NULL DEFAULT 0,
      status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('draft','active','archived')),
      created_by TEXT NOT NULL REFERENCES users(id),
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      updated_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS applications (
      id TEXT PRIMARY KEY,
      job_id TEXT NOT NULL REFERENCES jobs(id),
      candidate_id TEXT REFERENCES users(id),
      candidate_name TEXT NOT NULL,
      email TEXT NOT NULL DEFAULT '',
      phone TEXT NOT NULL DEFAULT '',
      education TEXT NOT NULL DEFAULT '',
      years_experience REAL NOT NULL DEFAULT 0,
      skills TEXT NOT NULL DEFAULT '',
      resume_url TEXT DEFAULT '',
      source TEXT NOT NULL DEFAULT '官网',
      referral_code TEXT DEFAULT NULL,
      stage TEXT NOT NULL DEFAULT 'applied',
      starred INTEGER NOT NULL DEFAULT 0,
      tags_json TEXT NOT NULL DEFAULT '[]',
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      updated_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS application_timeline (
      id TEXT PRIMARY KEY,
      application_id TEXT NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
      user_id TEXT REFERENCES users(id),
      action TEXT NOT NULL,
      from_stage TEXT,
      to_stage TEXT,
      note TEXT DEFAULT '',
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS interviews (
      id TEXT PRIMARY KEY,
      application_id TEXT NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
      interviewer_id TEXT NOT NULL REFERENCES users(id),
      round_type TEXT NOT NULL DEFAULT 'round1',
      scheduled_at TEXT NOT NULL,
      duration_minutes INTEGER NOT NULL DEFAULT 60,
      status TEXT NOT NULL DEFAULT 'scheduled',
      location TEXT DEFAULT '',
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS interview_feedback (
      id TEXT PRIMARY KEY,
      interview_id TEXT NOT NULL REFERENCES interviews(id) ON DELETE CASCADE,
      interviewer_id TEXT NOT NULL REFERENCES users(id),
      technical_score INTEGER NOT NULL DEFAULT 0,
      communication_score INTEGER NOT NULL DEFAULT 0,
      culture_score INTEGER NOT NULL DEFAULT 0,
      overall_score INTEGER NOT NULL DEFAULT 0,
      recommendation TEXT NOT NULL DEFAULT 'hold',
      comment TEXT DEFAULT '',
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS offers (
      id TEXT PRIMARY KEY,
      application_id TEXT NOT NULL REFERENCES applications(id),
      job_id TEXT NOT NULL REFERENCES jobs(id),
      salary REAL NOT NULL,
      bonus REAL NOT NULL DEFAULT 0,
      status TEXT NOT NULL DEFAULT 'draft',
      needs_approval INTEGER NOT NULL DEFAULT 0,
      created_by TEXT NOT NULL REFERENCES users(id),
      approved_by TEXT REFERENCES users(id),
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      approved_at TEXT
    );

    CREATE TABLE IF NOT EXISTS referrals (
      id TEXT PRIMARY KEY,
      code TEXT NOT NULL UNIQUE,
      referrer_id TEXT NOT NULL REFERENCES users(id),
      job_id TEXT REFERENCES jobs(id),
      points_earned INTEGER NOT NULL DEFAULT 0,
      successful_count INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS notifications (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      title TEXT NOT NULL,
      body TEXT NOT NULL,
      type TEXT NOT NULL DEFAULT 'system',
      read_flag INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    );
  `);
}

initSchema();

module.exports = db;
