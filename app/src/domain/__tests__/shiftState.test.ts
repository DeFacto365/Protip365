import { ALLOWED_SHIFT_TRANSITIONS, assertShiftTransition, canTransitionShift } from '../shiftState';

describe('shift lifecycle state machine', () => {
  it('allows only planned completion and not-worked transitions', () => {
    expect(ALLOWED_SHIFT_TRANSITIONS.planned).toEqual(['worked', 'missed', 'cancelled']);
    expect(canTransitionShift('planned', 'worked')).toBe(true);
    expect(canTransitionShift('planned', 'missed')).toBe(true);
    expect(canTransitionShift('planned', 'cancelled')).toBe(true);
    expect(canTransitionShift('planned', 'planned')).toBe(false);
  });

  it('requires explicit confirmation for worked-to-planned correction', () => {
    expect(canTransitionShift('worked', 'planned')).toBe(false);
    expect(canTransitionShift('worked', 'planned', { confirmedCorrection: true })).toBe(true);
  });

  it('rejects terminal-state and cross-terminal transitions', () => {
    expect(() => assertShiftTransition('missed', 'worked')).toThrow('invalid_shift_transition');
    expect(() => assertShiftTransition('cancelled', 'planned')).toThrow('invalid_shift_transition');
    expect(() => assertShiftTransition('worked', 'missed')).toThrow('invalid_shift_transition');
  });
});
