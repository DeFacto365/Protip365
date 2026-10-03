import {importLegacy, LegacyArchive} from './legacy';
import {hours, net, wage, totals, inRange, validData} from './domain';
const at = '2026-10-01T12:00:00Z';
const base = {version: 1 as const, onboarded: false, jobs: [], shifts: [], settings: {language: 'en' as const, weekStart: 1, reminder: true, offset: 15, goal: null, name: ''}};
const fixture = (): LegacyArchive => ({database: 'protip365.db', userVersion: 3, tables: {
 employers: [{id: 'e', name: 'Cafe', color: '#A67B65', default_hourly_rate: 1300, archived: 0}],
 roles: [{id: 'r', employer_id: 'e', name: 'Server', hourly_rate: 1500}],
 shifts: ['worked','planned','missed','cancelled'].map((status,i) => ({id: 's'+i, employer_id: 'e', role_id: 'r', date: '2026-10-01', start_min: 1020, end_min: 90, breaks_json: '[{"durationMin":30,"paid":false}]', actual_start_min: 1020, actual_end_min: 90, actual_breaks_json: '[{"durationMin":30,"paid":false},{"durationMin":15,"paid":true}]', hourly_rate_snapshot: 1500, actual_hourly_rate_snapshot: 1600, direct_tips: 10050, tip_share_received: 2000, pool_contribution: 500, tip_out_paid: 750, other_income: 3000, sales: 90000, status, created_at: at, updated_at: at})),
 settings: [{key: 'language', value: 'fr-CA'}, {key: 'currencyCode', value: 'USD'}, {key: 'postShiftReminderEnabled', value: '1'}, {key: 'postShiftReminderDelayMinutes', value: '240'}],
 schedule_templates: [{id: 'template', arbitrary_original_column: 'preserved'}], weekly_goals: [{id:'goal',target:10000}]
}});
test('upgrade retains exact overnight earnings, paid breaks, pooled tips, other income, status and original tables', () => {
 const old = fixture(), before = JSON.stringify(old), d = importLegacy(old,base);
 expect(validData(d)).toBe(true); expect(JSON.stringify(old)).toBe(before); expect(d.legacyArchive).toEqual(old);
 expect(d.settings).toMatchObject({language:'fr',currencyCode:'USD',offset:240});
 const worked = d.shifts[0]; expect(hours(worked)).toBe(8); expect(wage(worked)).toBe(12800); expect(net(worked)).toBe(10800); expect(totals([worked]).pay).toBe(26600);
 expect(inRange(d.shifts,'2026-10-01','2026-10-01')).toEqual([worked]);
 expect(importLegacy(old,base)).toEqual(d);
});
test('actual time absent remains zero earned hours rather than inventing scheduled wages', () => {
 const old = fixture(); old.tables.shifts[0].actual_start_min = null;
 const s = importLegacy(old,base).shifts[0]; expect(hours(s)).toBe(0); expect(wage(s)).toBe(0);
});
test('incompatible/corrupt records fail closed rather than silently resetting or dropping records', () => {
 const old = fixture(); old.tables.shifts[0].employer_id = 'missing'; expect(() => importLegacy(old,base)).toThrow();
 const corrupt = fixture(); corrupt.tables.shifts[0].actual_breaks_json = '[{"durationMin":-1,"paid":false}]'; expect(() => importLegacy(corrupt,base)).toThrow();
 const schema = fixture(); delete schema.tables.employers; expect(() => importLegacy(schema,base)).toThrow();
});
