import { calculatePlannedHours, PlannedShift, ShiftRecord } from "../../domain";

export type PlannedShiftForm = {
  id?: string;
  date: string;
  startTime: string;
  endTime: string;
  expectedHours: string;
  employerName: string;
  hourlyRate: string;
  reminderEnabled: boolean;
  notes: string;
};

export type PlannedShiftValidation = Partial<Record<keyof PlannedShiftForm, string>>;

const localUserId = "local-user";

export function todayISO() {
  return new Date().toISOString().slice(0, 10);
}

export function createDefaultPlannedShiftForm(): PlannedShiftForm {
  return {
    date: todayISO(),
    employerName: "",
    endTime: "",
    expectedHours: "",
    hourlyRate: "",
    reminderEnabled: false,
    startTime: "",
    notes: "",
  };
}

function parseDecimal(value: string) {
  const normalized = value.trim().replace(",", ".");
  if (normalized === "") {
    return undefined;
  }

  const parsed = Number(normalized);
  return Number.isFinite(parsed) ? parsed : Number.NaN;
}

function isLocalTime(value: string) {
  return /^([01]\d|2[0-3]):[0-5]\d$/.test(value);
}

function validateOptionalDecimal(value: string, field: keyof PlannedShiftForm, errors: PlannedShiftValidation) {
  const parsed = parseDecimal(value);
  if (Number.isNaN(parsed) || (parsed !== undefined && parsed < 0)) {
    errors[field] = "Enter a valid positive number";
  }
}

export function validatePlannedShift(form: PlannedShiftForm): PlannedShiftValidation {
  const errors: PlannedShiftValidation = {};

  if (!/^\d{4}-\d{2}-\d{2}$/.test(form.date)) {
    errors.date = "Use YYYY-MM-DD";
  }

  if (!isLocalTime(form.startTime)) {
    errors.startTime = "Use HH:MM";
  }

  if (!isLocalTime(form.endTime)) {
    errors.endTime = "Use HH:MM";
  }

  if (form.hourlyRate.trim() === "") {
    errors.hourlyRate = "Required";
  } else {
    validateOptionalDecimal(form.hourlyRate, "hourlyRate", errors);
  }

  validateOptionalDecimal(form.expectedHours, "expectedHours", errors);

  return errors;
}

export function hasPlannedShiftValidationErrors(errors: PlannedShiftValidation) {
  return Object.keys(errors).length > 0;
}

export function buildRecordFromPlannedShift(form: PlannedShiftForm): ShiftRecord {
  const shiftId = form.id ?? `planned-${Date.now()}`;
  const expectedHours = parseDecimal(form.expectedHours);
  const employerName = form.employerName.trim();
  const plannedShift: PlannedShift = {
    endTime: form.endTime,
    expectedHours: expectedHours === undefined ? undefined : expectedHours,
    hourlyRate: parseDecimal(form.hourlyRate) ?? 0,
    id: shiftId,
    shiftDate: form.date,
    startTime: form.startTime,
    status: "planned",
    userId: localUserId,
    notes: form.notes.trim() || undefined,
  };

  return {
    employer: employerName
      ? {
          active: true,
          hourlyRate: plannedShift.hourlyRate,
          id: `${shiftId}-employer`,
          name: employerName,
          userId: localUserId,
        }
      : undefined,
    plannedShift,
  };
}

export function formFromPlannedShiftRecord(record: ShiftRecord): PlannedShiftForm {
  return {
    date: record.plannedShift.shiftDate,
    employerName: record.employer?.name ?? "",
    endTime: record.plannedShift.endTime,
    expectedHours: record.plannedShift.expectedHours ? String(record.plannedShift.expectedHours) : "",
    hourlyRate: String(record.plannedShift.hourlyRate || ""),
    id: record.plannedShift.id,
    reminderEnabled: false,
    startTime: record.plannedShift.startTime,
    notes: record.plannedShift.notes ?? "",
  };
}

export function previewPlannedHours(form: PlannedShiftForm) {
  const errors = validatePlannedShift(form);
  if (hasPlannedShiftValidationErrors(errors)) {
    return null;
  }

  const record = buildRecordFromPlannedShift(form);
  return calculatePlannedHours(record.plannedShift);
}
