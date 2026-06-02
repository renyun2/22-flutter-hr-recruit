const { v4: uuid } = require('uuid');
const db = require('./db');
const { STAGES } = require('./utils/stages');

const SOURCES = ['官网', 'Boss直聘', '内推', '猎聘', '校园招聘'];
const EDUCATIONS = ['大专', '本科', '硕士', '博士'];
const SKILLS = ['Java', 'Flutter', 'React', 'Python', 'SQL', '产品设计', '数据分析'];
const DEPARTMENTS = ['研发', '产品', '设计', '市场', '运营', '人力'];
const LOCATIONS = ['上海', '北京', '深圳', '杭州', '成都'];

const STAGE_DISTRIBUTION = [
  { stage: 'applied', count: 15 },
  { stage: 'screening', count: 12 },
  { stage: 'written', count: 10 },
  { stage: 'round1', count: 12 },
  { stage: 'round2', count: 10 },
  { stage: 'offer', count: 8 },
  { stage: 'onboarded', count: 5 },
  { stage: 'rejected', count: 18 },
];

function daysAgo(n) {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return d.toISOString();
}

function daysFromNow(n) {
  const d = new Date();
  d.setDate(d.getDate() + n);
  d.setHours(10, 0, 0, 0);
  return d.toISOString();
}

