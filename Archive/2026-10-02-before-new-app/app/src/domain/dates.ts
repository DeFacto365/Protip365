/**
 * Pure date/time helpers for ISO `YYYY-MM-DD` dates and minutes-from-midnight
 * times. No React Native or database imports.
 */

const ISO_RE = /^\d{4}-\d{2}-\d{2}$/;

export function isValidIsoDate(iso: string): boolean {
  if (!ISO_RE.test(iso)) return false;
  const [y, m, d] = iso.split('-').map(Number);
  const date = new Date(Date.UTC(y, m - 1, d));
  return (
    date.getUTCFullYear() === y && date.getUTCMonth() === m - 1 && date.getUTCDate() === d
  );
}

function pad2(n: number): string {
  return n < 10 ? `0${n}` : String(n);
}

export function toIso(date: Date): string {
  return `${date.getFullYear()}-${pad2(date.getMonth() + 1)}-${pad2(date.getDate())}`;
}

export function todayIso(): string {
  return toIso(new Date());
}

/** Add `days` (may be negative) to an ISO date. */
export function addDaysIso(iso: string, days: number): string {
  const [y, m, d] = iso.split('-').map(Number);
  const date = new Date(Date.UTC(y, m - 1, d + days));
  return `${date.getUTCFullYear()}-${pad2(date.getUTCMonth() + 1)}-${pad2(date.getUTCDate())}`;
}

/** Monday-based start of the week containing `iso`. */
export function startOfWeekIso(iso: string): string {
  const [y, m, d] = iso.split('-').map(Number);
  const date = new Date(Date.UTC(y, m - 1, d));
  const weekday = date.getUTCDay(); // 0 = Sunday
  const diff = weekday === 0 ? -6 : 1 - weekday;
  return addDaysIso(iso, diff);
}

/** The 7 ISO dates of the week starting at `weekStartIso`. */
export function weekDatesIso(weekStartIso: string): string[] {
  return Array.from({ length: 7 }, (_, i) => addDaysIso(weekStartIso, i));
}

/** Add calendar months and clamp the day to the destination month's last day. */
export function addMonthsIso(iso: string, months: number): string {
  const [year, month, day] = iso.split('-').map(Number);
  const target = new Date(Date.UTC(year, month - 1 + months, 1));
  const lastDay = new Date(
    Date.UTC(target.getUTCFullYear(), target.getUTCMonth() + 1, 0)
  ).getUTCDate();
  return `${target.getUTCFullYear()}-${pad2(target.getUTCMonth() + 1)}-${pad2(
    Math.min(day, lastDay)
  )}`;
}

/** Every ISO date in the calendar month containing `iso`. */
export function monthDatesIso(iso: string): string[] {
  const [year, month] = iso.split('-').map(Number);
  const count = new Date(Date.UTC(year, month, 0)).getUTCDate();
  return Array.from({ length: count }, (_, index) =>
    `${year}-${pad2(month)}-${pad2(index + 1)}`
  );
}

/** Format minutes-from-midnight as 24h `HH:MM` (wraps past midnight). */
export function minutesToHHMM(min: number): string {
  const norm = ((Math.round(min) % 1440) + 1440) % 1440;
  return `${pad2(Math.floor(norm / 60))}:${pad2(norm % 60)}`;
}

/** Parse `HH:MM` (24h) into minutes-from-midnight; null when invalid. */
export function parseHHMM(text: string): number | null {
  const match = text.trim().match(/^(\d{1,2}):(\d{2})$/);
  if (!match) return null;
  const h = Number(match[1]);
  const m = Number(match[2]);
  if (h > 23 || m > 59) return null;
  return h * 60 + m;
}
