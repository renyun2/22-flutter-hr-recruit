const express = require('express');
const { v4: uuid } = require('uuid');
const db = require('../../db');
const { authRequired, requireRole } = require('../../middleware/auth');

const router = express.Router();

function mapJob(row) {
  return {
    ...row,
    salaryBand: { min: row.salary_min, max: row.salary_max },
  };
}

router.get('/public', (_req, res) => {
  const items = db
    .prepare(
      `SELECT id, title, department, location, description, requirements,
              salary_min, salary_max, status, created_at
       FROM jobs WHERE status = 'active' ORDER BY created_at DESC`
    )
    .all()
    .map(mapJob);
  res.json({ items });
});

router.get('/public/:id', (req, res) => {
  const job = db
    .prepare(
      `SELECT id, title, department, location, description, requirements,
              salary_min, salary_max, status, created_at
       FROM jobs WHERE id = ? AND status = 'active'`
    )
    .get(req.params.id);
  if (!job) return res.status(404).json({ error: '职位不存在或未发布', code: 404 });
  res.json(mapJob(job));
});

router.use(authRequired);

router.get('/', requireRole('hr', 'hiring_manager'), (req, res) => {
  const { status } = req.query;
  let sql = 'SELECT * FROM jobs WHERE 1=1';
  const params = [];
  if (status) {
    sql += ' AND status = ?';
    params.push(status);
  }
  sql += ' ORDER BY updated_at DESC';
  const items = db.prepare(sql).all(...params).map(mapJob);
  res.json({ items });
});

router.get('/:id', requireRole('hr', 'hiring_manager'), (req, res) => {
  const job = db.prepare('SELECT * FROM jobs WHERE id = ?').get(req.params.id);
  if (!job) return res.status(404).json({ error: '职位不存在', code: 404 });
  const applicationCount = db
    .prepare('SELECT COUNT(*) AS c FROM applications WHERE job_id = ?')
    .get(job.id).c;
  res.json({ ...mapJob(job), applicationCount });
});

router.post('/', requireRole('hr'), (req, res) => {
  const { title, department, location, description, requirements, salaryMin, salaryMax, status } =
    req.body || {};
  if (!title) return res.status(400).json({ error: '职位标题必填', code: 400 });
  const id = uuid();
  const now = new Date().toISOString();
  db.prepare(
    `INSERT INTO jobs (id, title, department, location, description, requirements,
      salary_min, salary_max, status, created_by, created_at, updated_at)
     VALUES (?,?,?,?,?,?,?,?,?,?,?,?)`
  ).run(
    id,
    title,
    department || '',
    location || '',
    description || '',
    requirements || '',
    Number(salaryMin) || 0,
    Number(salaryMax) || 0,
    status || 'active',
    req.user.id,
    now,
    now
  );
  res.status(201).json(mapJob(db.prepare('SELECT * FROM jobs WHERE id = ?').get(id)));
});

router.put('/:id', requireRole('hr'), (req, res) => {
  const job = db.prepare('SELECT * FROM jobs WHERE id = ?').get(req.params.id);
  if (!job) return res.status(404).json({ error: '职位不存在', code: 404 });
  const { title, department, location, description, requirements, salaryMin, salaryMax, status } =
    req.body || {};
  db.prepare(
    `UPDATE jobs SET
      title = COALESCE(?, title),
      department = COALESCE(?, department),
      location = COALESCE(?, location),
      description = COALESCE(?, description),
      requirements = COALESCE(?, requirements),
      salary_min = COALESCE(?, salary_min),
      salary_max = COALESCE(?, salary_max),
      status = COALESCE(?, status),
      updated_at = datetime('now')
     WHERE id = ?`
  ).run(
    title,
    department,
    location,
    description,
    requirements,
    salaryMin != null ? Number(salaryMin) : null,
    salaryMax != null ? Number(salaryMax) : null,
    status,
    job.id
  );
  res.json(mapJob(db.prepare('SELECT * FROM jobs WHERE id = ?').get(job.id)));
});

router.patch('/:id/status', requireRole('hr'), (req, res) => {
  const job = db.prepare('SELECT * FROM jobs WHERE id = ?').get(req.params.id);
  if (!job) return res.status(404).json({ error: '职位不存在', code: 404 });
  const { status } = req.body || {};
  if (!['draft', 'active', 'archived'].includes(status)) {
    return res.status(400).json({ error: '无效状态', code: 400 });
  }
  db.prepare('UPDATE jobs SET status = ?, updated_at = datetime(\'now\') WHERE id = ?').run(
    status,
    job.id
  );
  res.json(mapJob(db.prepare('SELECT * FROM jobs WHERE id = ?').get(job.id)));
});

router.post('/:id/copy', requireRole('hr'), (req, res) => {
  const job = db.prepare('SELECT * FROM jobs WHERE id = ?').get(req.params.id);
  if (!job) return res.status(404).json({ error: '职位不存在', code: 404 });
  const id = uuid();
  const now = new Date().toISOString();
  db.prepare(
    `INSERT INTO jobs (id, title, department, location, description, requirements,
      salary_min, salary_max, status, created_by, created_at, updated_at)
     VALUES (?,?,?,?,?,?,?,?,?,?,?,?)`
  ).run(
    id,
    `${job.title}（复制）`,
    job.department,
    job.location,
    job.description,
    job.requirements,
    job.salary_min,
    job.salary_max,
    'draft',
    req.user.id,
    now,
    now
  );
  res.status(201).json(mapJob(db.prepare('SELECT * FROM jobs WHERE id = ?').get(id)));
});

router.delete('/:id', requireRole('hr'), (req, res) => {
  const job = db.prepare('SELECT * FROM jobs WHERE id = ?').get(req.params.id);
  if (!job) return res.status(404).json({ error: '职位不存在', code: 404 });
  db.prepare('UPDATE jobs SET status = ?, updated_at = datetime(\'now\') WHERE id = ?').run(
    'archived',
    job.id
  );
  res.json({ ok: true });
});

module.exports = router;
