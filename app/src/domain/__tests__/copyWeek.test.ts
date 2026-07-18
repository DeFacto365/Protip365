import { copyWeekForward } from '../copyWeek';
import {
  addDaysIso,
  isValidIsoDate,
  minutesToHHMM,
  parseHHMM,
  startOfWeekIso,
  weekDatesIso,
} from '../dates';
import type { Shift } from '../types';

const shift = (overrides: Partial<Shift>): Shift => ({
  id: 'id',
  employerId: 'e1',
  date: '2026-07-13', // Monday
  startMin: 17 * 60,
  endMin: 23 * 60,
  breaks: [],
  hourlyRateSnapshot: 20,
  status: 'scheduled',
  ...overrides,
});

describe('date helpers', () => {
  it('validates ISO dates', () => {
    expect(isValidIsoDate('2026-07-17')).toBe(true);
    expect(isValidIsoDate('2026-02-30')).toBe(false);
    expect(isValidIsoDate('2026-7-17')).toBe(false);
  });

  it('adds days across month boundaries', () => {
    expect(addDaysIso('2026-07-28', 7)).toBe('2026-08-04');
    expect(addDaysIso('2026-01-01', -1)).toBe('2025-12-31');
  });

  it('computes Monday-based week start', () => {
    expect(startOfWeekIso('2026-07-17')).toBe('2026-07-13'); // Friday → Monday
    expect(startOfWeekIso('2026-07-13')).toBe('2026-07-13'); // Monday → itself
    expect(startOfWeekIso('2026-07-19')).toBe('2026-07-13'); // Sunday → previous Monday
  });

  it('produces seven consecutive dates', () => {
    const week = weekDatesIso('2026-07-13');
    expect(week).toHaveLength(7);
    expect(week[0]).toBe('2026-07-13');
    expect(week[6]).toBe('2026-07-19');
  });

  it('formats and parses HH:MM, wrapping overnight minutes', () => {
    expect(minutesToHHMM(17 * 60 + 5)).toBe('17:05');
    expect(minutesToHHMM(1460)).toBe('00:20');
    expect(parseHHMM('17:30')).toBe(1050);
    expect(parseHHMM('24:00')).toBeNull();
    expect(parseHHMM('9:60')).toBeNull();
    expect(parseHHMM('nonsense')).toBeNull();
  });
});

describe('copyWeekForward', () => {
  it('copies scheduled shifts to the same weekday next week', () => {
    const shifts = [
      shift({ id: 'a', date: '2026-07-13' }),
      shift({ id: 'b', date: '2026-07-17', startMin: 18 * 60, endMin: 20 }), // overnight Fri
    ];
    const copies = copyWeekForward(shifts, '2026-07-13');
    expect(copies).toHaveLength(2);
    expect(copies[0].date).toBe('2026-07-20');
    expect(copies[1].date).toBe('2026-07-24');
    expect(copies[1].startMin).toBe(18 * 60);
    expect(copies[1].endMin).toBe(20);
  });

  it('copies only shifts with status scheduled', () => {
    const shifts = [
      shift({ id: 'a', status: 'scheduled' }),
      shift({ id: 'b', status: 'worked', date: '2026-07-14' }),
      shift({ id: 'c', status: 'missed', date: '2026-07-15' }),
      shift({ id: 'd', status: 'cancelled', date: '2026-07-16' }),
    ];
    const copies = copyWeekForward(shifts, '2026-07-13');
    expect(copies).toHaveLength(1);
    expect(copies[0].date).toBe('2026-07-20');
  });

  it('ignores shifts outside the viewed week', () => {
    const shifts = [
      shift({ id: 'a', date: '2026-07-12' }), // Sunday of previous week
      shift({ id: 'b', date: '2026-07-20' }), // Monday of next week
    ];
    expect(copyWeekForward(shifts, '2026-07-13')).toHaveLength(0);
  });

  it('copies plan fields (breaks, role, rate) but never actual/completion data', () => {
    const source = shift({
      id: 'a',
      roleId: 'r1',
      breaks: [{ label: 'Lunch', startMin: 20 * 60, durationMin: 30, paid: false }],
      hourlyRateSnapshot: 22.5,
      notes: 'bring apron',
      // stale actual data on a scheduled shift must not propagate
      actualStartMin: 17 * 60,
      directTips: 99,
    });
    const [copy] = copyWeekForward([source], '2026-07-13');
    expect(copy.roleId).toBe('r1');
    expect(copy.hourlyRateSnapshot).toBe(22.5);
    expect(copy.breaks).toEqual([
      { label: 'Lunch', startMin: 20 * 60, durationMin: 30, paid: false },
    ]);
    expect(copy.notes).toBe('bring apron');
    expect('actualStartMin' in copy).toBe(false);
    expect('directTips' in copy).toBe(false);
    expect('status' in copy).toBe(false);
  });

  it('deep-copies breaks so mutating the copy never touches the source', () => {
    const source = shift({
      breaks: [{ label: 'Lunch', startMin: 20 * 60, durationMin: 30, paid: false }],
    });
    const [copy] = copyWeekForward([source], '2026-07-13');
    copy.breaks[0].durationMin = 99;
    expect(source.breaks[0].durationMin).toBe(30);
  });
});
