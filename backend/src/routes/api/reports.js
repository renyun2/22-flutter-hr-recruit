const express = require('express');
const db = require('../../db');
const { authRequired, requireRole } = require('../../middleware/auth');
const { STAGES, STAGE_LABELS, funnelStages } = require('../../utils/stages');

const router = express.Router();
router.use(authRequired);
router.use(requireRole('hr', 'hiring_manager'));

router.get('/funnel', (req, res) => {
  const { jobId } = req.query;
  let baseSql = 'FROM applications WHERE 1=1';
  const params = [];
  if (jobId) {
    baseSql += ' AND job_id = ?';
    params.push(jobId);
  }

  const total = db.prepare(`SELECT COUNT(*) AS c ${baseSql}`).get(...params).c;
  const stages = funnelStages();
  const counts = db
    .prepare(`SELECT stage, COUNT(*) AS count ${baseSql} GROUP BY stage`)
    .all(...params);
  const countMap = Object.fromEntries(counts.map((r) => [r.stage, r.count]));

  const funnel = stages.map((stage, idx) => {
    const count = countMap[stage] || 0;
    const prevStage = idx > 0 ? stages[idx - 1] : null;
    const prevCount = prevStage ? countMap[prevStage] || 0 : total;
    const conversionRate = prevCount > 0 ? Math.round((count / prevCount) * 1000) / 10 : 0;
    return {
      stage,
      label: STAGE_LABELS[stage],
      count,
      conversionRate: idx === 0 ? 100 : conversionRate,
    };
  });

  funnel.push({
    stage: 'rejected',
    label: STAGE_LABELS.rejected,
    count: countMap.rejected || 0,
    conversionRate: total > 0 ? Math.round(((countMap.rejected || 0) / total) * 1000) / 10 : 0,
  });

  res.json({ total, funnel });
});

router.get('/source', (_req, res) => {
  const rows = db
    .prepare(
      `SELECT source, COUNT(*) AS count
       FROM applications
       GROUP BY source
       ORDER BY count DESC`
    )
    .all();
  const total = rows.reduce((sum, r) => sum + r.count, 0);
  const items = rows.map((r) => ({
    source: r.source,
    count: r.count,
    percentage: total > 0 ? Math.round((r.count / total) * 1000) / 10 : 0,
  }));
  res.json({ total, items });
});

module.exports = router;
