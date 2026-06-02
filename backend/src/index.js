const express = require('express');
const cors = require('cors');
const { seed } = require('./seed');

const authRoutes = require('./routes/api/auth');
const jobsRoutes = require('./routes/api/jobs');
const applicationsRoutes = require('./routes/api/applications');
const candidateRoutes = require('./routes/api/candidate');
const talentPoolRoutes = require('./routes/api/talentPool');
const interviewsRoutes = require('./routes/api/interviews');
const offersRoutes = require('./routes/api/offers');
const referralsRoutes = require('./routes/api/referrals');
const reportsRoutes = require('./routes/api/reports');
const notificationsRoutes = require('./routes/api/notifications');

seed();

const app = express();
const PORT = process.env.PORT || 3009;

app.use(cors({ origin: true }));
app.use(express.json());

app.get('/health', (_req, res) => res.json({ ok: true, service: 'hr-recruit' }));

app.use('/api/auth', authRoutes);
app.use('/api/jobs', jobsRoutes);
app.use('/api/applications', applicationsRoutes);
app.use('/api/candidate', candidateRoutes);
app.use('/api/talent-pool', talentPoolRoutes);
app.use('/api/interviews', interviewsRoutes);
app.use('/api/offers', offersRoutes);
app.use('/api/referrals', referralsRoutes);
app.use('/api/reports', reportsRoutes);
app.use('/api/notifications', notificationsRoutes);

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`HR recruit backend running at http://localhost:${PORT}`);
    console.log(`API base: http://localhost:${PORT}/api`);
  });
}

module.exports = app;
