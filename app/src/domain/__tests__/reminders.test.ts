import {
  isActualsPending,
  parseReminderDelayHours,
  reminderDate,
  scheduledEndDate,
} from '../reminders';
import type { Shift } from '../types';

const shift = (overrides: Partial<Shift> = {}): Shift => ({
  id: 'shift',
  employerId: 'employer',
  date: '2026-07-17',
  startMin: 18 * 60,
  endMin: 23 * 60,
  breaks: [],
  hourlyRateSnapshot: 2000,
  status: 'planned',
  ...overrides,
});

describe('post-shift reminders', () => {
  it('defaults to two hours after the scheduled end', () => {
    const end = scheduledEndDate(shift());
    expect(reminderDate(shift()).getTime() - end.getTime()).toBe(120 * 60_000);
  });

  it('parses localized delays between zero and 24 hours', () => {
    expect(parseReminderDelayHours('2.5')).toBe(150);
    expect(parseReminderDelayHours('1,5')).toBe(90);
  });

  it('rejects empty, non-numeric, and out-of-range delays', () => {
    expect(parseReminderDelayHours('')).toBeNull();
    expect(parseReminderDelayHours('abc')).toBeNull();
    expect(parseReminderDelayHours('-1')).toBeNull();
    expect(parseReminderDelayHours('25')).toBeNull();
  });

  it('resolves an overnight end on the following local date', () => {
    const end = scheduledEndDate(shift({ endMin: 60 }));
    expect(end.getDate()).toBe(new Date(2026, 6, 18).getDate());
    expect(end.getHours()).toBe(1);
  });

  it('shows pending only after the delay and only while scheduled', () => {
    const due = reminderDate(shift());
    expect(isActualsPending(shift(), new Date(due.getTime() - 1))).toBe(false);
    expect(isActualsPending(shift(), due)).toBe(true);
    expect(isActualsPending(shift({ status: 'worked' }), due)).toBe(false);
  });
});
