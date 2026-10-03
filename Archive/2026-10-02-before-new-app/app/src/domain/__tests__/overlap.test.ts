import { findOverlaps, overlappingShiftIds, shiftsOverlap } from '../overlap';
import type { Shift } from '../types';

const shift = (overrides: Partial<Shift>): Shift => ({
  id: 'id',
  employerId: 'e1',
  date: '2026-07-17',
  startMin: 17 * 60,
  endMin: 23 * 60,
  breaks: [],
  hourlyRateSnapshot: 1500,
  status: 'planned',
  ...overrides,
});

describe('shiftsOverlap', () => {
  it('detects same-day overlap across employers', () => {
    expect(
      shiftsOverlap(
        { date: '2026-07-17', startMin: 17 * 60, endMin: 23 * 60 },
        { date: '2026-07-17', startMin: 22 * 60, endMin: 23 * 60 + 30 }
      )
    ).toBe(true);
  });

  it('back-to-back shifts do not overlap', () => {
    expect(
      shiftsOverlap(
        { date: '2026-07-17', startMin: 9 * 60, endMin: 17 * 60 },
        { date: '2026-07-17', startMin: 17 * 60, endMin: 23 * 60 }
      )
    ).toBe(false);
  });

  it('different days do not overlap', () => {
    expect(
      shiftsOverlap(
        { date: '2026-07-17', startMin: 17 * 60, endMin: 23 * 60 },
        { date: '2026-07-18', startMin: 17 * 60, endMin: 23 * 60 }
      )
    ).toBe(false);
  });

  it('an overnight shift overlaps the next morning shift it spills into', () => {
    expect(
      shiftsOverlap(
        { date: '2026-07-17', startMin: 18 * 60, endMin: 1440 + 120 }, // 18:00–02:00 (+1)
        { date: '2026-07-18', startMin: 60, endMin: 9 * 60 } // 01:00–09:00
      )
    ).toBe(true);
  });

  it('an overnight shift does not overlap a later next-day shift', () => {
    expect(
      shiftsOverlap(
        { date: '2026-07-17', startMin: 18 * 60, endMin: 20 }, // 18:00–00:20 (+1)
        { date: '2026-07-18', startMin: 9 * 60, endMin: 17 * 60 }
      )
    ).toBe(false);
  });
});

describe('findOverlaps', () => {
  const existing = [
    shift({ id: 'a', employerId: 'e1', startMin: 17 * 60, endMin: 23 * 60 }),
    shift({ id: 'b', employerId: 'e2', date: '2026-07-18' }),
    shift({ id: 'c', employerId: 'e2', startMin: 18 * 60, endMin: 22 * 60, status: 'cancelled' }),
  ];

  it('returns overlapping shifts from other employers', () => {
    const hits = findOverlaps(
      { date: '2026-07-17', startMin: 22 * 60, endMin: 23 * 60 + 59 },
      existing
    );
    expect(hits.map((s) => s.id)).toEqual(['a']);
  });

  it('excludes the shift being edited (same id)', () => {
    const hits = findOverlaps(
      { id: 'a', date: '2026-07-17', startMin: 17 * 60, endMin: 23 * 60 },
      existing
    );
    expect(hits).toHaveLength(0);
  });

  it('ignores missed/cancelled shifts', () => {
    const hits = findOverlaps(
      { date: '2026-07-17', startMin: 18 * 60, endMin: 19 * 60 },
      [existing[2]]
    );
    expect(hits).toHaveLength(0);
  });
});

describe('overlappingShiftIds', () => {
  it('flags every shift involved in an overlap, across employers', () => {
    const ids = overlappingShiftIds([
      shift({ id: 'a', employerId: 'e1', startMin: 17 * 60, endMin: 23 * 60 }),
      shift({ id: 'b', employerId: 'e2', startMin: 22 * 60, endMin: 23 * 60 + 30 }),
      shift({ id: 'c', employerId: 'e1', date: '2026-07-18' }),
    ]);
    expect(ids).toEqual(new Set(['a', 'b']));
  });

  it('never flags missed/cancelled shifts', () => {
    const ids = overlappingShiftIds([
      shift({ id: 'a', status: 'missed' }),
      shift({ id: 'b', startMin: 18 * 60, endMin: 22 * 60 }),
    ]);
    expect(ids.size).toBe(0);
  });
});
