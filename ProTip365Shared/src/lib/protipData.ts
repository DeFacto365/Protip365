import { getSupabaseClient } from "./supabase";

export type Employer = {
  id: string;
  user_id: string;
  name: string;
  hourly_rate: number;
  active?: boolean;
};

export type UserProfile = {
  user_id: string;
  default_hourly_rate: number;
  target_tip_daily: number;
  target_tip_weekly: number;
  target_tip_monthly: number;
  target_sales_daily: number;
  target_sales_weekly: number;
  target_sales_monthly: number;
  target_hours_daily: number;
  target_hours_weekly: number;
  target_hours_monthly: number;
  week_start: number;
  language: string;
  preferred_language?: string | null;
  name: string | null;
  use_multiple_employers: boolean;
  default_employer_id?: string | null;
  tip_target_percentage?: number | null;
  has_variable_schedule?: boolean | null;
  average_deduction_percentage?: number | null;
  default_alert_minutes?: number | null;
  onboarding_completed?: boolean | null;
};

export type ShiftIncome = {
  income_id?: string | null;
  shift_id?: string;
  id?: string;
  user_id: string;
  employer_id: string | null;
  employer_name: string | null;
  shift_date: string;
  expected_hours?: number;
  hours: number;
  hourly_rate: number | null;
  sales: number;
  tips: number;
  cash_out: number;
  other?: number;
  base_income: number;
  net_tips: number;
  total_income: number;
  tip_percentage: number;
  start_time: string | null;
  end_time: string | null;
  shift_status?: "planned" | "completed" | "missed";
  has_earnings?: boolean;
  notes?: string | null;
};

export type ShiftDraftInput = {
  shiftDate: string;
  startTime: string;
  endTime: string;
  expectedHours: number;
  employerId: string | null;
  hourlyRate: number;
  notes: string;
};

export type IncomeInput = {
  shiftId: string;
  actualHours: number;
  actualStartTime: string;
  actualEndTime: string;
  sales: number;
  tips: number;
  cashOut: number;
  notes: string;
  incomeId?: string | null;
};

export type ShiftUpdateInput = ShiftDraftInput & {
  shiftId: string;
};

type ExpectedShiftRow = {
  id: string;
  user_id: string;
  employer_id: string | null;
  shift_date: string;
  start_time: string | null;
  end_time: string | null;
  expected_hours: number;
  hourly_rate: number;
  notes?: string | null;
  status?: "planned" | "completed" | "missed";
};

type ShiftEntryRow = {
  id: string;
  shift_id: string;
  user_id: string;
  actual_start_time: string | null;
  actual_end_time: string | null;
  actual_hours: number;
  sales: number;
  tips: number;
  cash_out: number;
  other?: number | null;
  hourly_rate?: number | null;
  gross_income?: number | null;
  total_income?: number | null;
  deduction_percentage?: number | null;
  notes?: string | null;
};

const SHIFT_INCOME_PAGE_SIZE = 1000;
const SHIFT_ENTRY_LOOKUP_CHUNK_SIZE = 200;

const defaultProfile: Omit<UserProfile, "user_id"> = {
  default_hourly_rate: 15,
  language: "en",
  name: null,
  target_hours_daily: 0,
  target_hours_monthly: 0,
  target_hours_weekly: 0,
  target_sales_daily: 0,
  target_sales_monthly: 0,
  target_sales_weekly: 0,
  target_tip_daily: 0,
  target_tip_monthly: 0,
  target_tip_weekly: 0,
  use_multiple_employers: true,
  week_start: 0,
  average_deduction_percentage: 0,
};

function client() {
  const supabase = getSupabaseClient();

  if (!supabase) {
    throw new Error("Supabase is not configured.");
  }

  return supabase;
}

export async function getCurrentUserId() {
  const { data, error } = await client().auth.getUser();

  if (error || !data.user) {
    throw error ?? new Error("No signed-in user.");
  }

  return data.user.id;
}

export async function getProfile() {
  const { data: userData, error: userError } = await client().auth.getUser();

  if (userError || !userData.user) {
    throw userError ?? new Error("No signed-in user.");
  }

  const userId = userData.user.id;
  const { data, error } = await client()
    .from("users_profile")
    .select()
    .eq("user_id", userId)
    .maybeSingle<UserProfile>();

  if (error) {
    throw error;
  }

  if (data) {
    return {
      ...defaultProfile,
      ...data,
      user_id: userId,
    };
  }

  const profile = {
    ...defaultProfile,
    name: typeof userData.user.user_metadata?.name === "string" ? userData.user.user_metadata.name : null,
    user_id: userId,
  };

  const { error: insertError } = await client().from("users_profile").insert(profile);

  if (insertError) {
    throw insertError;
  }

  return profile;
}

