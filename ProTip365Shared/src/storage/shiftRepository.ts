import { ShiftRecord } from "../domain";
import { supabaseSecureStorage } from "../lib/secureStorage";

const STORAGE_KEY = "protip365.shiftRecords.v1";

export async function loadShiftRecords(): Promise<ShiftRecord[]> {
  const raw = await supabaseSecureStorage.getItem(STORAGE_KEY);
  if (!raw) {
    return [];
  }

  const parsed = JSON.parse(raw);
  return Array.isArray(parsed) ? parsed : [];
}

export async function saveShiftRecord(record: ShiftRecord): Promise<ShiftRecord[]> {
  const records = await loadShiftRecords();
  const nextRecords = [record, ...records.filter((item) => item.plannedShift.id !== record.plannedShift.id)];
  await supabaseSecureStorage.setItem(STORAGE_KEY, JSON.stringify(nextRecords));
  return nextRecords;
}

export async function clearShiftRecords() {
  await supabaseSecureStorage.removeItem(STORAGE_KEY);
}
