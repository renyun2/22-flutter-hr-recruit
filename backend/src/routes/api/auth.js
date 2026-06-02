const express = require('express');
const { v4: uuid } = require('uuid');
const db = require('../../db');
const { authRequired } = require('../../middleware/auth');

const router = express.Router();

router.post('/login', (req, res) => {
  const { username, password } = req.body || {};
  if (!username || !password) {
    return res.status(400).json({ error: '请输入账号和密码', code: 400 });
  }
  const user = db
    .prepare('SELECT id, username, name, role, email FROM users WHERE username = ? AND password = ?')
    .get(username, password);
  if (!user) return res.status(401).json({ error: '账号或密码错误', code: 401 });

  const token = uuid();
  db.prepare('INSERT INTO sessions (token, user_id) VALUES (?, ?)').run(token, user.id);
  res.json({ token, user });
});

router.get('/me', authRequired, (req, res) => {
  res.json({ user: req.user });
});

router.post('/logout', authRequired, (req, res) => {
  db.prepare('DELETE FROM sessions WHERE token = ?').run(req.token);
  res.json({ ok: true });
});

module.exports = router;