export async function saveProfile(profile: UserProfile) {
  const userId = await getCurrentUserId();
  const { error } = await client()
    .from("users_profile")
    .upsert({
      ...profile,
      user_id: userId,
    });

  if (error) {
    throw error;
  }
}

export async function listEmployers() {
  const userId = await getCurrentUserId();
  const { data, error } = await client()
    .from("employers")
    .select()
    .eq("user_id", userId)
    .order("name");

  if (error) {
    throw error;
  }

  return (data ?? []) as Employer[];
}

export async function addEmployer(name: string, hourlyRate: number) {
  const userId = await getCurrentUserId();
  const { error } = await client().from("employers").insert({
    active: true,
    hourly_rate: hourlyRate,
    name,
    user_id: userId,
  });

  if (error) {
    throw error;
  }
}

export async function deleteEmployer(id: string) {
  const userId = await getCurrentUserId();
  const { error } = await client().from("employers").update({ active: false }).eq("id", id).eq("user_id", userId);

  if (error) {
    throw error;
  }
}

export async function listShiftIncome(limit?: number) {
  const userId = await getCurrentUserId();
  const shifts = await listExpectedShiftRows(userId, limit);
  const { data: employers, error: employersError } = await client().from("employers").select().eq("user_id", userId);

  if (employersError) {
    throw employersError;
  }

  const typedShifts = shifts;
  const shiftIds = typedShifts.map((shift) => shift.id);
  const entriesByShiftId = new Map<string, ShiftEntryRow>();

  if (shiftIds.length > 0) {
    const entries = await listShiftEntryRows(userId, shiftIds);

    for (const entry of entries) {
      entriesByShiftId.set(entry.shift_id, entry);
    }
  }

  const employersById = new Map((employers ?? []).map((employer) => [employer.id, employer as Employer]));

  return typedShifts.map((shift) => {
    const entry = entriesByShiftId.get(shift.id);
    const employer = shift.employer_id ? employersById.get(shift.employer_id) : null;
    const hours = entry ? Number(entry.actual_hours ?? shift.expected_hours ?? 0) : 0;
    const hourlyRate = Number(entry?.hourly_rate ?? shift.hourly_rate ?? employer?.hourly_rate ?? 0);
    const sales = Number(entry?.sales ?? 0);
    const tips = Number(entry?.tips ?? 0);
    const cashOut = Number(entry?.cash_out ?? 0);
    const other = Number(entry?.other ?? 0);
    const baseIncome = entry ? Number(entry.gross_income ?? hours * hourlyRate) : 0;
    const totalIncome = entry ? Number(entry.total_income ?? baseIncome + tips + other - cashOut) : 0;

    return {
      base_income: baseIncome,
      cash_out: cashOut,
      employer_id: shift.employer_id,
      employer_name: employer?.name ?? null,
      end_time: entry?.actual_end_time ?? shift.end_time,
      expected_hours: Number(shift.expected_hours ?? 0),
      has_earnings: Boolean(entry),
      hourly_rate: hourlyRate,
      hours,
      id: shift.id,
      income_id: entry?.id ?? null,
      net_tips: tips - cashOut,
      notes: normalizedNote(shift.notes) ?? normalizedNote(entry?.notes) ?? null,
      other,
      sales,
      shift_date: shift.shift_date,
      shift_id: shift.id,
      shift_status: shift.status ?? (entry ? "completed" : "planned"),
      start_time: entry?.actual_start_time ?? shift.start_time,
      tip_percentage: sales > 0 ? (tips / sales) * 100 : 0,
      tips,
      total_income: totalIncome,
      user_id: shift.user_id,
    };
  });
}

async function listExpectedShiftRows(userId: string, limit?: number) {
  const rows: ExpectedShiftRow[] = [];
  const pageSize = limit ? Math.min(limit, SHIFT_INCOME_PAGE_SIZE) : SHIFT_INCOME_PAGE_SIZE;
  let from = 0;

  while (limit === undefined || rows.length < limit) {
    const remaining = limit === undefined ? pageSize : Math.min(pageSize, limit - rows.length);
    const to = from + remaining - 1;
    const { data, error } = await client()
      .from("expected_shifts")
      .select()
      .eq("user_id", userId)
      .order("shift_date", { ascending: false })
      .range(from, to);

    if (error) {
      throw error;
    }

    const page = (data ?? []) as ExpectedShiftRow[];
    rows.push(...page);

    if (page.length < remaining) {
      break;
    }

    from += page.length;
  }

  return rows;
}

