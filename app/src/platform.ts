import { Platform } from "react-native";
import * as Notifications from "expo-notifications";
import * as Print from "expo-print";
import * as Sharing from "expo-sharing";
import * as DocumentPicker from "expo-document-picker";
import { File, Paths } from "expo-file-system";
import {
  Data,
  Shift,
  addDays,
  hours,
  iso,
  minutes,
  net,
  validData,
  wage,
} from "./domain";
import { text } from "./copy";
export const RQ =
  "https://www.revenuquebec.ca/en/citizens/your-situation/employees-who-receive-tips-benefits-and-obligations/";
const escape = (v: unknown) =>
  String(v ?? "").replace(
    /[&<>"']/g,
    (c) =>
      ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[
        c
      ]!,
  );
const money = (v: number, language: "fr" | "en", currency = "CAD") =>
  new Intl.NumberFormat(language === "fr" ? "fr-CA" : "en-CA", {
    style: "currency",
    currency,
  }).format(v / 100);
export async function shareFile(name: string, value: string, type: string) {
  if (Platform.OS === "web") {
    const a = document.createElement("a"),
      url = URL.createObjectURL(new Blob([value], { type }));
    a.href = url;
    a.download = name;
    document.body.appendChild(a);
    a.click();
    a.remove();
    setTimeout(() => URL.revokeObjectURL(url), 3000);
    return;
  }
  const file = new File(Paths.cache, name);
  file.write(value);
  if (!(await Sharing.isAvailableAsync()))
    throw new Error("Sharing unavailable");
  await Sharing.shareAsync(file.uri, { mimeType: type });
}
export const backup = (d: Data) =>
  shareFile(
    `protip365-backup-${iso()}.json`,
    JSON.stringify(d, null, 2),
    "application/json",
  );
export function csv(data: Data) {
  const currency = data.settings.currencyCode ?? "CAD";
  const cell = (v: unknown) => {
    const s = String(v ?? "");
    return (
      '"' + (/^[=+@\-\t\r]/.test(s) ? "'" : "") + s.replace(/"/g, '""') + '"'
    );
  };
  return (
    "\uFEFF" +
    [
      [
        "ID",
        "Date",
        "Job",
        "Role",
        "Start",
        "End",
        "Break minutes",
        "Hours",
        `Wage ${currency}/hour`,
        `Cash ${currency}`,
        `Card ${currency}`,
        `Shared in ${currency}`,
        `Shared out ${currency}`,
        `Other direct tips ${currency}`,
        `Net tips ${currency}`,
        `Sales ${currency}`,
        `Wages ${currency}`,
        "Other income " + currency,
        "Status",
        "Planned",
        "Note",
        "Created",
        "Updated",
      ],
      ...data.shifts.map((s) => {
        const j = data.jobs.find((j) => j.id === s.job);
        const m = (v: number | null) =>
          v === null ? "" : (v / 100).toFixed(2);
        return [
          s.id,
          s.date,
          j?.name,
          j?.role,
          s.start,
          s.end,
          s.brk,
          hours(s),
          m(s.rate),
          m(s.cash),
          m(s.card),
          m(s.tipIn),
          m(s.tipOut),
          m(s.other),
          m(net(s)),
          m(s.sales),
          m(wage(s)),
          m(s.otherIncome ?? null),
          s.status ?? (s.planned ? "planned" : "worked"),
          s.planned ?? false,
          s.note,
          s.createdAt,
          s.updatedAt,
        ];
      }),
    ]
      .map((row) => row.map(cell).join(","))
      .join("\r\n")
  );
}
export async function readBackup() {
  const result = await DocumentPicker.getDocumentAsync({
    type: "application/json",
    copyToCacheDirectory: true,
  });
  if (result.canceled) return null;
  const raw =
    Platform.OS === "web"
      ? await fetch(result.assets[0].uri).then((r) => r.text())
      : await new File(result.assets[0].uri).text();
  const data = JSON.parse(raw);
  if (!validData(data)) throw new Error("Invalid backup");
  return data;
}
export async function statement(
  data: Data,
  shifts: Shift[],
  job: string,
  from: string,
  to: string,
  annual = false,
) {
  const l = data.settings.language,
    currency = data.settings.currencyCode ?? "CAD",
    t = (k: Parameters<typeof text>[0]) => text(k, l);
  const sum = (fn: (s: Shift) => number) =>
    shifts.reduce((v, s) => v + fn(s), 0);
  const rows = annual
    ? data.jobs
        .map((j) => {
          const ss = shifts.filter((s) => s.job === j.id);
          return `<tr><td>${escape(j.name)}</td><td>${money(
            ss.reduce((n, s) => n + net(s), 0),
            l, currency,
          )}</td><td>${money(
            ss.reduce((n, s) => n + wage(s), 0),
            l, currency,
          )}</td></tr>`;
        })
        .join("")
    : shifts
        .map(
          (s) =>
            `<tr><td>${escape(s.date)}</td><td>${s.sales === null ? "—" : money(s.sales, l, currency)}</td><td>${money((s.cash ?? 0) + (s.card ?? 0), l, currency)}</td><td>${money(s.other ?? 0, l, currency)}</td><td>${money(s.tipIn ?? 0, l, currency)}</td><td>${money(s.tipOut ?? 0, l, currency)}</td></tr>`,
        )
        .join("");
  const html = `<!doctype html><html lang="${l}"><head><meta charset="utf-8"><style>body{font-family:Arial;color:#3f2a22;padding:32px}h1{font-family:Georgia;font-size:28px}table{border-collapse:collapse;width:100%;font-size:12px}th,td{padding:10px;border-bottom:1px solid #e7e2d8;text-align:left}.total{background:#e0e5d6;padding:20px;margin:24px 0;font-size:24px}p{line-height:1.5}</style></head><body><h1>ProTip365 — ${escape(t(annual ? "tax" : "statement"))}</h1><p>${escape(data.settings.name)}<br>${escape(job)}<br>${escape(from)} → ${escape(to)}</p><table><thead><tr>${(annual ? [t("employer"), t("net"), l === "fr" ? "Salaire" : "Wages"] : [t("date"), t("sales"), "B", "C", "D", "E"]).map((v) => `<th>${escape(v)}</th>`).join("")}</tr></thead><tbody>${rows}</tbody></table><div class="total">${escape(t(annual ? "net" : "declare"))}: ${money(sum(net), l, currency)}</div><p>${annual ? (l === "fr" ? "Totaux personnels par employeur. Compare avec tes feuillets fiscaux pour éviter de déclarer deux fois les mêmes pourboires." : "Personal totals by employer. Compare with your tax slips to avoid reporting the same tips twice.") : escape(t("statementNote"))}</p><p>${annual ? "https://www.canada.ca/en/revenue-agency/campaigns/track-report-tips-gratuities.html" : RQ}</p></body></html>`;
  if (Platform.OS === "web") {
    const win = window.open("", "_blank");
    if (!win) throw new Error("Pop-up blocked");
    win.document.write(html);
    win.document.close();
    win.print();
    return;
  }
  const result = await Print.printToFileAsync({ html });
  await Sharing.shareAsync(result.uri, {
    mimeType: "application/pdf",
    UTI: "com.adobe.pdf",
  });
}
export async function permission() {
  if (Platform.OS === "web") return false;
  await Notifications.setNotificationChannelAsync("shifts", {
    name: "ProTip365",
    importance: Notifications.AndroidImportance.DEFAULT,
  });
  const current = await Notifications.getPermissionsAsync();
  return (
    current.granted || (await Notifications.requestPermissionsAsync()).granted
  );
}
export async function reminders(data: Data) {
  if (Platform.OS === "web") return;
  const old = await Notifications.getAllScheduledNotificationsAsync();
  for (const n of old)
    if (
      n.identifier.startsWith("protip-shift-") &&
      (!n.identifier.endsWith("-snooze") ||
        !data.settings.reminder ||
        !data.shifts.some(
          (s) =>
            s.planned && n.identifier === "protip-shift-" + s.id + "-snooze",
        ))
    )
      await Notifications.cancelScheduledNotificationAsync(n.identifier);
  if (
    !data.settings.reminder ||
    (await Notifications.getPermissionsAsync()).granted !== true
  )
    return;
  await Notifications.setNotificationCategoryAsync("shift", [
    {
      identifier: "snooze",
      buttonTitle: text("snooze", data.settings.language),
      options: { opensAppToForeground: false },
    },
  ]);
  for (const s of data.shifts.filter((s) => s.planned)) {
    const end = new Date(s.date + "T" + s.end + ":00");
    if (minutes(s.end) <= minutes(s.start)) end.setDate(end.getDate() + 1);
    end.setMinutes(end.getMinutes() + data.settings.offset);
    if (end.getTime() <= Date.now()) continue;
    const j = data.jobs.find((j) => j.id === s.job);
    await Notifications.scheduleNotificationAsync({
      identifier: "protip-shift-" + s.id,
      content: {
        title: j?.name || "ProTip365",
        body: text("notification", data.settings.language),
        data: { shiftId: s.id },
        categoryIdentifier: "shift",
      },
      trigger: {
        type: Notifications.SchedulableTriggerInputTypes.DATE,
        date: end,
        channelId: "shifts",
      },
    });
  }
}
export function onReminder(open: (id: string) => void, canSnooze: (id: string) => boolean = () => true) {
  if (Platform.OS === "web") return () => {};
  Notifications.setNotificationHandler({
    handleNotification: async () => ({
      shouldShowBanner: true,
      shouldShowList: true,
      shouldPlaySound: false,
      shouldSetBadge: false,
    }),
  });
  const act = async (r: Notifications.NotificationResponse) => {
    const id = r.notification.request.content.data?.shiftId;
    if (typeof id !== "string") return;
    if (r.actionIdentifier === "snooze") {
      if (!canSnooze(id)) {
        await Notifications.clearLastNotificationResponseAsync();
        return;
      }
      const d = new Date();
      d.setDate(d.getDate() + 1);
      d.setHours(9, 0, 0, 0);
      await Notifications.scheduleNotificationAsync({
        identifier: "protip-shift-" + id + "-snooze",
        content: {
          title: r.notification.request.content.title,
          body: r.notification.request.content.body,
          data: { shiftId: id },
        },
        trigger: {
          type: Notifications.SchedulableTriggerInputTypes.DATE,
          date: d,
          channelId: "shifts",
        },
      });
    } else open(id);
    await Notifications.clearLastNotificationResponseAsync();
  };
  const sub = Notifications.addNotificationResponseReceivedListener((r) => {
    void act(r).catch(() => {});
  });
  void Notifications.getLastNotificationResponseAsync()
    .then((r) => r && act(r))
    .catch(() => {});
  return () => sub.remove();
}
