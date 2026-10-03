import {
  Shift,
  Data,
  amount,
  hours,
  net,
  wage,
  hourly,
  range,
  inRange,
  salesCheck,
  validData,
  totals,
} from "./domain";
const shift = (overrides: Partial<Shift> = {}): Shift => ({
  id: "s1",
  job: "j1",
  date: "2026-10-02",
  start: "17:00",
  end: "01:30",
  brk: 30,
  cash: null,
  card: 10050,
  tipIn: null,
  tipOut: null,
  sales: null,
  other: null,
  note: "",
  rate: 1330,
  createdAt: "2026-10-02T17:00:00Z",
  updatedAt: "2026-10-02T17:00:00Z",
  ...overrides,
});
test("card-only unknown amounts remain nullable; overnight minutes and cent rounding", () => {
  const s = shift();
  expect(hours(s)).toBe(8);
  expect(net(s)).toBe(10050);
  expect(wage(s)).toBe(10640);
  expect(hourly(s)).toBe(2586);
  expect(s.cash).toBeNull();
  expect(hours(shift({ start: "19:00", end: "02:00" }))).toBe(6.5);
  expect(hours(shift({ start: "17:00", end: "17:00", brk: 0 }))).toBe(24);
});
test("zero tips save and shared tips subtract once, including statement C", () => {
  expect(net(shift({ card: 0 }))).toBe(0);
  expect(
    net(
      shift({ cash: 4050, card: 10000, tipIn: 1000, tipOut: 2050, other: 500 }),
    ),
  ).toBe(13500);
  expect(hourly(shift({ start: "17:00", end: "17:15", brk: 30 }))).toBeNull();
});
test("decimal commas accepted, malformed or negative money rejected", () => {
  expect(amount("100,50")).toBe(10050);
  expect(amount("0")).toBe(0);
  expect(amount("")).toBeNull();
  for (const v of ["-1", "1.234", "1,2,3", "Infinity", "1e8"])
    expect(amount(v)).toBeUndefined();
});
test("pay-period week start reslices ranges across month/year boundaries", () => {
  expect(range("week", "2026-10-02", 1)).toEqual(["2026-09-28", "2026-10-04"]);
  expect(range("week", "2026-10-02", 5)).toEqual(["2026-10-02", "2026-10-08"]);
  expect(range("week", "2026-01-01", 1)).toEqual(["2025-12-29", "2026-01-04"]);
  expect(range("month", "2026-02-18", 1)).toEqual(["2026-02-01", "2026-02-28"]);
  expect(range("year", "2026-10-02", 1)).toEqual(["2026-01-01", "2026-10-02"]);
});
test("two shifts same day/job count separately; planned shifts excluded", () => {
  const rows = [
    shift(),
    shift({ id: "s2", card: 5000 }),
    shift({ id: "s3", planned: true }),
  ];
  const worked = inRange(rows, "2026-10-01", "2026-10-02");
  expect(worked).toHaveLength(2);
  expect(totals(worked)).toMatchObject({
    tips: 15050,
    h: 16,
    pay: 36330,
    rate: 2271,
  });
});
test("sales check pairs numerator with recorded-sales subset, never infers unknown sales", () => {
  expect(salesCheck([shift()])).toBeNull();
  expect(
    salesCheck([
      shift({ card: 7000, sales: 100000 }),
      shift({ id: "s2", card: 99999 }),
    ]),
  ).toBe(7);
  expect(salesCheck([shift({ card: 8000, sales: 100000 })])).toBe(8);
});
test("backup schema rejects broken relationships and malformed financial data", () => {
  const d: Data = {
    version: 1,
    onboarded: true,
    jobs: [
      {
        id: "j1",
        name: "Bar",
        role: "Bartender",
        rate: 1330,
        color: "#A67B65",
        start: "17:00",
        end: "01:30",
        brk: 30,
      },
    ],
    shifts: [shift()],
    settings: {
      language: "fr",
      weekStart: 1,
      reminder: false,
      offset: 15,
      goal: null,
      name: "",
    },
  };
  expect(validData(JSON.parse(JSON.stringify(d)))).toBe(true);
  expect(validData({ ...d, shifts: [shift({ job: "missing" })] })).toBe(false);
  expect(validData({ ...d, shifts: [shift({ card: -1 })] })).toBe(false);
  expect(validData({ ...d, settings: { ...d.settings, weekStart: 7 } })).toBe(
    false,
  );
});
