import {
  combineResults,
  validateDeductionBasisPoints,
  validateHourlyRateCents,
  validateMoney,
  validateShiftWindow,
} from '../validate';
import type { ShiftBreak } from '../types';

const brk = (
  startMin: number,
  durationMin: number,
  paid = false,
  label = 'Break'
): ShiftBreak => ({ label, startMin, durationMin, paid });

describe('validateShiftWindow — times', () => {
  it('accepts a normal same-day window', () => {
    const r = validateShiftWindow({ startMin: 540, endMin: 1020, breaks: [] });
    expect(r.valid).toBe(true);
    expect(r.errors).toEqual([]);
  });

  it('accepts an overnight window (18:00–00:20)', () => {
    const r = validateShiftWindow({ startMin: 18 * 60, endMin: 20, breaks: [] });
    expect(r.valid).toBe(true);
  });

  it('rejects end equal to start', () => {
    const r = validateShiftWindow({ startMin: 600, endMin: 600, breaks: [] });
    expect(r.valid).toBe(false);
    expect(r.errors).toContain('end_not_after_start');
  });
});

describe('validateShiftWindow — breaks', () => {
  const startMin = 18 * 60;
  const endMin = 20; // overnight → normalized 1460

  it('accepts a break inside the window', () => {
    const r = validateShiftWindow({ startMin, endMin, breaks: [brk(21 * 60, 30)] });
    expect(r.valid).toBe(true);
  });

  it('accepts an after-midnight break on an overnight shift', () => {
    // 00:05, expressed as 5 minutes from midnight — before the 18:00 start numerically.
    const r = validateShiftWindow({ startMin, endMin, breaks: [brk(5, 10)] });
    expect(r.valid).toBe(true);
  });

  it('rejects a break that starts before the shift', () => {
    const r = validateShiftWindow({
      startMin: 9 * 60,
      endMin: 17 * 60,
      breaks: [brk(8 * 60, 30)],
    });
    expect(r.valid).toBe(false);
    expect(r.errors).toContain('break_outside_shift');
  });

  it('rejects a break that runs past the end of the shift', () => {
    const r = validateShiftWindow({
      startMin: 9 * 60,
      endMin: 17 * 60,
      breaks: [brk(16 * 60 + 45, 30)],
    });
    expect(r.valid).toBe(false);
    expect(r.errors).toContain('break_outside_shift');
  });

  it('rejects overlapping breaks', () => {
    const r = validateShiftWindow({
      startMin: 9 * 60,
      endMin: 17 * 60,
      breaks: [brk(12 * 60, 45), brk(12 * 60 + 30, 30)],
    });
    expect(r.valid).toBe(false);
    expect(r.errors).toContain('breaks_overlap');
  });

  it('accepts back-to-back breaks (touching, not overlapping)', () => {
    const r = validateShiftWindow({
      startMin: 9 * 60,
      endMin: 17 * 60,
      breaks: [brk(12 * 60, 30), brk(12 * 60 + 30, 15)],
    });
    expect(r.valid).toBe(true);
  });

  it('rejects zero or negative break durations', () => {
    const r = validateShiftWindow({
      startMin: 9 * 60,
      endMin: 17 * 60,
      breaks: [brk(12 * 60, 0)],
    });
    expect(r.valid).toBe(false);
    expect(r.errors).toContain('break_negative_duration');
  });

  it('rejects total unpaid break time exceeding the shift duration', () => {
    // 1h shift, breaks unpaid 40 + 40 = 80 > 60 (each fits partially → also outside)
    const r = validateShiftWindow({
      startMin: 600,
      endMin: 660,
      breaks: [brk(600, 40), brk(640, 40)],
    });
    expect(r.valid).toBe(false);
    expect(r.errors).toContain('unpaid_breaks_exceed_shift');
  });

  it('paid breaks never trigger the unpaid-exceeds check', () => {
    const r = validateShiftWindow({
      startMin: 600,
      endMin: 660,
      breaks: [brk(600, 60, true)],
    });
    expect(r.valid).toBe(true);
  });
});

describe('validateMoney', () => {
  it('accepts non-negative and missing amounts', () => {
    const r = validateMoney({ directTips: 0, tipOutPaid: 1250, sales: null, other: undefined });
    expect(r.valid).toBe(true);
  });

  it('rejects negative amounts', () => {
    const r = validateMoney({ directTips: -1 });
    expect(r.valid).toBe(false);
    expect(r.errors).toContain('negative_amount');
  });

  it('rejects NaN amounts', () => {
    const r = validateMoney({ directTips: Number.NaN });
    expect(r.valid).toBe(false);
  });
});

describe('combineResults', () => {
  it('merges and dedupes errors', () => {
    const combined = combineResults(
      validateShiftWindow({ startMin: 600, endMin: 600, breaks: [] }),
      validateMoney({ tips: -5 })
    );
    expect(combined.valid).toBe(false);
    expect(combined.errors.sort()).toEqual(['end_not_after_start', 'negative_amount']);
  });
});

describe('rate and deduction validation', () => {
  it('rejects zero, negative, fractional-cent, and missing hourly rates', () => {
    expect(validateHourlyRateCents(1).valid).toBe(true);
    expect(validateHourlyRateCents(0).errors).toEqual(['rate_not_positive']);
    expect(validateHourlyRateCents(-1).valid).toBe(false);
    expect(validateHourlyRateCents(1000.5).valid).toBe(false);
    expect(validateHourlyRateCents(null).valid).toBe(false);
  });

  it('accepts only integer deduction basis points from 0 through 10000', () => {
    expect(validateDeductionBasisPoints(0).valid).toBe(true);
    expect(validateDeductionBasisPoints(10000).valid).toBe(true);
    expect(validateDeductionBasisPoints(-1).errors).toEqual(['deduction_out_of_range']);
    expect(validateDeductionBasisPoints(10001).valid).toBe(false);
  });
});
