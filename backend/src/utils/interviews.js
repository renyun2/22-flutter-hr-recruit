const db = require('../db');

const DEFAULT_DURATION = 60;
const WORK_START_HOUR = 9;
const WORK_END_HOUR = 18;
const SLOT_STEP_MINUTES = 60;

function parseTime(iso) {
  return new Date(iso).getTime();
}

function rangesOverlap(startA, endA, startB, endB) {
  return startA < endB && startB < endA;
}

function hasInterviewConflict(interviewerId, scheduledAt, durationMinutes, excludeId = null) {
  const start = parseTime(scheduledAt);
  const end = start + durationMinutes * 60 * 1000;
  let sql = `
    SELECT id, scheduled_at, duration_minutes
    FROM interviews
    WHERE interviewer_id = ? AND status = 'scheduled'
  `;
  const params = [interviewerId];
  if (excludeId) {
    sql += ' AND id != ?';
    params.push(excludeId);
  }
  const existing = db.prepare(sql).all(...params);
  return existing.some((row) => {
    const rowStart = parseTime(row.scheduled_at);
    const rowEnd = rowStart + (row.duration_minutes || DEFAULT_DURATION) * 60 * 1000;
    return rangesOverlap(start, end, rowStart, rowEnd);
  });
}

function suggestSlots(interviewerId, preferredAt, durationMinutes = DEFAULT_DURATION, count = 5) {
  const base = preferredAt ? new Date(preferredAt) : new Date();
  base.setMinutes(0, 0, 0);
  const suggestions = [];
  const durationMs = durationMinutes * 60 * 1000;

  for (let dayOffset = 0; dayOffset < 7 && suggestions.length < count; dayOffset += 1) {
    const day = new Date(base);
    day.setDate(day.getDate() + dayOffset);
    for (let hour = WORK_START_HOUR; hour < WORK_END_HOUR && suggestions.length < count; hour += 1) {
      const slot = new Date(day);
      slot.setHours(hour, 0, 0, 0);
      const slotIso = slot.toISOString();
      if (!hasInterviewConflict(interviewerId, slotIso, durationMinutes)) {
        suggestions.push({
          scheduledAt: slotIso,
          durationMinutes,
          label: `${slot.toLocaleDateString('zh-CN')} ${String(hour).padStart(2, '0')}:00`,
        });
      }
    }
  }
  return suggestions;
}

module.exports = {
  DEFAULT_DURATION,
  hasInterviewConflict,
  suggestSlots,
};
