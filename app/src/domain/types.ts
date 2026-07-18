/**
 * Domain types for ProTip365 V4 MVP.
 * Pure TypeScript — no React Native or database imports.
 */

export type ShiftStatus = 'scheduled' | 'worked' | 'missed' | 'cancelled';

export type TipMethod = 'direct' | 'pooled' | 'mixed';

/**
 * Canonical not-worked reason codes (stored untranslated).
 * `employer_cancelled` maps the shift to status `cancelled`;
 * every other code maps to `missed`. `other` requires a note.
 */
export type NotWorkedReason =
  | 'sick'
  | 'employer_cancelled'
  | 'personal'
  | 'emergency'
  | 'schedule_conflict'
  | 'weather_or_transportation'
  | 'other';

/** Canonical PRD §9 ordering, for pickers. */
export const NOT_WORKED_REASONS: readonly NotWorkedReason[] = [
  'sick',
  'employer_cancelled',
  'personal',
  'emergency',
  'schedule_conflict',
  'weather_or_transportation',
  'other',
];

export type PayoutStatus =
  | 'not_expected'
  | 'pending'
  | 'partially_received'
  | 'received'
  | 'disputed';

export interface Employer {
  id: string;
  name: string;
  /** Hex color from the employer palette. */
  color: string;
  /** Estimated deduction rate as a fraction (0–1). */
  deductionRate: number;
}

export interface Role {
  id: string;
  employerId: string;
  name: string;
  hourlyRate: number;
}

export interface ShiftBreak {
  label: string;
  /** Minutes from midnight of the shift date; may exceed 1440 for overnight shifts. */
  startMin: number;
  durationMin: number;
  paid: boolean;
}

export interface Shift {
  id: string;
  employerId: string;
  roleId?: string | null;

  // ---- Scheduled (plan) fields ----
  /** Work date, ISO `YYYY-MM-DD`. */
  date: string;
  /** Scheduled start, minutes from midnight (0–1439). */
  startMin: number;
  /** Scheduled end, minutes from midnight; may exceed 1440 for overnight shifts. */
  endMin: number;
  breaks: ShiftBreak[];
  /** Hourly rate snapshotted at scheduling time. */
  hourlyRateSnapshot: number;
  status: ShiftStatus;
  /** Required reason code when status is `missed` or `cancelled`. */
  notWorkedReason?: NotWorkedReason | null;
  /** Free-text note; required when the reason code is `other`. */
  notWorkedNote?: string | null;

  // ---- Actual (completion) fields ----
  actualStartMin?: number | null;
  actualEndMin?: number | null;
  actualBreaks?: ShiftBreak[] | null;
  tipMethod?: TipMethod | null;
  directTips?: number;
  poolContribution?: number;
  tipShareReceived?: number;
  tipOutPaid?: number;
  sales?: number | null;
  otherIncome?: number;
  /** Deduction rate snapshotted at completion, as a fraction (0–1). */
  deductionRateSnapshot?: number;
  expectedPayout?: number;
  actualReceived?: number;
  payoutStatus?: PayoutStatus;
  notes?: string | null;

  createdAt?: string;
  updatedAt?: string;
}

/** Fields written by the one-transaction completion operation. */
export interface ShiftActualsInput {
  actualStartMin: number;
  actualEndMin: number;
  actualBreaks: ShiftBreak[];
  tipMethod: TipMethod;
  directTips: number;
  poolContribution: number;
  tipShareReceived: number;
  tipOutPaid: number;
  sales?: number | null;
  otherIncome?: number;
  deductionRateSnapshot: number;
  expectedPayout: number;
  actualReceived: number;
  payoutStatus: PayoutStatus;
  notes?: string | null;
}
