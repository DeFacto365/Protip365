import {Data, Job, Shift, validData} from './domain';
export type LegacyArchive = {database: 'protip365.db'; userVersion: number; tables: Record<string, Record<string, unknown>[]>};
type Row = Record<string, any>;
const time = (n: number) => {if (!Number.isInteger(n) || n < 0 || n >= 1440) throw new Error('Invalid legacy time'); return `${String(Math.floor(n / 60)).padStart(2, '0')}:${String(n % 60).padStart(2, '0')}`;};
function unpaid(raw: string | null) {
  const breaks = JSON.parse(raw ?? '[]');
  if (!Array.isArray(breaks) || breaks.some(b => !b || !Number.isInteger(b.durationMin) || b.durationMin < 0 || typeof b.paid !== 'boolean')) throw new Error('Invalid legacy breaks');
  return breaks.reduce((n, b) => n + (b.paid ? 0 : b.durationMin), 0);
}
/** Convert earned amounts without interpreting other income as tips. Keep every original row in the backup. */
export function importLegacy(archive: LegacyArchive, initial: Data): Data {
  const {employers, roles, shifts, settings} = archive.tables;
  if (![employers, roles, shifts, settings].every(Array.isArray)) throw new Error('Unsupported legacy schema');
  const values = Object.fromEntries(settings.map(s => [s.key, s.value]));
  const jobs: Job[] = [];
  const jobId = (employer: string, role: string | null) => JSON.stringify([employer, role]);
  for (const e of employers as Row[]) {
    const employerRoles = (roles as Row[]).filter(r => r.employer_id === e.id);
    for (const role of [null, ...employerRoles]) {
      const sample = (shifts as Row[]).filter(s => s.employer_id === e.id && (s.role_id ?? null) === (role?.id ?? null)).sort((a,b) => String(b.updated_at).localeCompare(String(a.updated_at)))[0];
      jobs.push({id: jobId(e.id, role?.id ?? null), name: e.name, role: role?.name ?? '', rate: role?.hourly_rate ?? e.default_hourly_rate, color: e.color, archived: e.archived === 1, start: time(sample?.start_min ?? 1020), end: time(sample?.end_min ?? 1380), brk: unpaid(sample?.breaks_json ?? '[]')});
    }
  }
  const imported: Shift[] = (shifts as Row[]).map(s => {
    if (!['planned','worked','missed','cancelled'].includes(s.status)) throw new Error('Invalid legacy status');
    const worked = s.status === 'worked';
    const start = worked ? s.actual_start_min ?? s.start_min : s.start_min;
    const end = worked ? s.actual_end_min ?? s.end_min : s.end_min;
    const missingActuals = worked && (s.actual_start_min == null || s.actual_end_min == null);
    return {id: s.id, job: jobId(s.employer_id, s.role_id ?? null), date: s.date, start: time(start), end: time(end), brk: missingActuals ? (end <= start ? end + 1440 : end) - start : unpaid(worked ? s.actual_breaks_json : s.breaks_json), rate: worked ? s.actual_hourly_rate_snapshot ?? s.hourly_rate_snapshot : s.hourly_rate_snapshot, cash: s.direct_tips ?? null, card: null, tipIn: s.tip_share_received ?? null, tipOut: s.tip_out_paid == null && s.pool_contribution == null ? null : (s.tip_out_paid ?? 0) + (s.pool_contribution ?? 0), sales: s.sales ?? null, other: null, otherIncome: s.other_income ?? null, note: s.notes ?? s.not_worked_note ?? '', planned: s.status === 'planned', status: s.status, createdAt: s.created_at, updatedAt: s.updated_at};
  });
  const data: Data = {...initial, onboarded: jobs.length > 0, jobs, shifts: imported, legacyArchive: archive,
    settings: {...initial.settings, language: values.language === 'fr-CA' ? 'fr' : 'en', currencyCode: values.currencyCode ?? 'CAD', reminder: values.postShiftReminderEnabled === '1', offset: Number(values.postShiftReminderDelayMinutes ?? 120)}};
  if (!validData(data)) throw new Error('Legacy records could not be converted safely');
  return data;
}
