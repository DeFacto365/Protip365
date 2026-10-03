import React, { useCallback, useEffect, useRef, useState } from "react";
import {
  ActivityIndicator,
  Alert,
  BackHandler,
  KeyboardAvoidingView,
  Linking,
  Platform,
  Pressable,
  ScrollView,
  View,
  Modal,
} from "react-native";
import { SafeAreaProvider, SafeAreaView } from "react-native-safe-area-context";
import { useFonts } from "expo-font";
import { Fraunces_500Medium } from "@expo-google-fonts/fraunces/500Medium";
import { Fraunces_600SemiBold } from "@expo-google-fonts/fraunces/600SemiBold";
import { WorkSans_400Regular } from "@expo-google-fonts/work-sans/400Regular";
import { WorkSans_500Medium } from "@expo-google-fonts/work-sans/500Medium";
import { WorkSans_600SemiBold } from "@expo-google-fonts/work-sans/600SemiBold";
import { randomUUID } from "expo-crypto";
import {
  Home,
  CalendarDays,
  Plus,
  ChartNoAxesColumn,
  User,
  ArrowLeft,
  Check,
  ChevronLeft,
  ChevronRight,
} from "lucide-react-native";
import { StatusBar } from "expo-status-bar";
import {
  Data,
  Job,
  Shift,
  addDays,
  amount,
  colors,
  hourly,
  hours,
  inRange,
  iso,
  localDate,
  net,
  range,
  salesCheck,
  totals,
  validDate,
  weekStart,
} from "./domain";
import { fresh, load, save } from "./storage";
import { CopyKey, text, roleLabel } from "./copy";
import {
  backup,
  csv,
  onReminder,
  permission,
  readBackup,
  reminders,
  shareFile,
  statement,
  RQ,
} from "./platform";
import {
  Button,
  Card,
  Chips,
  Field,
  Leaf,
  Logo,
  Toggle,
  Txt,
  C,
  s,
} from "./ui";
import { DateField, HoursForm, JobForm, TipsForm } from "./forms";
import {BillingHost, AccessSheet, useAccess} from './billing/access';
type Screen =
  | "welcome"
  | "job"
  | "setup"
  | "home"
  | "calendar"
  | "stats"
  | "me"
  | "hours"
  | "tips"
  | "saved"
  | "statement";
const systemConfirm = (
  title: string,
  message: string,
  accept: string,
  cancel: string,
) =>
  new Promise<boolean>((resolve) =>
    Platform.OS === "web"
      ? resolve(window.confirm(title + "\n" + message))
      : Alert.alert(
          title,
          message,
          [
            { text: cancel, style: "cancel", onPress: () => resolve(false) },
            { text: accept, onPress: () => resolve(true) },
          ],
          { cancelable: true, onDismiss: () => resolve(false) },
        ),
  );