async function listShiftEntryRows(userId: string, shiftIds: string[]) {
  const rows: ShiftEntryRow[] = [];

  for (let index = 0; index < shiftIds.length; index += SHIFT_ENTRY_LOOKUP_CHUNK_SIZE) {
    const chunk = shiftIds.slice(index, index + SHIFT_ENTRY_LOOKUP_CHUNK_SIZE);
    const { data, error } = await client()
      .from("shift_entries")
      .select()
      .eq("user_id", userId)
      .in("shift_id", chunk);

    if (error) {
      throw error;
    }

    rows.push(...((data ?? []) as ShiftEntryRow[]));
  }

  return rows;
}

function normalizedNote(value: string | null | undefined) {
  const note = value?.trim();

  return note ? note : null;
}

async function assertEmployerBelongsToUser(employerId: string | null, userId: string) {
  if (!employerId) {
    return;
  }

  const { data: employer, error } = await client()
    .from("employers")
    .select("id")
    .eq("id", employerId)
    .eq("user_id", userId)
    .maybeSingle<{ id: string }>();

  if (error) {
    throw error;
  }

  if (!employer) {
    throw new Error("Selected employer was not found.");
  }
}

export async function createShift(input: ShiftDraftInput) {
  const userId = await getCurrentUserId();
  await assertEmployerBelongsToUser(input.employerId, userId);

  const { error } = await client().from("expected_shifts").insert({
    alert_minutes: null,
    employer_id: input.employerId,
    expected_hours: input.expectedHours,
    hourly_rate: input.hourlyRate,
    lunch_break_minutes: 0,
    notes: input.notes,
    shift_date: input.shiftDate,
    start_time: input.startTime,
    end_time: input.endTime,
    status: "planned",
    user_id: userId,
  });

  if (error) {
    throw error;
  }
}

export async function updateShift(input: ShiftUpdateInput) {
  const userId = await getCurrentUserId();
  await assertEmployerBelongsToUser(input.employerId, userId);
  const { data: entry, error: entryError } = await client()
    .from("shift_entries")
    .select("id,tips,cash_out,other")
    .eq("shift_id", input.shiftId)
    .eq("user_id", userId)
    .maybeSingle<Pick<ShiftEntryRow, "id" | "tips" | "cash_out" | "other">>();

  if (entryError) {
    throw entryError;
  }

  const { error } = await client()
    .from("expected_shifts")
    .update({
      employer_id: input.employerId,
      expected_hours: input.expectedHours,
      hourly_rate: input.hourlyRate,
      notes: input.notes,
      shift_date: input.shiftDate,
      start_time: input.startTime,
      end_time: input.endTime,
    })
    .eq("id", input.shiftId)
    .eq("user_id", userId);

  if (error) {
    throw error;
  }

  if (entry?.id) {
    const profile = await getProfile();
    const other = Number(entry.other ?? 0);
    const grossIncome = input.expectedHours * input.hourlyRate;
    const totalIncome = grossIncome + Number(entry.tips ?? 0) + other - Number(entry.cash_out ?? 0);
    const deductionPercentage = Number(profile.average_deduction_percentage ?? 0);
    const { error: incomeError } = await client()
      .from("shift_entries")
      .update({
        actual_end_time: input.endTime,
        actual_hours: input.expectedHours,
        actual_start_time: input.startTime,
        deduction_percentage: deductionPercentage,
        gross_income: grossIncome,
        hourly_rate: input.hourlyRate,
        net_income: totalIncome * (1 - deductionPercentage / 100),
        notes: input.notes,
        total_income: totalIncome,
      })
      .eq("id", entry.id)
      .eq("user_id", userId);

    if (incomeError) {
      throw incomeError;
    }
  }
}

export async function deleteShift(shiftId: string) {
  const userId = await getCurrentUserId();
  const { error } = await client().from("expected_shifts").delete().eq("id", shiftId).eq("user_id", userId);

  if (error) {
    throw error;
  }
}

export async function markShiftMissed(shiftId: string, reason: string) {
  const userId = await getCurrentUserId();
  const { data: previousShift, error: previousShiftError } = await client()
    .from("expected_shifts")
    .select("status,notes")
    .eq("id", shiftId)
    .eq("user_id", userId)
    .maybeSingle<Pick<ExpectedShiftRow, "status" | "notes">>();

  if (previousShiftError) {
    throw previousShiftError;
  }

  const { error: statusError } = await client()
    .from("expected_shifts")
    .update({
      notes: reason,
      status: "missed",
    })
    .eq("id", shiftId)
    .eq("user_id", userId);

  if (statusError) {
    throw statusError;
  }

  const { error: entryError } = await client().from("shift_entries").delete().eq("shift_id", shiftId).eq("user_id", userId);

  if (entryError) {
    await client()
      .from("expected_shifts")
      .update({
        notes: previousShift?.notes ?? null,
        status: previousShift?.status ?? "planned",
      })
      .eq("id", shiftId)
      .eq("user_id", userId);
    throw entryError;
  }
}