function seed() {
  const count = db.prepare('SELECT COUNT(*) AS c FROM users').get().c;
  if (count > 0) return;

  const hrId = uuid();
  const managerId = uuid();
  const candidate1Id = uuid();
  const interviewer1Id = uuid();
  const extraCandidateIds = Array.from({ length: 12 }, () => uuid());

  const insertUser = db.prepare(
    'INSERT INTO users (id, username, name, password, role, email) VALUES (?,?,?,?,?,?)'
  );
  insertUser.run(hrId, 'hr1', 'HR 张敏', '123456', 'hr', 'hr1@company.com');
  insertUser.run(managerId, 'manager1', '李经理', '123456', 'hiring_manager', 'manager1@company.com');
  insertUser.run(candidate1Id, 'candidate1', '王小明', '123456', 'candidate', 'candidate1@mail.com');
  insertUser.run(interviewer1Id, 'interviewer1', '赵面试官', '123456', 'interviewer', 'interviewer1@company.com');
  extraCandidateIds.forEach((id, i) => {
    insertUser.run(id, `candidate${i + 2}`, `候选人${i + 2}`, '123456', 'candidate', `c${i + 2}@mail.com`);
  });

  const insertJob = db.prepare(
    `INSERT INTO jobs (id, title, department, location, description, requirements,
      salary_min, salary_max, status, created_by, created_at, updated_at)
     VALUES (?,?,?,?,?,?,?,?,?,?,?,?)`
  );
  const jobIds = [];
  const jobTitles = [
    '高级 Flutter 工程师', 'Java 后端开发', '产品经理', 'UI 设计师', '数据分析师',
    'HRBP', '前端工程师', '测试工程师', '运维工程师', 'Android 开发',
    'iOS 开发', '算法工程师', '市场专员', '运营经理', '财务专员',
    '行政助理', '法务专员', '品牌经理', '客户成功', '销售代表',
    'DevOps 工程师', '技术文档工程师',
  ];
  jobTitles.forEach((title, i) => {
    const id = uuid();
    jobIds.push(id);
    const min = 8000 + (i % 5) * 2000;
    const max = min + 8000;
    insertJob.run(
      id,
      title,
      DEPARTMENTS[i % DEPARTMENTS.length],
      LOCATIONS[i % LOCATIONS.length],
      `${title} 岗位职责与团队介绍 #${i + 1}`,
      '本科及以上学历，相关经验优先，良好的沟通协作能力',
      min,
      max,
      i % 7 === 0 ? 'draft' : i % 11 === 0 ? 'archived' : 'active',
      hrId,
      daysAgo(30 - i),
      daysAgo(i % 5)
    );
  });

  const referralId = uuid();
  const referralCode = 'REF-HR001';
  db.prepare(
    'INSERT INTO referrals (id, code, referrer_id, job_id, points_earned, successful_count) VALUES (?,?,?,?,?,?)'
  ).run(referralId, referralCode, hrId, jobIds[0], 5000, 1);

  const insertApp = db.prepare(
    `INSERT INTO applications (id, job_id, candidate_id, candidate_name, email, phone, education,
      years_experience, skills, resume_url, source, referral_code, stage, starred, tags_json, created_at, updated_at)
     VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)`
  );
  const insertTimeline = db.prepare(
    'INSERT INTO application_timeline (id, application_id, user_id, action, from_stage, to_stage, note) VALUES (?,?,?,?,?,?,?)'
  );

  const allCandidateIds = [candidate1Id, ...extraCandidateIds];
  let appIndex = 0;
  const applicationIds = [];

  STAGE_DISTRIBUTION.forEach(({ stage, count }) => {
    for (let j = 0; j < count; j += 1) {
      appIndex += 1;
      const id = uuid();
      applicationIds.push({ id, stage });
      const candidateId = allCandidateIds[appIndex % allCandidateIds.length];
      const candidate = db.prepare('SELECT * FROM users WHERE id = ?').get(candidateId);
      const jobId = jobIds[appIndex % jobIds.length];
      const education = EDUCATIONS[appIndex % EDUCATIONS.length];
      const years = (appIndex % 8) + 0.5;
      const skills = `${SKILLS[appIndex % SKILLS.length]}, ${SKILLS[(appIndex + 2) % SKILLS.length]}`;
      const source = SOURCES[appIndex % SOURCES.length];
      const useReferral = appIndex === 3 ? referralCode : appIndex % 9 === 0 ? referralCode : null;
      const starred = appIndex % 6 === 0 ? 1 : 0;
      const tags = JSON.stringify(appIndex % 4 === 0 ? ['高潜', '技术强'] : appIndex % 3 === 0 ? ['沟通好'] : []);

      insertApp.run(
        id,
        jobId,
        candidateId,
        candidate.name,
        candidate.email,
        `138${String(10000000 + appIndex).slice(-8)}`,
        education,
        years,
        skills,
        `https://resume.example.com/${id}`,
        source,
        useReferral,
        stage,
        starred,
        tags,
        daysAgo(appIndex),
        daysAgo(appIndex % 3)
      );
      insertTimeline.run(uuid(), id, hrId, 'apply', null, 'applied', '投递简历');
      if (stage !== 'applied') {
        insertTimeline.run(uuid(), id, hrId, 'stage_change', 'applied', stage, `进入${stage}`);
      }
    }
  });

  const insertInterview = db.prepare(
    `INSERT INTO interviews (id, application_id, interviewer_id, round_type, scheduled_at, duration_minutes, status, location)
     VALUES (?,?,?,?,?,?,?,?)`
  );
  const round1Apps = applicationIds.filter((a) =>
    ['round1', 'round2', 'offer', 'onboarded'].includes(a.stage)
  );
  round1Apps.slice(0, 8).forEach((app, i) => {
    insertInterview.run(
      uuid(),
      app.id,
      interviewer1Id,
      i % 2 === 0 ? 'round1' : 'round2',
      daysFromNow(i + 1),
      60,
      i % 3 === 0 ? 'completed' : 'scheduled',
      '总部 A 座 3F'
    );
  });

  const insertOffer = db.prepare(
    `INSERT INTO offers (id, application_id, job_id, salary, bonus, status, needs_approval, created_by, approved_by, approved_at)
     VALUES (?,?,?,?,?,?,?,?,?,?)`
  );
  const offerApps = applicationIds.filter((a) => ['offer', 'onboarded'].includes(a.stage));
  offerApps.forEach((app, i) => {
    const application = db.prepare('SELECT * FROM applications WHERE id = ?').get(app.id);
    const job = db.prepare('SELECT * FROM jobs WHERE id = ?').get(application.job_id);
    const overBand = i === 0;
    const salary = overBand ? job.salary_max + 3000 : job.salary_max - 1000;
    insertOffer.run(
      uuid(),
      app.id,
      application.job_id,
      salary,
      5000,
      overBand ? 'pending_approval' : 'approved',
      overBand ? 1 : 0,
      hrId,
      overBand ? null : managerId,
      overBand ? null : daysAgo(1)
    );
  });

  const insertNotif = db.prepare(
    'INSERT INTO notifications (id, user_id, title, body, type, read_flag, created_at) VALUES (?,?,?,?,?,?,?)'
  );
  [hrId, managerId, interviewer1Id, candidate1Id].forEach((uid, i) => {
    insertNotif.run(uuid(), uid, '系统通知', '欢迎使用 HR 招聘系统', 'system', 0, daysAgo(i));
  });
  insertNotif.run(uuid(), managerId, 'Offer 待审批', '有 Offer 薪资超出 band 待您审批', 'offer_approval', 0, daysAgo(0));

  console.log('HR recruit seed completed');
  console.log(`  jobs: ${jobIds.length}, applications: ${appIndex}`);
}

module.exports = { seed };

if (require.main === module) seed();
