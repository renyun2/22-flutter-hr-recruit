const express = require('express');
const { v4: uuid } = require('uuid');
const db = require('../../db');
const { authRequired, requireRole } = require('../../middleware/auth');

const router = express.Router();
router.use(authRequired);

router.get('/', requireRole('hr', 'hiring_manager'), (req, res) => {
  const { status } = req.query;
  let sql = `
    SELECT o.*, a.candidate_name, j.title AS job_title, u.name AS creator_name
    FROM offers o
    JOIN applications a ON a.id = o.application_id
    JOIN jobs j ON j.id = o.job_id
    JOIN users u ON u.id = o.created_by
    WHERE 1=1
  `;
  const params = [];
  if (status) {
    sql += ' AND o.status = ?';
    params.push(status);
  }
  if (req.user.role === 'hiring_manager') {
    sql += ' AND o.needs_approval = 1';
  }
  sql += ' ORDER BY o.created_at DESC';
  const items = db.prepare(sql).all(...params).map((row) => ({
    ...row,
    needsApproval: !!row.needs_approval,
  }));
  res.json({ items });
});

router.post('/', requireRole('hr'), (req, res) => {
  const { applicationId, salary, bonus } = req.body || {};
  if (!applicationId || salary == null) {
    return res.status(400).json({ error: '投递与薪资必填', code: 400 });
  }

  const application = db
    .prepare(
      `SELECT a.*, j.salary_min, j.salary_max, j.title AS job_title
       FROM applications a JOIN jobs j ON j.id = a.job_id WHERE a.id = ?`
    )
    .get(applicationId);
  if (!application) return res.status(404).json({ error: '投递不存在', code: 404 });

  const salaryNum = Number(salary);
  const needsApproval = salaryNum > application.salary_max ? 1 : 0;
  const status = needsApproval ? 'pending_approval' : 'approved';

  const id = uuid();
  db.prepare(
    `INSERT INTO offers (id, application_id, job_id, salary, bonus, status, needs_approval, created_by)
     VALUES (?,?,?,?,?,?,?,?)`
  ).run(
    id,
    applicationId,
    application.job_id,
    salaryNum,
    Number(bonus) || 0,
    status,
    needsApproval,
    req.user.id
  );

  if (needsApproval) {
    const managers = db.prepare('SELECT id FROM users WHERE role = ?').all('hiring_manager');
    managers.forEach((m) => {
      db.prepare(
        'INSERT INTO notifications (id, user_id, title, body, type) VALUES (?,?,?,?,?)'
      ).run(
        uuid(),
        m.id,
        'Offer 待审批',
        `${application.candidate_name} 的 Offer 薪资超出 band，需审批`,
        'offer_approval'
      );
    });
  } else {
    db.prepare('UPDATE applications SET stage = ?, updated_at = datetime(\'now\') WHERE id = ?').run(
      'offer',
      applicationId
    );
  }

  const offer = db.prepare('SELECT * FROM offers WHERE id = ?').get(id);
  res.status(201).json({ ...offer, needsApproval: !!offer.needs_approval });
});

router.post('/:id/approve', requireRole('hiring_manager'), (req, res) => {
  const offer = db.prepare('SELECT * FROM offers WHERE id = ?').get(req.params.id);
  if (!offer) return res.status(404).json({ error: 'Offer 不存在', code: 404 });
  if (!offer.needs_approval) {
    return res.status(400).json({ error: '该 Offer 无需审批', code: 400 });
  }
  if (offer.status !== 'pending_approval') {
    return res.status(400).json({ error: 'Offer 已处理', code: 400 });
  }

  const { approved, comment } = req.body || {};
  const now = new Date().toISOString();
  const status = approved ? 'approved' : 'rejected';

  db.prepare(
    'UPDATE offers SET status = ?, approved_by = ?, approved_at = ? WHERE id = ?'
  ).run(status, req.user.id, now, offer.id);

  if (approved) {
    db.prepare('UPDATE applications SET stage = ?, updated_at = ? WHERE id = ?').run(
      'offer',
      now,
      offer.application_id
    );
    db.prepare(
      'INSERT INTO notifications (id, user_id, title, body, type) VALUES (?,?,?,?,?)'
    ).run(uuid(), offer.created_by, 'Offer 已批准', comment || '经理已批准 Offer', 'offer_approval');
  }

  res.json({
    ...db.prepare('SELECT * FROM offers WHERE id = ?').get(offer.id),
    needsApproval: !!offer.needs_approval,
  });
});

module.exports = router;
