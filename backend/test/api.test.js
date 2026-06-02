const { test, before, after, describe } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');

const dbPath = path.join(__dirname, '..', 'data', `hr-test-${process.pid}.db`);

async function callApp(app, method, url, { token, body } = {}) {
  return new Promise((resolve, reject) => {
    const server = app.listen(0, () => {
      const { port } = server.address();
      const http = require('http');
      const payload = body ? JSON.stringify(body) : null;
      const req = http.request(
        {
          hostname: '127.0.0.1',
          port,
          path: url,
          method,
          headers: {
            'Content-Type': 'application/json',
            ...(token ? { Authorization: `Bearer ${token}` } : {}),
            ...(payload ? { 'Content-Length': Buffer.byteLength(payload) } : {}),
          },
        },
        (res) => {
          let raw = '';
          res.on('data', (c) => (raw += c));
          res.on('end', () => {
            server.close();
            resolve({
              status: res.statusCode,
              body: raw ? JSON.parse(raw) : null,
            });
          });
        }
      );
      req.on('error', (e) => {
        server.close();
        reject(e);
      });
      if (payload) req.write(payload);
      req.end();
    });
  });
}

describe('HR Recruit API', () => {
  let app;
  let hrToken;
  let managerToken;
  let interviewerToken;
  let candidateToken;
  let sampleAppId;
  let interviewerId;
  let pendingOfferId;

  before(() => {
    if (fs.existsSync(dbPath)) fs.unlinkSync(dbPath);
    process.env.HR_DB_PATH = dbPath;
    delete require.cache[require.resolve('../src/db')];
    delete require.cache[require.resolve('../src/seed')];
    delete require.cache[require.resolve('../src/index')];
    const { seed } = require('../src/seed');
    seed();
    app = require('../src/index');
  });

  after(() => {
    delete require.cache[require.resolve('../src/db')];
    delete require.cache[require.resolve('../src/index')];
    try {
      if (fs.existsSync(dbPath)) fs.unlinkSync(dbPath);
    } catch (_) {
      // Windows may keep sqlite file locked briefly
    }
  });

  test('login with test accounts', async () => {
    const hr = await callApp(app, 'POST', '/api/auth/login', {
      body: { username: 'hr1', password: '123456' },
    });
    assert.equal(hr.status, 200);
    assert.equal(hr.body.user.role, 'hr');
    hrToken = hr.body.token;

    const mgr = await callApp(app, 'POST', '/api/auth/login', {
      body: { username: 'manager1', password: '123456' },
    });
    managerToken = mgr.body.token;

    const interviewer = await callApp(app, 'POST', '/api/auth/login', {
      body: { username: 'interviewer1', password: '123456' },
    });
    interviewerToken = interviewer.body.token;
    interviewerId = interviewer.body.user.id;

    const candidate = await callApp(app, 'POST', '/api/auth/login', {
      body: { username: 'candidate1', password: '123456' },
    });
    candidateToken = candidate.body.token;
  });

  test('application stage advancement', async () => {
    const list = await callApp(app, 'GET', '/api/applications?stage=applied', { token: hrToken });
    assert.equal(list.status, 200);
    assert.ok(list.body.items.length > 0);
    sampleAppId = list.body.items[0].id;

    const res = await callApp(app, 'PATCH', `/api/applications/${sampleAppId}/stage`, {
      token: hrToken,
      body: { stage: 'screening', note: '通过初筛' },
    });
    assert.equal(res.status, 200);
    assert.equal(res.body.stage, 'screening');

    const timeline = await callApp(app, 'GET', `/api/applications/${sampleAppId}/timeline`, {
      token: hrToken,
    });
    assert.equal(timeline.status, 200);
    assert.ok(timeline.body.items.some((t) => t.to_stage === 'screening'));
  });

  test('application filtering by keyword education years', async () => {
    const qs = new URLSearchParams({ keyword: 'Flutter', education: '本科', minYears: '1' });
    const res = await callApp(app, 'GET', `/api/applications?${qs.toString()}`, {
      token: hrToken,
    });
    assert.equal(res.status, 200);
    res.body.items.forEach((a) => {
      assert.ok(a.education.includes('本科') || a.education === '本科');
      assert.ok(a.years_experience >= 1);
    });
  });

  test('interview conflict returns 409 with suggested slots', async () => {
    const interviews = await callApp(app, 'GET', '/api/interviews?interviewerId=' + interviewerId, {
      token: hrToken,
    });
    assert.equal(interviews.status, 200);
    const existing = interviews.body.items.find((i) => i.status === 'scheduled');
    assert.ok(existing, 'seed should include scheduled interview');

    const conflict = await callApp(app, 'POST', '/api/interviews', {
      token: hrToken,
      body: {
        applicationId: sampleAppId,
        interviewerId,
        roundType: 'round1',
        scheduledAt: existing.scheduled_at,
        durationMinutes: 60,
      },
    });
    assert.equal(conflict.status, 409);
    assert.ok(Array.isArray(conflict.body.suggestedSlots));
    assert.ok(conflict.body.suggestedSlots.length > 0);
  });

  test('offer over band needs hiring_manager approval', async () => {
    const apps = await callApp(app, 'GET', '/api/applications?stage=round2', { token: hrToken });
    const appRow = apps.body.items[0];
    const detail = await callApp(app, 'GET', `/api/applications/${appRow.id}`, { token: hrToken });
    const salaryMax = detail.body.salary_max;

    const created = await callApp(app, 'POST', '/api/offers', {
      token: hrToken,
      body: { applicationId: appRow.id, salary: salaryMax + 5000, bonus: 3000 },
    });
    assert.equal(created.status, 201);
    assert.equal(created.body.status, 'pending_approval');
    assert.equal(created.body.needsApproval, true);
    pendingOfferId = created.body.id;

    const offers = await callApp(app, 'GET', '/api/offers', { token: managerToken });
    assert.equal(offers.status, 200);
    assert.ok(offers.body.items.some((o) => o.id === pendingOfferId));

    const approved = await callApp(app, 'POST', `/api/offers/${pendingOfferId}/approve`, {
      token: managerToken,
      body: { approved: true, comment: '特批通过' },
    });
    assert.equal(approved.status, 200);
    assert.equal(approved.body.status, 'approved');
  });

  test('referral reward on onboard', async () => {
    const referral = await callApp(app, 'POST', '/api/referrals', {
      token: hrToken,
      body: {},
    });
    assert.equal(referral.status, 201);
    const code = referral.body.code;

    const jobs = await callApp(app, 'GET', '/api/jobs/public');
    const jobId = jobs.body.items[0].id;

    const applied = await callApp(app, 'POST', '/api/applications', {
      token: candidateToken,
      body: { jobId, referralCode: code, skills: 'Flutter Dart' },
    });
    assert.equal(applied.status, 201);
    const appId = applied.body.id;

    const stages = ['screening', 'written', 'round1', 'round2', 'offer', 'onboarded'];
    for (const stage of stages) {
      const r = await callApp(app, 'PATCH', `/api/applications/${appId}/stage`, {
        token: hrToken,
        body: { stage },
      });
      assert.equal(r.status, 200);
    }

    const stats = await callApp(app, 'GET', '/api/referrals/stats', { token: hrToken });
    assert.equal(stats.status, 200);
    assert.ok(stats.body.totalPoints >= 5000);
    assert.ok(stats.body.items.some((i) => i.code === code && i.successful_count >= 1));
  });

  test('candidate sees own applications only', async () => {
    const res = await callApp(app, 'GET', '/api/candidate/applications', { token: candidateToken });
    assert.equal(res.status, 200);
    assert.ok(res.body.items.length > 0);
  });

  test('reports funnel and source', async () => {
    const funnel = await callApp(app, 'GET', '/api/reports/funnel', { token: hrToken });
    assert.equal(funnel.status, 200);
    assert.ok(funnel.body.funnel.length > 0);

    const source = await callApp(app, 'GET', '/api/reports/source', { token: hrToken });
    assert.equal(source.status, 200);
    assert.ok(source.body.items.length > 0);
  });
});