export default function App() {
  return (
    <SafeAreaProvider>
      <BillingHost />
      <Main />
    </SafeAreaProvider>
  );
}
function Main() {
  const access = useAccess();
  const [accessVisible, showAccess] = useState(false);
  const [fonts, errorFonts] = useFonts({
    Fraunces_500Medium,
    Fraunces_600SemiBold,
    WorkSans_400Regular,
    WorkSans_500Medium,
    WorkSans_600SemiBold,
  });
  const [data, D] = useState<Data | null>(null),
    [screen, S] = useState<Screen>("welcome"),
    [fatal, F] = useState(false),
    [busy, Q] = useState(false),
    [editingJob, J] = useState<Job | undefined>(),
    [draft, V] = useState<Shift | null>(null),
    [saved, Z] = useState<Shift | null>(null),
    [previous, P] = useState<Data | null>(null),
    [day, Y] = useState(iso()),
    [month, M] = useState(iso().slice(0, 7) + "-01"),
    [statsRange, R] = useState<"week" | "month" | "year">("week"),
    [statementJob, K] = useState(""),
    [from, A] = useState(""),
    [to, B] = useState(""),
    [goal, G] = useState(""),
    [notice, N] = useState(""),
    [nameDraft, ND] = useState("");
  const [planning, setPlanning] = useState(false);
  const [confirmation, setConfirmation] = useState<{
    title: string;
    message: string;
    accept: string;
    cancel: string;
    resolve: (yes: boolean) => void;
  } | null>(null);
  const confirm = (
    title: string,
    message: string,
    accept: string,
    cancel: string,
  ): Promise<boolean> =>
    Platform.OS === "web"
      ? new Promise((resolve) =>
          setConfirmation({ title, message, accept, cancel, resolve }),
        )
      : systemConfirm(title, message, accept, cancel);
  const answerConfirmation = (yes: boolean) => {
    confirmation?.resolve(yes);
    setConfirmation(null);
  };
  const reference = useRef(data);
  reference.current = data;
  const scroll = useRef<ScrollView>(null);
  const loaded = useCallback(async () => {
    F(false);
    try {
      const value = await load();
      D(value);
      ND(value.settings.name);
      S(value.onboarded ? "home" : "welcome");
      G(value.settings.goal === null ? "" : String(value.settings.goal / 100));
    } catch {
      F(true);
    }
  }, []);
  useEffect(() => {
    void loaded();
  }, [loaded]);
  useEffect(() => {
    scroll.current?.scrollTo({ y: 0, animated: false });
  }, [screen]);
  const t = (key: CopyKey) => text(key, data?.settings.language ?? "fr");
  const money = (n: number | null) =>
    n === null
      ? "—"
      : new Intl.NumberFormat(
          data?.settings.language === "fr" ? "fr-CA" : "en-CA",
          { style: "currency", currency: "CAD" },
        ).format(n / 100);
  const fmt = (
    d: string,
    options: Intl.DateTimeFormatOptions = { month: "short", day: "numeric" },
  ) =>
    localDate(d).toLocaleDateString(
      data?.settings.language === "fr" ? "fr-CA" : "en-CA",
      options,
    );
  const commit = async (next: Data, recovery = false) => {
    if (!recovery && data && (next.jobs !== data.jobs || next.shifts !== data.shifts)) {
      useAccess.getState().refresh();
      if (!useAccess.getState().canWrite) {showAccess(true); throw new Error('access_required');}
    }
    await save(next);
    D(next);
  };
  const safe = (fn: () => Promise<void>, failure: CopyKey = "storageError") => {
    Q(true);
    void fn()
      .catch(error => {if (error?.message !== 'access_required') Alert.alert(t("error"), t(failure));})
      .finally(() => Q(false));
  };
  const updateSettings = async (values: Partial<Data["settings"]>) => {
    if (data)
      await commit({ ...data, settings: { ...data.settings, ...values } });
  };
  const begin = (date = iso(), shift?: Shift, planned = false) => {
    useAccess.getState().refresh();
    if (!useAccess.getState().canWrite) {showAccess(true); return;}
    const d = reference.current;
    if (!d) return;
    const last = d.shifts
        .filter((x) => !x.planned)
        .sort((a, b) => b.updatedAt.localeCompare(a.updatedAt))[0],
      scheduled = d.shifts.find((s) => s.date === date && s.planned),
      source = shift ?? scheduled;
    const job =
      d.jobs.find((j) => j.id === (source?.job ?? last?.job) && !j.archived) ??
      d.jobs.find((j) => !j.archived);
    if (!job) {
      J(undefined);
      S("job");
      return;
    }
    const now = new Date().toISOString();
    setPlanning(planned || (!!shift?.planned && shift.date > iso()));
    V(
      source
        ? { ...source, planned: planned || source.planned }
        : {
            id: randomUUID(),
            job: job.id,
            date,
            start: last?.job === job.id ? last.start : job.start,
            end: last?.job === job.id ? last.end : job.end,
            brk: last?.job === job.id ? last.brk : job.brk,
            cash: null,
            card: null,
            tipIn: null,
            tipOut: null,
            sales: null,
            other: null,
            note: "",
            rate: job.rate,
            planned,
            createdAt: now,
            updatedAt: now,
          },
    );
    S("hours");
  };
  useEffect(
    () => {
      if (!data) return;
      return onReminder((id) => {
        const d = reference.current,
          s = d?.shifts.find((s) => s.id === id);
        if (s) begin(s.date, s);
      }, id => !!reference.current?.settings.reminder && !!reference.current?.shifts.some(s => s.id === id && s.planned));
    },
    [!!data],
  );
  useEffect(() => {
    if (data)
      void reminders(data).catch(() =>
        N(text("notifyError", data.settings.language)),
      );
  }, [data]);
  useEffect(() => {
    const sub = BackHandler.addEventListener("hardwareBackPress", () => {
      if (["home", "welcome"].includes(screen)) return false;
      goBack();
      return true;
    });
    return () => sub.remove();
  }, [screen]);
  const goBack = () =>
    S(
      screen === "tips"
        ? "hours"
        : data?.onboarded
          ? "home"
          : screen === "setup"
            ? "job"
            : "welcome",
    );
  const remove = async (shift: Shift) => {
    if (
      !data ||
      !(await confirm(
        t("delete"),
        t("deleteConfirm"),
        t("delete"),
        t("cancel"),
      ))
    )
      return;
    P(data);
    await commit({
      ...data,
      shifts: data.shifts.filter((s) => s.id !== shift.id),
    }, true);
    S("calendar");
  };
  const undo = async () => {
    if (previous) {
      await commit(previous, true);
      P(null);
      S("home");
    }
  };
  if (fatal || errorFonts)
    return (
      <SafeAreaView
        style={[s.screen, { justifyContent: "center", padding: 24, gap: 20 }]}
      >
        <Txt>{t("loadError")}</Txt>
        <Button label={t("retry")} onPress={() => void loaded()} />
      </SafeAreaView>
    );
  if (!data || !fonts)
    return (
      <SafeAreaView style={[s.screen, { justifyContent: "center" }]}>
        <ActivityIndicator color={C.green} />
      </SafeAreaView>
    );
  const today = iso(),
    [wf, wt] = range("week", today, data.settings.weekStart),
    weekly = inRange(data.shifts, wf, wt),
    weekTotals = totals(weekly),
    [mf, mt] = range("month", today, data.settings.weekStart),
    monthly = inRange(data.shifts, mf, mt);
  const jobOf = (shift: Shift) => data.jobs.find((j) => j.id === shift.job)!;
  const metric = (
    label: string,
    value: string,
    hint?: string,
    tint = C.paper,
  ) => (
    <Card tint={tint} style={{ flex: 1 }}>
      <Txt kind="small">{label}</Txt>
      <Txt kind="section">{value}</Txt>
      {!!hint && <Txt kind="small">{hint}</Txt>}
    </Card>
  );
  const shiftRows = (shifts: Shift[]) =>
    shifts.map((shift) => (
      <Pressable
        key={shift.id}
        accessibilityRole="button"
        onPress={() => begin(shift.date, shift, !!shift.planned)}
        style={s.listItem}
      >
        <View style={s.row}>
          <View
            style={[s.dot, { backgroundColor: jobOf(shift)?.color ?? C.sage }]}
          />
          <View style={{ flex: 1 }}>
            <Txt>{jobOf(shift)?.name}</Txt>
            <Txt kind="small">
              {fmt(shift.date)} ·{" "}
              {hours(shift).toLocaleString(undefined, {
                maximumFractionDigits: 2,
              })}{" "}
              h{shift.planned ? " · " + t("planned") : ""}
            </Txt>
          </View>
          <View style={{ alignItems: "flex-end" }}>
            <Txt>{shift.planned ? "—" : money(net(shift))}</Txt>
            {!shift.planned && <Txt kind="small">{money(hourly(shift))}/h</Txt>}
          </View>
        </View>
      </Pressable>
    ));
  const check = (shifts: Shift[]) => {
    const p = salesCheck(shifts);
    return p !== null && p < 8 ? (
      <Card tint={C.blush}>
        <Txt kind="small">
          {t("eight")} ({p.toFixed(1)} %)
        </Txt>
        <Txt kind="small">{t("eightHint")}</Txt>
        <Button
          small
          secondary
          label="Revenu Québec"
          onPress={() => void Linking.openURL(RQ)}
        />
      </Card>
    ) : null;
  };
  const weekDays = Array.from({ length: 7 }, (_, i) => {
    const n = (i + 1) % 7;
    return {
      value: String(n),
      label: fmt(addDays("2026-09-27", n), { weekday: "short" }),
    };
  });
  const setup = (
    <>
      <Txt kind="title">{t("weekTitle")}</Txt>
      <Txt>{t("weekStart")}</Txt>
      <Txt kind="small">{t("weekHint")}</Txt>
      <Chips
        value={String(data.settings.weekStart)}
        items={weekDays}
        onChange={(v) => safe(() => updateSettings({ weekStart: Number(v) }))}
      />
      <Toggle
        label={t("reminder")}
        hint={t("reminderHint")}
        value={data.settings.reminder}
        onChange={(value) =>
          safe(async () => {
            if (value && !(await permission())) {
              N(t("reminderDenied"));
              return;
            }
            await updateSettings({ reminder: value });
          })
        }
      />
      <Field label={t("goal")} money value={goal} onChange={G} />
      <Button
        disabled={busy}
        label={t("done")}
        onPress={() =>
          safe(async () => {
            const n = amount(goal);
            if (n === undefined) {
              Alert.alert(t("error"), t("invalid"));
              return;
            }
            const granted = data.settings.reminder ? await permission() : false;
            await commit({
              ...data,
              onboarded: true,
              settings: { ...data.settings, goal: n, reminder: granted },
            });
            S("home");
          })
        }
      />
    </>
  );
  const openStatement = () => {
    K(data.jobs[0]?.id ?? "");
    A(addDays(wf, -7));
    B(addDays(wf, -1));
    S("statement");
  };
  let content: React.ReactNode;
  switch (screen) {
    case "welcome":
      content = (
        <>
          <Card tint={C.soft} style={{ padding: 28 }}>
            <Leaf />
            <Logo size={88} />
            <Txt kind="title" style={{ fontSize: 38, lineHeight: 46 }}>
              {t("title")}
            </Txt>
            <Txt>{t("promise")}</Txt>
          </Card>
          <Chips
            value={data.settings.language}
            items={[
              { value: "fr", label: "Français" },
              { value: "en", label: "English" },
            ]}
            onChange={(v) =>
              safe(() => updateSettings({ language: v as "fr" | "en" }))
            }
          />
          <Button
            label={t("start")}
            onPress={() => {
              J(undefined);
              S("job");
            }}
          />
          <Button
            secondary
            label={t("import")}
            onPress={() => Alert.alert(t("import"), t("importSoon"))}
          />
          <Txt kind="small" style={{ textAlign: "center" }}>
            {t("privacy")}
          </Txt>
          <Button
            secondary
            label={t("restore")}
            disabled={busy}
            onPress={() =>
              safe(async () => {
                const restored = await readBackup();
                if (
                  restored &&
                  (await confirm(
                    t("restore"),
                    t("restoreConfirm"),
                    t("continue"),
                    t("cancel"),
                  ))
                ) {
                  await backup(data);
                  await commit(restored, true);
                  G(
                    restored.settings.goal === null
                      ? ""
                      : String(restored.settings.goal / 100),
                  );
                  S(restored.onboarded ? "home" : "welcome");
                }
              }, "restoreError")
            }
          />
        </>
      );
      break;
    case "job":
      content = (
        <>
          <JobForm
            key={editingJob?.id ?? "new"}
            t={t}
            index={data.jobs.length}
            initial={editingJob}
            onSave={async (j) => {
              const job = { ...j, id: editingJob?.id ?? randomUUID() };
              await commit({
                ...data,
                jobs: editingJob
                  ? data.jobs.map((x) => (x.id === job.id ? job : x))
                  : [...data.jobs, job],
              });
              S(data.onboarded ? "me" : "setup");
            }}
          />
          {editingJob && (
            <Button
              secondary
              label={t("archive")}
              onPress={() =>
                safe(async () => {
                  await commit({
                    ...data,
                    jobs: data.jobs.map((j) =>
                      j.id === editingJob.id ? { ...j, archived: true } : j,
                    ),
                  });
                  S("me");
                })
              }
            />
          )}
        </>
      );
      break;
    case "setup":
      content = setup;
      break;
    case "home": {
      const recent = data.shifts
        .filter((s) => !s.planned)
        .sort(
          (a, b) =>
            b.date.localeCompare(a.date) ||
            b.createdAt.localeCompare(a.createdAt),
        )
        .slice(0, 5);
      content = (
        <>
          <View style={s.row}>
            <Logo size={34} />
            <Txt>
              {t("hello")}
              {data.settings.name ? " " + data.settings.name : ""}
            </Txt>
          </View>
          <Card tint={C.soft} style={{ borderRadius: 26, padding: 24 }}>
            <Leaf />
            <Txt kind="eyebrow">{t("tipsWeek")}</Txt>
            <Txt kind="small">
              {t("week")} · {fmt(wf)}
            </Txt>
            <Txt kind="display" adjustsFontSizeToFit numberOfLines={1}>
              {money(weekTotals.tips)}
            </Txt>
            <Txt kind="small">
              {t("net")} · {weekly.length}{" "}
              {t(weekly.length === 1 ? "loggedOne" : "logged")}
            </Txt>
            {data.settings.goal !== null && data.settings.goal > 0 && (
              <>
                <View
                  style={{
                    height: 6,
                    borderRadius: 3,
                    backgroundColor: C.sand,
                    overflow: "hidden",
                  }}
                >
                  <View
                    style={{
                      height: 6,
                      width: `${Math.max(0, Math.min(100, (100 * weekTotals.tips) / data.settings.goal))}%`,
                      backgroundColor: C.green,
                    }}
                  />
                </View>
                <Txt kind="small">
                  {Math.round((100 * weekTotals.tips) / data.settings.goal)} %{" "}
                  {t("goalProgress")} {money(data.settings.goal)}
                </Txt>
              </>
            )}
            <Button label={"+ " + t("add")} onPress={() => begin()} />
          </Card>
          <View style={s.split}>
            {metric(
              t("month"),
              money(totals(monthly).tips),
              undefined,
              C.blush,
            )}
            {metric(
              t("hourly"),
              money(weekTotals.rate),
              t("hourlyHint"),
              C.soft,
            )}
          </View>
          <Txt kind="section">{t("recent")}</Txt>
          {recent.length ? (
            shiftRows(recent)
          ) : (
            <Card>
              <Txt>{t("empty")}</Txt>
            </Card>
          )}
          {data.shifts
            .filter((s) => s.planned && s.date >= today)
            .sort((a, b) => a.date.localeCompare(b.date))
            .slice(0, 1)
            .map((s) => (
              <Card key={s.id}>
                <Txt kind="eyebrow">{t("planned")}</Txt>
                <Txt>
                  {jobOf(s)?.name} · {fmt(s.date)}
                </Txt>
                <Txt kind="small">
                  {s.start} → {s.end}
                </Txt>
                <Button
                  secondary
                  label={t("edit")}
                  onPress={() => begin(s.date, s, true)}
                />
              </Card>
            ))}
        </>
      );
      break;
    }
    case "hours":
      content = draft ? (
        <>
          <HoursForm
            draft={draft}
            jobs={data.jobs}
            t={t}
            onDraft={V}
            planned={planning}
            onNext={() => {
              if (planning)
                safe(async () => {
                  P(data);
                  await commit({
                    ...data,
                    shifts: [
                      ...data.shifts.filter((s) => s.id !== draft.id),
                      { ...draft, planned: true, updatedAt: new Date().toISOString() },
                    ],
                  });
                  S("calendar");
                });
              else S("tips");
            }}
          />
          {data.shifts.some((s) => s.id === draft.id) && (
            <Button
              secondary
              label={t("delete")}
              onPress={() => safe(() => remove(draft))}
            />
          )}
        </>
      ) : null;
      break;
    case "tips":
      content = draft ? (
        <TipsForm
          key={draft.id}
          draft={draft}
          job={jobOf(draft)}
          t={t}
          money={money}
          onSave={async (shift) => {
            P(data);
            await commit({
              ...data,
              shifts: [...data.shifts.filter((s) => s.id !== shift.id), shift],
            });
            Z(shift);
            S("saved");
          }}
        />
      ) : null;
      break;
    case "saved": {
      if (!saved) {
        S("home");
        break;
      }
      const history = data.shifts.filter(
          (s) =>
            s.id !== saved.id &&
            s.job === saved.job &&
            !s.planned &&
            localDate(s.date).getDay() === localDate(saved.date).getDay(),
        ),
        difference = history.length
          ? net(saved) -
            Math.round(history.reduce((n, s) => n + net(s), 0) / history.length)
          : 0;
      content = (
        <>
          <View style={{ alignItems: "center", gap: 18, padding: 24 }}>
            <View
              style={{ backgroundColor: C.soft, borderRadius: 40, padding: 20 }}
            >
              <Check size={40} color={C.green} />
            </View>
            <Txt kind="title">{t("saved")}</Txt>
            <Txt kind="small">
              {jobOf(saved)?.name} · {fmt(saved.date)}
            </Txt>
          </View>
          <Card tint={C.soft}>
            <Txt>{t("net")}</Txt>
            <Txt kind="display" adjustsFontSizeToFit numberOfLines={1}>
              {money(net(saved))}
            </Txt>
          </Card>
          <View style={s.split}>
            {metric(t("hourly"), money(hourly(saved)), t("hourlyHint"))}
            {metric(t("hours"), hours(saved) + " h")}
          </View>
          {difference > 0 && (
            <Txt>
              {money(difference)} {t("comparison")}
            </Txt>
          )}
          {check([saved])}
          <Button label={t("done")} onPress={() => S("home")} />
          <Button
            secondary
            label={t("undo")}
            disabled={!previous || busy}
            onPress={() => safe(undo)}
          />
          <Button
            secondary
            label={t("edit")}
            onPress={() => begin(saved.date, saved)}
          />
        </>
      );
      break;
    }
    case "calendar": {
      const md = localDate(month),
        start = weekStart(month, data.settings.weekStart),
        cells = Array.from({ length: 42 }, (_, i) => addDays(start, i)),
        selected = data.shifts.filter((s) => s.date === day),
        monthEnd = iso(new Date(md.getFullYear(), md.getMonth() + 1, 0));
      content = (
        <>
          <View style={s.row}>
            <Pressable
              accessibilityRole="button"
              style={{ padding: 12 }}
              accessibilityLabel={t("previousMonth")}
              onPress={() =>
                M(iso(new Date(md.getFullYear(), md.getMonth() - 1, 1)))
              }
            >
              <ChevronLeft color={C.ink} />
            </Pressable>
            <Txt kind="section" style={{ flex: 1, textAlign: "center" }}>
              {fmt(month, { month: "long", year: "numeric" })}
            </Txt>
            <Pressable
              accessibilityRole="button"
              style={{ padding: 12 }}
              accessibilityLabel={t("nextMonth")}
              onPress={() =>
                M(iso(new Date(md.getFullYear(), md.getMonth() + 1, 1)))
              }
            >
              <ChevronRight color={C.ink} />
            </Pressable>
          </View>
          <Txt kind="section">
            {money(totals(inRange(data.shifts, month, monthEnd)).tips)}
          </Txt>
          <View style={s.wrap}>
            {data.jobs.map((j) => (
              <View key={j.id} style={s.row}>
                <View style={[s.dot, { backgroundColor: j.color }]} />
                <Txt kind="small">{j.name}</Txt>
              </View>
            ))}
          </View>
          <View style={{ flexDirection: "row" }}>
            {Array.from({ length: 7 }, (_, i) =>
              fmt(addDays(start, i), { weekday: "narrow" }),
            ).map((v, i) => (
              <Txt
                key={i}
                kind="small"
                style={{ width: "14.285%", textAlign: "center" }}
              >
                {v}
              </Txt>
            ))}
          </View>
          <View style={{ flexDirection: "row", flexWrap: "wrap" }}>
            {cells.map((d) => {
              const ss = data.shifts.filter((s) => s.date === d && !s.planned),
                jobs = [
                  ...new Set(
                    data.shifts.filter((s) => s.date === d).map((s) => s.job),
                  ),
                ],
                n = ss.reduce((v, s) => v + net(s), 0);
              return (
                <Pressable
                  accessibilityRole="button"
                  accessibilityLabel={
                    fmt(d, { weekday: "long", month: "long", day: "numeric" }) +
                    " " +
                    money(n)
                  }
                  key={d}
                  onPress={() => Y(d)}
                  style={{
                    width: "14.285%",
                    minHeight: 76,
                    borderRadius: 12,
                    borderWidth: d === today ? 1 : 0,
                    borderColor: C.sage,
                    backgroundColor: d === day ? C.ink : undefined,
                    paddingTop: 9,
                    opacity: d.slice(0, 7) === month.slice(0, 7) ? 1 : 0.35,
                    alignItems: "center",
                    gap: 3,
                  }}
                >
                  <Txt
                    style={{ fontSize: 14, color: d === day ? C.bg : C.ink }}
                  >
                    {localDate(d).getDate()}
                  </Txt>
                  {ss.length > 0 && (
                    <Txt
                      style={{ fontSize: 10, color: d === day ? C.bg : C.ink }}
                    >
                      {money(n).replace(/[,.]00/g, "")}
                    </Txt>
                  )}
                  <View style={{ flexDirection: "row", gap: 3 }}>
                    {jobs.map((id) => (
                      <View
                        key={id}
                        style={{
                          width: 5,
                          height: 5,
                          borderRadius: 3,
                          backgroundColor: data.jobs.find((j) => j.id === id)
                            ?.color,
                        }}
                      />
                    ))}
                  </View>
                </Pressable>
              );
            })}
          </View>
          <Txt kind="section">
            {fmt(day, { weekday: "long", month: "short", day: "numeric" })}
          </Txt>
          {selected.length ? (
            shiftRows(selected)
          ) : (
            <Txt kind="small">{t("noShift")}</Txt>
          )}
          <Button label={t("addDay")} onPress={() => begin(day)} />
          <Button
            secondary
            label={t("plan")}
            onPress={() => begin(day < today ? today : day, undefined, true)}
          />
        </>
      );
      break;
    }
    case "stats": {
      const [from, to] = range(statsRange, today, data.settings.weekStart),
        ss = inRange(data.shifts, from, to),
        total = totals(ss),
        days = Array.from({ length: 7 }, (_, i) => addDays(wf, i)),
        bars = days.map((d) => totals(inRange(data.shifts, d, d)).tips),
        max = Math.max(1, ...bars);
      const averages = Array.from({ length: 7 }, (_, n) => {
        const rows = data.shifts.filter(
          (s) => !s.planned && localDate(s.date).getDay() === n,
        );
        return {
          n,
          avg: rows.length ? totals(rows).tips / rows.length : 0,
          count: rows.length,
        };
      })
        .filter((x) => x.count)
        .sort((a, b) => b.avg - a.avg);
      content = (
        <>
          <Txt kind="title">{t("stats")}</Txt>
          <Chips
            value={statsRange}
            onChange={(v) => R(v as typeof statsRange)}
            items={["week", "month", "year"].map((v) => ({
              value: v,
              label: t(v as CopyKey),
            }))}
          />
          <Card tint={C.soft}>
            <Txt>{t("net")}</Txt>
            <Txt kind="display" numberOfLines={1} adjustsFontSizeToFit>
              {money(total.tips)}
            </Txt>
            <Txt kind="small">
              {ss.length} {t(ss.length === 1 ? "loggedOne" : "logged")} ·{" "}
              {total.h.toFixed(1)} h
            </Txt>
            <Txt kind="small">
              {t("hourlyHint")}: {money(total.pay)}
            </Txt>
          </Card>
          <View style={s.split}>
            {metric(t("hourly"), money(total.rate))}
            {metric(t("average"), money(total.average))}
          </View>
          {statsRange === "week" && (
            <View
              style={{
                flexDirection: "row",
                height: 170,
                alignItems: "flex-end",
                gap: 5,
              }}
            >
              {days.map((d, i) => (
                <View key={d} style={{ flex: 1, alignItems: "center", gap: 6 }}>
                  <Txt style={{ fontSize: 10 }}>
                    {Math.round(bars[i] / 100)}
                  </Txt>
                  <View
                    style={{
                      height: Math.max(2, (110 * Math.max(0, bars[i])) / max),
                      width: "70%",
                      backgroundColor: d === today ? C.clay : C.sage,
                      borderRadius: 5,
                    }}
                  />
                  <Txt kind="small">{fmt(d, { weekday: "narrow" })}</Txt>
                </View>
              ))}
            </View>
          )}
          <Txt kind="section">{t("byJob")}</Txt>
          {data.jobs.map((j) => {
            const tips = totals(ss.filter((s) => s.job === j.id)).tips;
            return (
              <View key={j.id} style={{ gap: 6 }}>
                <View style={s.row}>
                  <Txt style={{ flex: 1 }}>{j.name}</Txt>
                  <Txt>{money(tips)}</Txt>
                </View>
                <View
                  style={{
                    height: 7,
                    backgroundColor: C.paper,
                    borderRadius: 4,
                  }}
                >
                  <View
                    style={{
                      height: 7,
                      borderRadius: 4,
                      width: `${Math.max(0, Math.min(100, total.tips ? (100 * tips) / total.tips : 0))}%`,
                      backgroundColor: j.color,
                    }}
                  />
                </View>
              </View>
            );
          })}
          {averages[0] && (
            <Card>
              <Txt>
                {t("bestDay")}:{" "}
                {fmt(addDays("2026-09-27", averages[0].n), { weekday: "long" })}
              </Txt>
              <Txt kind="section">{money(Math.round(averages[0].avg))}</Txt>
              <Txt kind="small">{t("average")}</Txt>
            </Card>
          )}
          {check(ss)}
        </>
      );
      break;
    }
    case "me":
      content = (
        <>
          <Txt kind="title">{t("me")}</Txt>
          <Txt kind="section">{t("myJobs")}</Txt>
          {data.jobs
            .filter((j) => !j.archived)
            .map((j) => (
              <Pressable
                accessibilityRole="button"
                key={j.id}
                onPress={() => {
                  J(j);
                  S("job");
                }}
              >
                <Card>
                  <View style={s.row}>
                    <View style={[s.dot, { backgroundColor: j.color }]} />
                    <View style={{ flex: 1 }}>
                      <Txt>{j.name}</Txt>
                      <Txt kind="small">
                        {roleLabel(j.role, t)} · {money(j.rate)}/h
                      </Txt>
                    </View>
                    <Txt kind="small">{t("edit")}</Txt>
                  </View>
                </Card>
              </Pressable>
            ))}
          <Button
            secondary
            label={t("addJob")}
            onPress={() => {
              J(undefined);
              S("job");
            }}
          />
          <Txt kind="section">{t("paperwork")}</Txt>
          <Button secondary label={t("statement")} onPress={openStatement} />
          <Button
            secondary
            disabled={busy}
            label={t("tax")}
            onPress={() =>
              safe(
                () =>
                  statement(
                    data,
                    inRange(
                      data.shifts,
                      today.slice(0, 4) + "-01-01",
                      today.slice(0, 4) + "-12-31",
                    ),
                    "Tous / All",
                    today.slice(0, 4) + "-01-01",
                    today.slice(0, 4) + "-12-31",
                    true,
                  ),
                "exportError",
              )
            }
          />
          <Button
            secondary
            disabled={busy}
            label={t("csv")}
            onPress={() =>
              safe(
                () =>
                  shareFile(
                    `protip365-shifts-${today}.csv`,
                    csv(data),
                    "text/csv",
                  ),
                "exportError",
              )
            }
          />
          <Txt kind="section">{t("backup")}</Txt>
          <Txt kind="small">{t("backupHint")}</Txt>
          <Button
            secondary
            disabled={busy}
            label={t("backup")}
            onPress={() => safe(() => backup(data), "exportError")}
          />
          <Button
            secondary
            disabled={busy}
            label={t("restore")}
            onPress={() =>
              safe(async () => {
                const restored = await readBackup();
                if (
                  restored &&
                  (await confirm(
                    t("restore"),
                    t("restoreConfirm"),
                    t("continue"),
                    t("cancel"),
                  ))
                ) {
                  await backup(data);
                  P(data);
                  await commit(restored, true);
                  G(
                    restored.settings.goal === null
                      ? ""
                      : String(restored.settings.goal / 100),
                  );
                  S("home");
                }
              }, "restoreError")
            }
          />
          <Txt kind="section">{t("settings")}</Txt>
          <Button
            secondary
            disabled={busy}
            label={t("eraseRecords")}
            onPress={() => safe(async () => {
              if (!(await confirm(t("eraseRecords"), t("eraseRecordsConfirm"), t("delete"), t("cancel")))) return;
              const empty = fresh();
              empty.settings.language = data.settings.language;
              await commit(empty, true);
              P(data);
              ND(""); G(""); N("");
              S("welcome");
            })}
          />
          {Platform.OS !== 'web' && <Button secondary label={t('accessTitle')} onPress={() => showAccess(true)}/>}
          <Field
            label={t("nameUser")}
            value={nameDraft}
            onChange={ND}
            onBlur={() => safe(() => updateSettings({ name: nameDraft }))}
          />
          <Chips
            value={data.settings.language}
            items={[
              { value: "fr", label: "Français" },
              { value: "en", label: "English" },
            ]}
            onChange={(v) =>
              safe(() => updateSettings({ language: v as "fr" | "en" }))
            }
          />
          <Txt>{t("weekStart")}</Txt>
          <Chips
            value={String(data.settings.weekStart)}
            items={weekDays}
            onChange={(v) =>
              safe(() => updateSettings({ weekStart: Number(v) }))
            }
          />
          <Toggle
            label={t("reminder")}
            hint={t("reminderHint")}
            value={data.settings.reminder}
            onChange={(reminder) =>
              safe(async () => {
                if (reminder && !(await permission())) {
                  N(t("reminderDenied"));
                  return;
                }
                await updateSettings({ reminder });
              })
            }
          />
          <Field label={t("goal")} value={goal} money onChange={G} />
          <Button
            secondary
            label={t("saveGoal")}
            onPress={() =>
              safe(async () => {
                const value = amount(goal);
                if (value === undefined) {
                  Alert.alert(t("error"), t("invalid"));
                  return;
                }
                await updateSettings({ goal: value });
              })
            }
          />
          {(["privacyLink", "terms", "help"] as const).map((k, i) => (
            <Button
              secondary
              key={k}
              label={t(k)}
              onPress={() =>
                void Linking.openURL(
                  "https://www.protip365.com/" +
                    ["privacy", "terms", "support"][i],
                )
              }
            />
          ))}
        </>
      );
      break;
    case "statement": {
      const ss = inRange(data.shifts, from, to).filter(
        (s) => s.job === statementJob,
      );
      content = (
        <>
          <Txt kind="title">{t("statement")}</Txt>
          <Chips
            value={statementJob}
            items={data.jobs.map((j) => ({ value: j.id, label: j.name }))}
            onChange={K}
          />
          <View style={s.split}>
            <View style={{ flex: 1 }}>
              <DateField label={t("from")} value={from} onChange={A} />
            </View>
            <View style={{ flex: 1 }}>
              <DateField label={t("to")} value={to} onChange={B} />
            </View>
          </View>
          <Card tint={C.soft}>
            <Txt>{t("declare")}</Txt>
            <Txt kind="display" numberOfLines={1} adjustsFontSizeToFit>
              {money(totals(ss).tips)}
            </Txt>
            <Txt kind="small">B + C + D − E</Txt>
          </Card>
          <ScrollView horizontal>
            <View>
              <View style={[s.row, { minWidth: 500 }]}>
                {[t("date"), t("sales"), "B", "C", "D", "E"].map((v, i) => (
                  <Txt key={i} style={{ width: 75, fontSize: 13 }}>
                    {v}
                  </Txt>
                ))}
              </View>
              {ss.map((entry) => (
                <View key={entry.id} style={[s.row, s.listItem]}>
                  {[
                    entry.date,
                    money(entry.sales),
                    money((entry.cash ?? 0) + (entry.card ?? 0)),
                    money(entry.other ?? 0),
                    money(entry.tipIn ?? 0),
                    money(entry.tipOut ?? 0),
                  ].map((v, i) => (
                    <Txt key={i} style={{ width: 75, fontSize: 12 }}>
                      {v}
                    </Txt>
                  ))}
                </View>
              ))}
            </View>
          </ScrollView>
          {check(ss)}
          <Button
            label={t("pdf")}
            disabled={busy}
            onPress={() =>
              safe(async () => {
                if (!validDate(from) || !validDate(to) || from > to) {
                  Alert.alert(t("error"), t("invalidTime"));
                  return;
                }
                await statement(
                  data,
                  ss,
                  data.jobs.find((j) => j.id === statementJob)?.name ?? "",
                  from,
                  to,
                );
              }, "exportError")
            }
          />
          <Txt kind="small">{t("statementNote")}</Txt>
        </>
      );
      break;
    }
  }
  const main = ["home", "calendar", "stats", "me"].includes(screen);
  return (
    <SafeAreaView style={s.screen}>
      <AccessSheet visible={accessVisible} onClose={() => showAccess(false)} t={t} onMessage={N}/>
      <Modal
        visible={!!confirmation}
        transparent
        animationType="fade"
        onRequestClose={() => answerConfirmation(false)}
      >
        <View
          style={{
            flex: 1,
            backgroundColor: "rgba(63,42,34,0.4)",
            justifyContent: "center",
            alignItems: "center",
            padding: 24,
          }}
        >
          <Card style={{ width: "100%", maxWidth: 440 }}>
            <Txt kind="title">{confirmation?.title}</Txt>
            <Txt>{confirmation?.message}</Txt>
            <Button
              label={confirmation?.accept ?? t("done")}
              onPress={() => answerConfirmation(true)}
            />
            <Button
              secondary
              label={confirmation?.cancel ?? t("cancel")}
              onPress={() => answerConfirmation(false)}
            />
          </Card>
        </View>
      </Modal>
      <StatusBar style="dark" />
      <KeyboardAvoidingView
        style={{ flex: 1 }}
        behavior={Platform.OS === "ios" ? "padding" : Platform.OS === "android" ? "height" : undefined}
      >
        {!main && screen !== "welcome" && (
          <View style={s.toolbar}>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={t("back")}
              onPress={goBack}
              style={{ padding: 8 }}
            >
              <ArrowLeft color={C.ink} />
            </Pressable>
            <Txt kind="small">protip365</Txt>
            <Logo size={28} />
          </View>
        )}
        {screen === "tips" ? (
          content
        ) : (
          <ScrollView
            ref={scroll}
            keyboardShouldPersistTaps="handled"
            contentContainerStyle={[
              s.content,
              { maxWidth: 600, width: "100%", alignSelf: "center" },
            ]}
          >
            {previous && screen !== "saved" && (
              <Button
                secondary
                disabled={busy}
                label={t("undo")}
                onPress={() => safe(undo)}
              />
            )}
            {content}
            {!!notice && (
              <Card tint={C.blush}>
                <Txt kind="small">{notice}</Txt>
                <Button
                  small
                  secondary
                  label={t("done")}
                  onPress={() => N("")}
                />
              </Card>
            )}
          </ScrollView>
        )}
      </KeyboardAvoidingView>
      {main && (
        <View style={s.nav}>
          {(
            [
              ["home", Home],
              ["calendar", CalendarDays],
              ["plus", Plus],
              ["stats", ChartNoAxesColumn],
              ["me", User],
            ] as const
          ).map(([tab, Icon]) => (
            <Pressable
              key={tab}
              accessibilityRole="button"
              accessibilityLabel={t(tab === "plus" ? "add" : tab)}
              accessibilityState={{ selected: tab === screen }}
              onPress={() => (tab === "plus" ? begin() : S(tab))}
              style={s.navItem}
            >
              {tab === "plus" ? (
                <View style={s.navPlus}>
                  <Icon color={C.bg} size={27} />
                </View>
              ) : (
                <>
                  <Icon color={tab === screen ? C.green : C.ink2} size={23} />
                  <Txt
                    style={{
                      fontSize: 11,
                      color: tab === screen ? C.green : C.ink2,
                    }}
                  >
                    {t(tab)}
                  </Txt>
                </>
              )}
            </Pressable>
          ))}
        </View>
      )}
    </SafeAreaView>
  );
}
