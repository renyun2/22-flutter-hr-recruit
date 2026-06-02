const express = require('express');
const { v4: uuid } = require('uuid');
const db = require('../../db');
const { authRequired } = require('../../middleware/auth');

const router = express.Router();
router.use(authRequired);

function generateCode() {
  return `REF-${Math.random().toString(36).slice(2, 8).toUpperCase()}`;
}

router.post('/', (req, res) => {
  const { jobId } = req.body || {};
  let code = generateCode();
  while (db.prepare('SELECT id FROM referrals WHERE code = ?').get(code)) {
    code = generateCode();
  }
  const id = uuid();
  db.prepare('INSERT INTO referrals (id, code, referrer_id, job_id) VALUES (?,?,?,?)').run(
    id,
    code,
    req.user.id,
    jobId || null
  );
  res.status(201).json(db.prepare('SELECT * FROM referrals WHERE id = ?').get(id));
});

router.get('/stats', (req, res) => {
  const rows = db
    .prepare(
      `SELECT code, job_id, points_earned, successful_count, created_at
       FROM referrals WHERE referrer_id = ? ORDER BY created_at DESC`
    )
    .all(req.user.id);
  const totalPoints = rows.reduce((sum, r) => sum + r.points_earned, 0);
  const totalSuccess = rows.reduce((sum, r) => sum + r.successful_count, 0);
  res.json({
    totalPoints,
    totalSuccess,
    rewardPerOnboard: 5000,
    items: rows,
  });
});

module.exports = router;
