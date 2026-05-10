import { beforeEach, describe, expect, it, vi } from "vitest";
import { clearShiftRecords, loadShiftRecords, saveShiftRecord } from "./shiftRepository";
import { ShiftRecord } from "../domain";

const store = new Map<string, string>();

vi.mock("@react-native-async-storage/async-storage", () => ({
  default: {
    getItem: vi.fn((key: string) => Promise.resolve(store.get(key) ?? null)),
    removeItem: vi.fn((key: string) => {
      store.delete(key);
      return Promise.resolve();
    }),
    setItem: vi.fn((key: string, value: string) => {
      store.set(key, value);
      return Promise.resolve();
    }),
  },
}));

const record: ShiftRecord = {
  entry: {
    id: "entry-1",
    sales: 500,
    shiftId: "shift-1",
    tips: { card: 90, cash: 10 },
    userId: "local-user",
  },
  plannedShift: {
    endTime: "22:00",
    hourlyRate: 15,
    id: "shift-1",
    shiftDate: "2026-05-09",
    startTime: "17:00",
    status: "completed",
    userId: "local-user",
  },
};

describe("shiftRepository", () => {
  beforeEach(() => {
    store.clear();
  });

  it("persists and loads shift records", async () => {
    await saveShiftRecord(record);

    expect(await loadShiftRecords()).toEqual([record]);
  });

  it("replaces an edited shift by planned shift id", async () => {
    await saveShiftRecord(record);
    await saveShiftRecord({
      ...record,
      entry: {
        ...record.entry!,
        sales: 600,
      },
    });

    const records = await loadShiftRecords();
    expect(records).toHaveLength(1);
    expect(records[0]?.entry?.sales).toBe(600);
  });

  it("clears stored shifts", async () => {
    await saveShiftRecord(record);
    await clearShiftRecords();

    expect(await loadShiftRecords()).toEqual([]);
  });
});
