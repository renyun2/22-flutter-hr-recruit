const express = require('express');
const db = require('../../db');
const { authRequired } = require('../../middleware/auth');

const router = express.Router();
router.use(authRequired);

router.get('/', (req, res) => {
  const items = db
    .prepare('SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC LIMIT 50')
    .all(req.user.id)
    .map((row) => ({ ...row, read: !!row.read_flag }));
  res.json({ items });
});

router.patch('/:id/read', (req, res) => {
  db.prepare('UPDATE notifications SET read_flag = 1 WHERE id = ? AND user_id = ?').run(
    req.params.id,
    req.user.id
  );
  res.json({ ok: true });
});

module.exports = router;
