const express = require('express');
const db = require('../../db');
const { authRequired, requireRole } = require('../../middleware/auth');
const { STAGE_LABELS } = require('../../utils/stages');

const router = express.Router();
router.use(authRequired);
router.use(requireRole('hr', 'hiring_manager'));

function mapTalent(row) {
  return {
    ...row,
    starred: !!row.starred,
    tags: JSON.parse(row.tags_json || '[]'),
    stageLabel: STAGE_LABELS[row.stage] || row.stage,
  };
}

router.get('/', (req, res) => {
  const { keyword, tag, starred } = req.query;
  let sql = `
    SELECT a.*, j.title AS job_title
    FROM applications a
    JOIN jobs j ON j.id = a.job_id
    WHERE (a.starred = 1 OR a.stage IN ('round2', 'offer', 'onboarded'))
  `;
  const params = [];

  if (starred === '1' || starred === 'true') {
    sql += ' AND a.starred = 1';
  }
  if (keyword) {
    sql += ' AND (a.candidate_name LIKE ? OR a.skills LIKE ?)';
    const kw = `%${keyword}%`;
    params.push(kw, kw);
  }
  if (tag) {
    sql += ' AND a.tags_json LIKE ?';
    params.push(`%"${tag}"%`);
  }

  sql += ' ORDER BY a.starred DESC, a.updated_at DESC';
  const items = db.prepare(sql).all(...params).map(mapTalent);
  res.json({ items });
});

router.patch('/:applicationId', (req, res) => {
  const app = db.prepare('SELECT * FROM applications WHERE id = ?').get(req.params.applicationId);
  if (!app) return res.status(404).json({ error: '候选人不存在', code: 404 });

  const { starred, tags } = req.body || {};
  const tagsJson = tags != null ? JSON.stringify(tags) : app.tags_json;
  const starVal = starred != null ? (starred ? 1 : 0) : app.starred;

  db.prepare('UPDATE applications SET starred = ?, tags_json = ?, updated_at = datetime(\'now\') WHERE id = ?').run(
    starVal,
    tagsJson,
    app.id
  );
  res.json(mapTalent(db.prepare('SELECT * FROM applications WHERE id = ?').get(app.id)));
});

module.exports = router;
