// Ported from Docs/reference-prototype.js; money is stored as integer cents.
export type Job = {
  id: string;
  name: string;
  role: string;
  rate: number;
  color: string;
  start: string;
  end: string;
  brk: number;
  archived?: boolean;
};
export type Shift = {
  id: string;
  job: string;
  date: string;
  start: string;
  end: string;
  brk: number;
  cash: number | null;
  card: number | null;
  tipIn: number | null;
  tipOut: number | null;
  sales: number | null;
  other: number | null;
  note: string;
  rate: number;
  planned?: boolean;
  createdAt: string;
  updatedAt: string;
};
export type Settings = {
  language: "fr" | "en";
  weekStart: number;
  reminder: boolean;
  offset: number;
  goal: number | null;
  name: string;
};
export type Data = {
  version: 1;
  onboarded: boolean;
  jobs: Job[];
  shifts: Shift[];
  settings: Settings;
};
export const colors = ["#A67B65", "#6F8FA3", "#8A9C7D", "#C9A15B", "#9C7A9A"];
export const iso = (d = new Date()) =>
  `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
export const localDate = (d: string) => new Date(d + "T12:00:00");
export function addDays(d: string, n: number) {
  const x = localDate(d);
  x.setDate(x.getDate() + n);
  return iso(x);
}
export const minutes = (s: string) =>
  Number(s.slice(0, 2)) * 60 + Number(s.slice(3));
export function hours(s: Pick<Shift, "start" | "end" | "brk">) {
  let n = minutes(s.end) - minutes(s.start);
  if (n <= 0) n += 1440;
  return Math.max(0, n - s.brk) / 60;
}
export const net = (s: Shift) =>
  (s.cash ?? 0) +
  (s.card ?? 0) +
  (s.tipIn ?? 0) +
  (s.other ?? 0) -
  (s.tipOut ?? 0);
export const wage = (s: Shift) => Math.round(hours(s) * s.rate);
export const hourly = (s: Shift) =>
  hours(s) > 0 ? Math.round((wage(s) + net(s)) / hours(s)) : null;
export function weekStart(d: string, start: number) {
  return addDays(d, -((localDate(d).getDay() - start + 7) % 7));
}
export function range(
  kind: "week" | "month" | "year",
  today: string,
  start: number,
): [string, string] {
  const w = weekStart(today, start),
    d = localDate(today);
  return kind === "week"
    ? [w, addDays(w, 6)]
    : kind === "month"
      ? [
          today.slice(0, 7) + "-01",
          iso(new Date(d.getFullYear(), d.getMonth() + 1, 0)),
        ]
      : [today.slice(0, 4) + "-01-01", today];
}
export function inRange(shifts: Shift[], from: string, to: string) {
  return shifts.filter((s) => !s.planned && s.date >= from && s.date <= to);
}
export function totals(shifts: Shift[]) {
  const tips = shifts.reduce((v, s) => v + net(s), 0),
    h = shifts.reduce((v, s) => v + hours(s), 0),
    pay = tips + shifts.reduce((v, s) => v + wage(s), 0);
  return {
    tips,
    h,
    pay,
    rate: h ? Math.round(pay / h) : null,
    average: shifts.length ? Math.round(tips / shifts.length) : null,
  };
}
export function salesCheck(shifts: Shift[]) {
  const known = shifts.filter((s) => s.sales !== null && s.sales > 0);
  const sales = known.reduce((v, s) => v + s.sales!, 0);
  return sales
    ? (100 * known.reduce((v, s) => v + (s.cash ?? 0) + (s.card ?? 0), 0)) /
        sales
    : null;
}
export function amount(text: string): number | null | undefined {
  if (!text.trim()) return null;
  const t = text.trim().replace(",", ".");
  if (!/^\d+(\.\d{1,2})?$/.test(t)) return undefined;
  const [a, b = ""] = t.split(".");
  const n = Number(a) * 100 + Number(b.padEnd(2, "0"));
  return Number.isSafeInteger(n) && n <= 100000000 ? n : undefined;
}
export function validDate(d: string) {
  return /^\d{4}-\d{2}-\d{2}$/.test(d) && iso(localDate(d)) === d;
}
export function validTime(t: string) {
  return /^([01]\d|2[0-3]):[0-5]\d$/.test(t);
}
export function validData(value: unknown): value is Data {
  if (!value || typeof value !== "object") return false;
  const d = value as Data;
  return (
    d.version === 1 &&
    typeof d.onboarded === "boolean" &&
    Array.isArray(d.jobs) &&
    Array.isArray(d.shifts) &&
    !!d.settings &&
    ["fr", "en"].includes(d.settings.language) &&
    Number.isInteger(d.settings.weekStart) &&
    d.settings.weekStart >= 0 &&
    d.settings.weekStart <= 6 &&
    typeof d.settings.reminder === "boolean" &&
    Number.isFinite(d.settings.offset) &&
    d.settings.offset >= 0 &&
    d.settings.offset <= 120 &&
    (d.settings.goal === null ||
      (Number.isSafeInteger(d.settings.goal) && d.settings.goal >= 0)) &&
    typeof d.settings.name === "string" &&
    new Set(d.jobs.map((j) => j?.id)).size === d.jobs.length &&
    new Set(d.shifts.map((s) => s?.id)).size === d.shifts.length &&
    d.jobs.every(
      (j) =>
        !!j &&
        typeof j.id === "string" &&
        j.id.length > 0 &&
        (j.archived === undefined || typeof j.archived === "boolean") &&
        typeof j.name === "string" &&
        typeof j.role === "string" &&
        /^#[0-9a-f]{6}$/i.test(j.color) &&
        Number.isSafeInteger(j.rate) &&
        j.rate >= 0 &&
        validTime(j.start) &&
        validTime(j.end) &&
        Number.isInteger(j.brk) &&
        j.brk >= 0 &&
        j.brk <= 60,
    ) &&
    d.shifts.every(
      (s) =>
        !!s &&
        typeof s.id === "string" &&
        s.id.length > 0 &&
        (s.planned === undefined || typeof s.planned === "boolean") &&
        typeof s.createdAt === "string" &&
        Number.isFinite(Date.parse(s.createdAt)) &&
        typeof s.updatedAt === "string" &&
        Number.isFinite(Date.parse(s.updatedAt)) &&
        d.jobs.some((j) => j.id === s.job) &&
        validDate(s.date) &&
        validTime(s.start) &&
        validTime(s.end) &&
        Number.isInteger(s.brk) &&
        s.brk >= 0 &&
        s.brk <= 60 &&
        Number.isSafeInteger(s.rate) &&
        s.rate >= 0 &&
        [s.cash, s.card, s.tipIn, s.tipOut, s.sales, s.other].every(
          (n) => n === null || (Number.isSafeInteger(n) && n >= 0),
        ) &&
        typeof s.note === "string",
    )
  );
}
