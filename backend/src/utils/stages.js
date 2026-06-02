const STAGES = ['applied', 'screening', 'written', 'round1', 'round2', 'offer', 'onboarded'];
const TERMINAL_STAGES = ['onboarded', 'rejected'];

const STAGE_LABELS = {
  applied: '投递',
  screening: '筛选',
  written: '笔试',
  round1: '一面',
  round2: '二面',
  offer: 'Offer',
  onboarded: '入职',
  rejected: '淘汰',
};

const STAGE_ORDER = [...STAGES, 'rejected'];

function stageIndex(stage) {
  return STAGE_ORDER.indexOf(stage);
}

function canMoveStage(from, to, role) {
  if (!STAGE_ORDER.includes(from) || !STAGE_ORDER.includes(to)) return false;
  if (from === to) return true;
  if (to === 'rejected') return role === 'hr' || role === 'hiring_manager';
  if (from === 'rejected' || from === 'onboarded') return false;

  const fromIdx = stageIndex(from);
  const toIdx = stageIndex(to);
  if (toIdx < fromIdx) return role === 'hr' || role === 'hiring_manager';
  if (to === 'onboarded' && from !== 'offer') return false;
  return role === 'hr' || role === 'hiring_manager';
}

function nextStage(stage) {
  const idx = STAGES.indexOf(stage);
  if (idx === -1 || idx >= STAGES.length - 1) return null;
  return STAGES[idx + 1];
}

function funnelStages() {
  return STAGES;
}

module.exports = {
  STAGES,
  TERMINAL_STAGES,
  STAGE_LABELS,
  STAGE_ORDER,
  stageIndex,
  canMoveStage,
  nextStage,
  funnelStages,
};