export async function deleteIncome(incomeId: string, shiftId: string) {
  const userId = await getCurrentUserId();
  const { data: previousShift, error: previousShiftError } = await client()
    .from("expected_shifts")
    .select("status")
    .eq("id", shiftId)
    .eq("user_id", userId)
    .maybeSingle<Pick<ExpectedShiftRow, "status">>();

  if (previousShiftError) {
    throw previousShiftError;
  }

  const { error: statusError } = await client()
    .from("expected_shifts")
    .update({ status: "planned" })
    .eq("id", shiftId)
    .eq("user_id", userId)
    .eq("status", "completed");

  if (statusError) {
    throw statusError;
  }

  const { error } = await client().from("shift_entries").delete().eq("id", incomeId).eq("shift_id", shiftId).eq("user_id", userId);

  if (error) {
    if (previousShift?.status) {
      await client().from("expected_shifts").update({ status: previousShift.status }).eq("id", shiftId).eq("user_id", userId);
    }

    throw error;
  }
}

export async function saveIncome(input: IncomeInput) {
  const userId = await getCurrentUserId();
  const [{ data: shift, error: shiftError }, profile] = await Promise.all([
    client().from("expected_shifts").select("hourly_rate").eq("id", input.shiftId).eq("user_id", userId).maybeSingle<{ hourly_rate: number }>(),
    getProfile(),
  ]);

  if (shiftError) {
    throw shiftError;
  }

  if (!shift) {
    throw new Error("Selected shift was not found.");
  }

  const hourlyRate = Number(shift.hourly_rate ?? 0);
  const grossIncome = input.actualHours * hourlyRate;
  const other = 0;
  const totalIncome = grossIncome + input.tips + other - input.cashOut;
  const deductionPercentage = Number(profile.average_deduction_percentage ?? 0);
  const payload = {
    actual_end_time: input.actualEndTime,
    actual_hours: input.actualHours,
    actual_start_time: input.actualStartTime,
    cash_out: input.cashOut,
    deduction_percentage: deductionPercentage,
    gross_income: grossIncome,
    hourly_rate: hourlyRate,
    net_income: totalIncome * (1 - deductionPercentage / 100),
    notes: input.notes,
    other,
    sales: input.sales,
    shift_id: input.shiftId,
    tips: input.tips,
    total_income: totalIncome,
    user_id: userId,
  };

  const query = input.incomeId
    ? client().from("shift_entries").update(payload).eq("id", input.incomeId).eq("user_id", userId)
    : client().from("shift_entries").insert(payload);

  const { error } = await query;

  if (error) {
    throw error;
  }

  const { error: notesError } = await client()
    .from("expected_shifts")
    .update({ notes: input.notes })
    .eq("id", input.shiftId)
    .eq("user_id", userId);

  if (notesError) {
    throw notesError;
  }

  const { error: statusError } = await client()
    .from("expected_shifts")
    .update({ status: "completed" })
    .eq("id", input.shiftId)
    .eq("user_id", userId);

  if (statusError) {
    throw statusError;
  }
}

export function formatCurrency(amount: number) {
  return new Intl.NumberFormat(undefined, {
    currency: "USD",
    maximumFractionDigits: 2,
    minimumFractionDigits: 2,
    style: "currency",
  }).format(Number.isFinite(amount) ? amount : 0);
}

export function parseMoney(value: string) {
  const parsed = Number(value.replace(/[^0-9.-]/g, ""));

  return Number.isFinite(parsed) ? parsed : 0;
}

export function toDateValue(date: Date) {
  const month = `${date.getMonth() + 1}`.padStart(2, "0");
  const day = `${date.getDate()}`.padStart(2, "0");

  return `${date.getFullYear()}-${month}-${day}`;
}

export function toTimeValue(date: Date) {
  const hours = `${date.getHours()}`.padStart(2, "0");
  const minutes = `${date.getMinutes()}`.padStart(2, "0");

  return `${hours}:${minutes}`;
}

export function hoursBetween(startTime: string, endTime: string) {
  const [startHours, startMinutes] = startTime.split(":").map(Number);
  const [endHours, endMinutes] = endTime.split(":").map(Number);
  const start = startHours + startMinutes / 60;
  let end = endHours + endMinutes / 60;

  if (end < start) {
    end += 24;
  }

  return Math.max(0, Math.round((end - start) * 100) / 100);
}
