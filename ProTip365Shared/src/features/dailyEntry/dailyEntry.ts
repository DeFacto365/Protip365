import { calculateShift, ShiftRecord, TipOut } from "../../domain";

export type DailyEntryForm = {
  id?: string;
  date: string;
  startTime: string;
  endTime: string;
  hours: string;
  sales: string;
  cashTips: string;
  cardTips: string;
  tipOutName: string;
  tipOutValue: string;
  tipOutBasis: "sales" | "tips";
  tipOutMethod: "percentage" | "fixed";
  otherIncome: string;
  hourlyRate: string;
  notes: string;
};

export type DailyEntryValidation = Partial<Record<keyof DailyEntryForm, string>>;

const localUserId = "local-user";

export function todayISO() {
  return new Date().toISOString().slice(0, 10);
}

export function createDefaultDailyEntryForm(): DailyEntryForm {
  return {
    cardTips: "",
    cashTips: "",
    date: todayISO(),
    endTime: "",
    hourlyRate: "",
    hours: "",
    otherIncome: "",
    sales: "",
    startTime: "",
    tipOutBasis: "sales",
    tipOutMethod: "percentage",
    tipOutName: "Tip-out",
    tipOutValue: "",
    notes: "",
  };
}

function parseAmount(value: string) {
  const normalized = value.trim().replace(",", ".");
  if (normalized === "") {
    return 0;
  }

  const parsed = Number(normalized);
  return Number.isFinite(parsed) ? parsed : Number.NaN;
}

function validateAmount(value: string, field: keyof DailyEntryForm, errors: DailyEntryValidation, required = false) {
  if (required && value.trim() === "") {
    errors[field] = "Required";
    return;
  }

  const parsed = parseAmount(value);
  if (Number.isNaN(parsed) || parsed < 0) {
    errors[field] = "Enter a valid positive number";
  }
}

export function validateDailyEntry(form: DailyEntryForm): DailyEntryValidation {
  const errors: DailyEntryValidation = {};

  if (!/^\d{4}-\d{2}-\d{2}$/.test(form.date)) {
    errors.date = "Use YYYY-MM-DD";
  }

  validateAmount(form.hours, "hours", errors, true);
  validateAmount(form.sales, "sales", errors);
  validateAmount(form.cashTips, "cashTips", errors);
  validateAmount(form.cardTips, "cardTips", errors);
  validateAmount(form.tipOutValue, "tipOutValue", errors);
  validateAmount(form.otherIncome, "otherIncome", errors);
  validateAmount(form.hourlyRate, "hourlyRate", errors, true);

  return errors;
}

export function hasValidationErrors(errors: DailyEntryValidation) {
  return Object.keys(errors).length > 0;
}

export function buildShiftRecordFromDailyEntry(form: DailyEntryForm): ShiftRecord {
  const shiftId = form.id ?? `shift-${Date.now()}`;
  const tipOuts: TipOut[] =
    parseAmount(form.tipOutValue) > 0
      ? [
          {
            basis: form.tipOutBasis,
            id: `${shiftId}-tipout-1`,
            method: form.tipOutMethod,
            name: form.tipOutName.trim() || "Tip-out",
            value: parseAmount(form.tipOutValue),
          },
        ]
      : [];

  return {
    entry: {
      actualEndTime: form.endTime || undefined,
      actualHours: parseAmount(form.hours),
      actualStartTime: form.startTime || undefined,
      id: `entry-${shiftId}`,
      otherIncome: parseAmount(form.otherIncome),
      sales: parseAmount(form.sales),
      shiftId,
      tipOuts,
      tips: {
        card: parseAmount(form.cardTips),
        cash: parseAmount(form.cashTips),
      },
      userId: localUserId,
      notes: form.notes.trim() || undefined,
    },
    plannedShift: {
      endTime: form.endTime || "00:00",
      hourlyRate: parseAmount(form.hourlyRate),
      id: shiftId,
      shiftDate: form.date,
      startTime: form.startTime || "00:00",
      status: "completed",
      userId: localUserId,
      notes: form.notes.trim() || undefined,
    },
  };
}

export function formFromShiftRecord(record: ShiftRecord): DailyEntryForm {
  const calculation = calculateShift(record);
  const firstTipOut = record.entry?.tipOuts?.[0];

  return {
    cardTips: String(calculation.cardTips || ""),
    cashTips: String(calculation.cashTips || ""),
    date: record.plannedShift.shiftDate,
    endTime: record.entry?.actualEndTime ?? record.plannedShift.endTime,
    hourlyRate: String(record.entry?.hourlyRateSnapshot ?? record.plannedShift.hourlyRate),
    hours: String(calculation.hours || ""),
    id: record.plannedShift.id,
    notes: record.entry?.notes ?? record.plannedShift.notes ?? "",
    otherIncome: String(calculation.otherIncome || ""),
    sales: String(calculation.sales || ""),
    startTime: record.entry?.actualStartTime ?? record.plannedShift.startTime,
    tipOutBasis: firstTipOut?.basis ?? "sales",
    tipOutMethod: firstTipOut?.method ?? "percentage",
    tipOutName: firstTipOut?.name ?? "Tip-out",
    tipOutValue: firstTipOut ? String(firstTipOut.value) : "",
  };
}

export function previewDailyEntry(form: DailyEntryForm) {
  if (hasValidationErrors(validateDailyEntry(form))) {
    return null;
  }

  return calculateShift(buildShiftRecordFromDailyEntry(form));
}
