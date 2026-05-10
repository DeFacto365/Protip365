export type CurrencyAmount = number;
export type ISODate = string;
export type LocalTime = string;

export type ShiftStatus = "planned" | "completed" | "missed" | "did_not_work";

export type TipOutMethod = "fixed" | "percentage";
export type TipOutBasis = "sales" | "tips";

export type Employer = {
  id: string;
  userId: string;
  name: string;
  hourlyRate: CurrencyAmount;
  active: boolean;
};

export type TipBreakdown = {
  cash: CurrencyAmount;
  card: CurrencyAmount;
};

export type TipOut = {
  id: string;
  name: string;
  method: TipOutMethod;
  basis: TipOutBasis;
  value: number;
};

export type PlannedShift = {
  id: string;
  userId: string;
  shiftDate: ISODate;
  employerId?: string;
  startTime: LocalTime;
  endTime: LocalTime;
  expectedHours?: number;
  hourlyRate: CurrencyAmount;
  lunchBreakMinutes?: number;
  status: ShiftStatus;
  notes?: string;
  salesTarget?: CurrencyAmount;
};

export type ShiftEntry = {
  id: string;
  shiftId: string;
  userId: string;
  actualStartTime?: LocalTime;
  actualEndTime?: LocalTime;
  actualHours?: number;
  sales?: CurrencyAmount;
  tips?: TipBreakdown;
  tipOuts?: TipOut[];
  otherIncome?: CurrencyAmount;
  hourlyRateSnapshot?: CurrencyAmount;
  grossIncomeSnapshot?: CurrencyAmount;
  totalIncomeSnapshot?: CurrencyAmount;
  netIncomeSnapshot?: CurrencyAmount;
  deductionPercentageSnapshot?: number;
  notes?: string;
};

export type ShiftRecord = {
  plannedShift: PlannedShift;
  entry?: ShiftEntry;
  employer?: Employer;
};

export type ShiftCalculation = {
  status: ShiftStatus;
  worked: boolean;
  hours: number;
  sales: CurrencyAmount;
  cashTips: CurrencyAmount;
  cardTips: CurrencyAmount;
  grossTips: CurrencyAmount;
  tipOut: CurrencyAmount;
  netTips: CurrencyAmount;
  otherIncome: CurrencyAmount;
  grossWages: CurrencyAmount;
  netWages: CurrencyAmount;
  totalIncome: CurrencyAmount;
  realHourlyRate: CurrencyAmount;
  tipPercentage: number;
};

export type ReportTotals = Omit<ShiftCalculation, "status" | "worked"> & {
  shiftCount: number;
  workedShiftCount: number;
  missedShiftCount: number;
};

export type ReportPeriodKind = "today" | "week" | "month" | "year";

export type WeekStartsOn = 0 | 1 | 2 | 3 | 4 | 5 | 6;

export type ReportPeriod = {
  kind: ReportPeriodKind;
  startDate: ISODate;
  endDate: ISODate;
  label: string;
};

export type ReportTarget = {
  income?: CurrencyAmount;
  tips?: CurrencyAmount;
  sales?: CurrencyAmount;
  hours?: number;
};

export type ReportTargetProgress = {
  income: number;
  tips: number;
  sales: number;
  hours: number;
};

export type ReportSummary = {
  period: ReportPeriod;
  records: ShiftRecord[];
  totals: ReportTotals;
  targetProgress: ReportTargetProgress;
};
