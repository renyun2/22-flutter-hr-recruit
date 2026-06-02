const express = require('express');
const db = require('../../db');
const { authRequired, requireRole } = require('../../middleware/auth');
const { STAGE_LABELS } = require('../../utils/stages');

const router = express.Router();
router.use(authRequired);
router.use(requireRole('candidate'));

function mapApplication(row) {
  return {
    ...row,
    starred: !!row.starred,
    tags: JSON.parse(row.tags_json || '[]'),
    stageLabel: STAGE_LABELS[row.stage] || row.stage,
  };
}

router.get('/applications', (req, res) => {
  const items = db
    .prepare(
      `SELECT a.*, j.title AS job_title, j.department, j.location
       FROM applications a
       JOIN jobs j ON j.id = a.job_id
       WHERE a.candidate_id = ?
       ORDER BY a.created_at DESC`
    )
    .all(req.user.id)
    .map(mapApplication);
  res.json({ items });
});

module.exports = router;
