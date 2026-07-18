/**
 * Domain types for ProTip365 V4 MVP.
 * Pure TypeScript — no React Native or database imports.
 */

export type ShiftStatus = 'planned' | 'worked' | 'missed' | 'cancelled';

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
  /** Integer cents/hour. */
  defaultHourlyRate: number;
  /** Integer basis points (0-10000). */
  deductionRateBp: number;
  /** Archived employers remain available to history but not new-shift pickers. */
  archived: boolean;
}

export interface Role {
  id: string;
  employerId: string;
  name: string;
  /** Integer cents/hour. */
  hourlyRate: number;
}

export interface ScheduleTemplate {
  id: string;
  name: string;
  employerId: string;
  roleId?: string | null;
  startMin: number;
  endMin: number;
  breaks: ShiftBreak[];
  plannedExpectedTips?: number | null;
  plannedOtherIncome?: number | null;
  notes?: string | null;
  archived: boolean;
}

export interface RecurrenceRule {
  id: string;
  templateId: string;
  cadenceWeeks: 1 | 2;
  /** Monday = 0 through Sunday = 6. */
  weekdays: number[];
  startDate: string;
  endDate?: string | null;
  occurrenceCount?: number | null;
  active: boolean;
}

export type GoalMetric = 'worked_hours' | 'net_tips' | 'actual_gross' | 'estimated_net';

export interface WeeklyGoal {
  id: string;
  weekStart: string;
  metric: GoalMetric;
  /** Integer minutes for worked-hours goals; integer cents for money goals. */
  target: number;
  employerId?: string | null;
  /** Explicit user choice to carry this goal into the following week. */
  repeat: boolean;
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
  /** Integer cents/hour. */
  hourlyRateSnapshot: number;
  /** Optional planned amounts in integer cents. Null means not entered. */
  plannedExpectedTips?: number | null;
  plannedOtherIncome?: number | null;
  status: ShiftStatus;
  /** ISO timestamp of the latest lifecycle transition. */
  transitionAt?: string;
  /** Required reason code when status is `missed` or `cancelled`. */
  notWorkedReason?: NotWorkedReason | null;
  /** Free-text note; required when the reason code is `other`. */
  notWorkedNote?: string | null;

  // ---- Actual (completion) fields ----
  actualStartMin?: number | null;
  actualEndMin?: number | null;
  actualBreaks?: ShiftBreak[] | null;
  /** Integer cents/hour captured and editable at completion. */
  actualHourlyRateSnapshot?: number | null;
  tipMethod?: TipMethod | null;
  /** Monetary completion fields are integer cents. */
  directTips?: number;
  poolContribution?: number;
  tipShareReceived?: number;
  tipOutPaid?: number;
  sales?: number | null;
  otherIncome?: number;
  /** Integer basis points snapshotted at completion. */
  deductionRateSnapshotBp?: number;
  expectedPayout?: number;
  actualReceived?: number;
  payoutStatus?: PayoutStatus;
  notes?: string | null;
  /** Planned-source metadata; historical validity never depends on the source rows. */
  sourceTemplateId?: string | null;
  sourceRecurrenceRuleId?: string | null;
  /** Stable key used to make recurring generation idempotent. */
  recurrenceKey?: string | null;

  createdAt?: string;
  updatedAt?: string;
}

/** Fields written by the one-transaction completion operation. */
export interface ShiftActualsInput {
  actualStartMin: number;
  actualEndMin: number;
  actualBreaks: ShiftBreak[];
  actualHourlyRateSnapshot: number;
  tipMethod: TipMethod;
  directTips: number;
  poolContribution: number;
  tipShareReceived: number;
  tipOutPaid: number;
  sales?: number | null;
  otherIncome?: number;
  deductionRateSnapshotBp: number;
  expectedPayout: number;
  actualReceived: number;
  payoutStatus: PayoutStatus;
  notes?: string | null;
}
