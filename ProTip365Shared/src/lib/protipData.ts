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
  name: string | null;
  use_multiple_employers: boolean;
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
  const userId = await getCurrentUserId();
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
  const { error } = await client().from("employers").delete().eq("id", id);

  if (error) {
    throw error;
  }
}

export async function listShiftIncome(limit = 100) {
  const { data, error } = await client().from("v_shift_income").select().limit(limit);

  if (error) {
    throw error;
  }

  return (data ?? []) as ShiftIncome[];
}

export async function createShift(input: ShiftDraftInput) {
  const userId = await getCurrentUserId();
  const { error } = await client().from("shifts").insert({
    employer_id: input.employerId,
    expected_hours: input.expectedHours,
    hourly_rate: input.hourlyRate,
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

export async function saveIncome(input: IncomeInput) {
  const userId = await getCurrentUserId();
  const payload = {
    actual_end_time: input.actualEndTime,
    actual_hours: input.actualHours,
    actual_start_time: input.actualStartTime,
    cash_out: input.cashOut,
    notes: input.notes,
    sales: input.sales,
    shift_id: input.shiftId,
    tips: input.tips,
    user_id: userId,
  };

  const query = input.incomeId
    ? client().from("shift_income").update(payload).eq("id", input.incomeId)
    : client().from("shift_income").insert(payload);

  const { error } = await query;

  if (error) {
    throw error;
  }

  await client().from("shifts").update({ status: "completed" }).eq("id", input.shiftId);
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
