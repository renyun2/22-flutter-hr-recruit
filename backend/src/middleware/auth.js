const db = require('../db');

function authRequired(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ error: '未登录', code: 401 });

  const session = db.prepare('SELECT user_id FROM sessions WHERE token = ?').get(token);
  if (!session) return res.status(401).json({ error: '登录已过期', code: 401 });

  const user = db
    .prepare('SELECT id, username, name, role, email FROM users WHERE id = ?')
    .get(session.user_id);
  if (!user) return res.status(401).json({ error: '用户不存在', code: 401 });

  req.token = token;
  req.user = user;
  next();
}

function requireRole(...roles) {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ error: '无权限', code: 403 });
    }
    next();
  };
}

module.exports = { authRequired, requireRole };
