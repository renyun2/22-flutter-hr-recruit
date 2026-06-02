const express = require('express');
const { v4: uuid } = require('uuid');
const db = require('../../db');
const { authRequired, requireRole } = require('../../middleware/auth');
const { DEFAULT_DURATION, hasInterviewConflict, suggestSlots } = require('../../utils/interviews');

const router = express.Router();
router.use(authRequired);

function mapInterview(row) {
  return {
    ...row,
    application: row.application_id
      ? {
          id: row.application_id,
          candidateName: row.candidate_name,
          jobTitle: row.job_title,
        }
      : undefined,
  };
}

router.get('/', (req, res) => {
  const { interviewerId, applicationId, status } = req.query;
  let sql = `
    SELECT i.*, a.candidate_name, j.title AS job_title
    FROM interviews i
    JOIN applications a ON a.id = i.application_id
    JOIN jobs j ON j.id = a.job_id
    WHERE 1=1
  `;
  const params = [];

  if (req.user.role === 'interviewer') {
    sql += ' AND i.interviewer_id = ?';
    params.push(req.user.id);
  } else if (interviewerId) {
    sql += ' AND i.interviewer_id = ?';
    params.push(interviewerId);
  } else if (!['hr', 'hiring_manager'].includes(req.user.role)) {
    return res.status(403).json({ error: '无权限', code: 403 });
  }

  if (applicationId) {
    sql += ' AND i.application_id = ?';
    params.push(applicationId);
  }
  if (status) {
    sql += ' AND i.status = ?';
    params.push(status);
  }

  sql += ' ORDER BY i.scheduled_at ASC';
  const items = db.prepare(sql).all(...params).map(mapInterview);
  res.json({ items });
});

router.post('/', requireRole('hr'), (req, res) => {
  const { applicationId, interviewerId, interviewerUsername, roundType, scheduledAt, durationMinutes, location } =
    req.body || {};
  if (!applicationId || !scheduledAt) {
    return res.status(400).json({ error: '投递与时间必填', code: 400 });
  }

  const application = db.prepare('SELECT * FROM applications WHERE id = ?').get(applicationId);
  if (!application) return res.status(404).json({ error: '投递不存在', code: 404 });

  let resolvedInterviewerId = interviewerId;
  if (!resolvedInterviewerId && interviewerUsername) {
    const byName = db.prepare('SELECT id FROM users WHERE username = ? AND role = ?').get(
      interviewerUsername,
      'interviewer'
    );
    resolvedInterviewerId = byName?.id;
  }
  if (!resolvedInterviewerId) {
    return res.status(400).json({ error: '面试官必填', code: 400 });
  }

  const interviewer = db
    .prepare('SELECT * FROM users WHERE id = ? AND role = ?')
    .get(resolvedInterviewerId, 'interviewer');
  if (!interviewer) return res.status(404).json({ error: '面试官不存在', code: 404 });

  const duration = Number(durationMinutes) || DEFAULT_DURATION;
  if (hasInterviewConflict(resolvedInterviewerId, scheduledAt, duration)) {
    return res.status(409).json({
      error: '该面试官此时段已有面试安排',
      code: 409,
      suggestedSlots: suggestSlots(resolvedInterviewerId, scheduledAt, duration),
    });
  }

  const id = uuid();
  db.prepare(
    `INSERT INTO interviews (id, application_id, interviewer_id, round_type, scheduled_at, duration_minutes, location)
     VALUES (?,?,?,?,?,?,?)`
  ).run(
    id,
    applicationId,
    resolvedInterviewerId,
    roundType || 'round1',
    scheduledAt,
    duration,
    location || ''
  );

  db.prepare(
    'INSERT INTO notifications (id, user_id, title, body, type) VALUES (?,?,?,?,?)'
  ).run(
    uuid(),
    resolvedInterviewerId,
    '新面试安排',
    `${application.candidate_name} 的 ${roundType || 'round1'} 面试已安排`,
    'interview'
  );

  const row = db
    .prepare(
      `SELECT i.*, a.candidate_name, j.title AS job_title
       FROM interviews i
       JOIN applications a ON a.id = i.application_id
       JOIN jobs j ON j.id = a.job_id
       WHERE i.id = ?`
    )
    .get(id);
  res.status(201).json(mapInterview(row));
});

router.post('/:id/feedback', requireRole('interviewer', 'hr'), (req, res) => {
  const interview = db.prepare('SELECT * FROM interviews WHERE id = ?').get(req.params.id);
  if (!interview) return res.status(404).json({ error: '面试不存在', code: 404 });
  if (req.user.role === 'interviewer' && interview.interviewer_id !== req.user.id) {
    return res.status(403).json({ error: '无权限', code: 403 });
  }

  const {
    technicalScore,
    communicationScore,
    cultureScore,
    overallScore,
    recommendation,
    comment,
  } = req.body || {};

  const existing = db.prepare('SELECT id FROM interview_feedback WHERE interview_id = ?').get(interview.id);
  if (existing) {
    return res.status(400).json({ error: '该面试已提交反馈', code: 400 });
  }

  const id = uuid();
  db.prepare(
    `INSERT INTO interview_feedback (id, interview_id, interviewer_id, technical_score,
      communication_score, culture_score, overall_score, recommendation, comment)
     VALUES (?,?,?,?,?,?,?,?,?)`
  ).run(
    id,
    interview.id,
    req.user.id,
    Number(technicalScore) || 0,
    Number(communicationScore) || 0,
    Number(cultureScore) || 0,
    Number(overallScore) || 0,
    recommendation || 'hold',
    comment || ''
  );
  db.prepare('UPDATE interviews SET status = ? WHERE id = ?').run('completed', interview.id);

  res.status(201).json(db.prepare('SELECT * FROM interview_feedback WHERE id = ?').get(id));
});

module.exports = router;
