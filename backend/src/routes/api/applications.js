const express = require('express');
const { v4: uuid } = require('uuid');
const db = require('../../db');
const { authRequired, requireRole } = require('../../middleware/auth');
const { STAGES, STAGE_LABELS, canMoveStage } = require('../../utils/stages');

const router = express.Router();

function mapApplication(row) {
  return {
    ...row,
    starred: !!row.starred,
    tags: JSON.parse(row.tags_json || '[]'),
    stageLabel: STAGE_LABELS[row.stage] || row.stage,
  };
}

function addTimeline(applicationId, userId, action, fromStage, toStage, note) {
  db.prepare(
    `INSERT INTO application_timeline (id, application_id, user_id, action, from_stage, to_stage, note)
     VALUES (?,?,?,?,?,?,?)`
  ).run(uuid(), applicationId, userId, action, fromStage, toStage, note || '');
}

function rewardReferralOnOnboard(application) {
  if (!application.referral_code) return;
  const referral = db.prepare('SELECT * FROM referrals WHERE code = ?').get(application.referral_code);
  if (!referral) return;
  db.prepare(
    'UPDATE referrals SET points_earned = points_earned + 5000, successful_count = successful_count + 1 WHERE id = ?'
  ).run(referral.id);
  db.prepare(
    'INSERT INTO notifications (id, user_id, title, body, type) VALUES (?,?,?,?,?)'
  ).run(
    uuid(),
    referral.referrer_id,
    '内推奖励',
    `候选人 ${application.candidate_name} 已成功入职，获得 5000 积分`,
    'referral'
  );
}

router.post('/', authRequired, (req, res) => {
  const {
    jobId,
    candidateName,
    email,
    phone,
    education,
    yearsExperience,
    skills,
    resumeUrl,
    source,
    referralCode,
  } = req.body || {};
  if (!jobId) return res.status(400).json({ error: '职位必填', code: 400 });

  const job = db.prepare('SELECT * FROM jobs WHERE id = ? AND status = ?').get(jobId, 'active');
  if (!job) return res.status(404).json({ error: '职位不存在或未开放', code: 404 });

  const name = candidateName || req.user.name;
  const id = uuid();
  const now = new Date().toISOString();
  const candidateId = req.user.role === 'candidate' ? req.user.id : null;

  db.prepare(
    `INSERT INTO applications (id, job_id, candidate_id, candidate_name, email, phone, education,
      years_experience, skills, resume_url, source, referral_code, stage, created_at, updated_at)
     VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)`
  ).run(
    id,
    jobId,
    candidateId,
    name,
    email || req.user.email || '',
    phone || '',
    education || '',
    Number(yearsExperience) || 0,
    skills || '',
    resumeUrl || '',
    source || (referralCode ? '内推' : '官网'),
    referralCode || null,
    'applied',
    now,
    now
  );
  addTimeline(id, req.user.id, 'apply', null, 'applied', '提交投递');
  res.status(201).json(mapApplication(db.prepare('SELECT * FROM applications WHERE id = ?').get(id)));
});

router.use(authRequired);

router.get('/', requireRole('hr', 'hiring_manager'), (req, res) => {
  const { jobId, stage, keyword, education, minYears, maxYears } = req.query;
  let sql = `
    SELECT a.*, j.title AS job_title
    FROM applications a
    JOIN jobs j ON j.id = a.job_id
    WHERE 1=1
  `;
  const params = [];

  if (jobId) {
    sql += ' AND a.job_id = ?';
    params.push(jobId);
  }
  if (stage) {
    sql += ' AND a.stage = ?';
    params.push(stage);
  }
  if (keyword) {
    sql += ' AND (a.candidate_name LIKE ? OR a.skills LIKE ? OR a.email LIKE ?)';
    const kw = `%${keyword}%`;
    params.push(kw, kw, kw);
  }
  if (education) {
    sql += ' AND a.education LIKE ?';
    params.push(`%${education}%`);
  }
  if (minYears != null && minYears !== '') {
    sql += ' AND a.years_experience >= ?';
    params.push(Number(minYears));
  }
  if (maxYears != null && maxYears !== '') {
    sql += ' AND a.years_experience <= ?';
    params.push(Number(maxYears));
  }

  sql += ' ORDER BY a.updated_at DESC';
  const items = db.prepare(sql).all(...params).map(mapApplication);
  const byStage = {};
  STAGES.concat(['rejected']).forEach((s) => {
    byStage[s] = items.filter((a) => a.stage === s);
  });
  res.json({
    items,
    byStage,
    stages: STAGES.concat(['rejected']).map((s) => ({ key: s, label: STAGE_LABELS[s] })),
  });
});

router.get('/:id', authRequired, (req, res) => {
  const app = db
    .prepare(
      `SELECT a.*, j.title AS job_title, j.department, j.salary_min, j.salary_max
       FROM applications a JOIN jobs j ON j.id = a.job_id WHERE a.id = ?`
    )
    .get(req.params.id);
  if (!app) return res.status(404).json({ error: '投递不存在', code: 404 });
  if (req.user.role === 'candidate' && app.candidate_id !== req.user.id) {
    return res.status(403).json({ error: '无权限', code: 403 });
  }
  res.json(mapApplication(app));
});

router.patch('/:id/stage', requireRole('hr', 'hiring_manager'), (req, res) => {
  const app = db.prepare('SELECT * FROM applications WHERE id = ?').get(req.params.id);
  if (!app) return res.status(404).json({ error: '投递不存在', code: 404 });

  const { stage, note } = req.body || {};
  if (!stage) return res.status(400).json({ error: '阶段必填', code: 400 });
  if (!canMoveStage(app.stage, stage, req.user.role)) {
    return res.status(403).json({ error: '不允许的阶段变更', code: 403 });
  }

  const now = new Date().toISOString();
  db.prepare('UPDATE applications SET stage = ?, updated_at = ? WHERE id = ?').run(stage, now, app.id);
  addTimeline(app.id, req.user.id, 'stage_change', app.stage, stage, note);

  if (stage === 'onboarded') {
    rewardReferralOnOnboard(app);
  }

  res.json(mapApplication(db.prepare('SELECT * FROM applications WHERE id = ?').get(app.id)));
});

router.get('/:id/timeline', authRequired, (req, res) => {
  const app = db.prepare('SELECT * FROM applications WHERE id = ?').get(req.params.id);
  if (!app) return res.status(404).json({ error: '投递不存在', code: 404 });
  if (req.user.role === 'candidate' && app.candidate_id !== req.user.id) {
    return res.status(403).json({ error: '无权限', code: 403 });
  }
  const items = db
    .prepare(
      `SELECT t.*, u.name AS user_name, u.role AS user_role
       FROM application_timeline t
       LEFT JOIN users u ON u.id = t.user_id
       WHERE t.application_id = ?
       ORDER BY t.created_at ASC`
    )
    .all(app.id);
  res.json({ items });
});

module.exports = router;
