import { calculateShift, ShiftRecord, ShiftStatus } from "../../domain";

export type ShiftEditTarget = "dailyEntry" | "plannedShift";

export type ShiftListItem = {
  id: string;
  date: string;
  time: string;
  title: string;
  subtitle: string;
  status: ShiftStatus;
  statusLabel: string;
  editTarget: ShiftEditTarget;
};

export function statusLabel(status: ShiftStatus) {
  switch (status) {
    case "completed":
      return "Completed";
    case "did_not_work":
      return "Did not work";
    case "missed":
      return "Missed";
    case "planned":
    default:
      return "Planned";
  }
}

export function editTargetForRecord(record: ShiftRecord): ShiftEditTarget {
  return record.plannedShift.status === "completed" && record.entry ? "dailyEntry" : "plannedShift";
}

export function buildShiftListItem(record: ShiftRecord): ShiftListItem {
  const calculation = calculateShift(record);
  const time = `${record.plannedShift.startTime} - ${record.plannedShift.endTime}`;
  const status = record.plannedShift.status;

  return {
    date: record.plannedShift.shiftDate,
    editTarget: editTargetForRecord(record),
    id: record.plannedShift.id,
    status,
    statusLabel: statusLabel(status),
    subtitle:
      status === "completed"
        ? `$${calculation.totalIncome.toFixed(2)} total | ${calculation.hours.toFixed(2)} h`
        : `${statusLabel(status)} | ${record.employer?.name ?? "No employer"}`,
    time,
    title: `${record.plannedShift.shiftDate} | ${time}`,
  };
}

export function sortShiftRecordsAscending(records: ShiftRecord[]) {
  return [...records].sort((first, second) => `${first.plannedShift.shiftDate} ${first.plannedShift.startTime}`.localeCompare(`${second.plannedShift.shiftDate} ${second.plannedShift.startTime}`));
}

export function sortShiftRecordsDescending(records: ShiftRecord[]) {
  return [...records].sort((first, second) => `${second.plannedShift.shiftDate} ${second.plannedShift.startTime}`.localeCompare(`${first.plannedShift.shiftDate} ${first.plannedShift.startTime}`));
}

export function buildCalendarItems(records: ShiftRecord[]) {
  return sortShiftRecordsAscending(records).map(buildShiftListItem);
}

export function buildHistoryItems(records: ShiftRecord[]) {
  return sortShiftRecordsDescending(records).map(buildShiftListItem);
}
