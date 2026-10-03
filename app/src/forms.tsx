import React, { useState } from "react";
import { View, Pressable, Platform, ScrollView } from "react-native";
import DateTimePicker from "@react-native-community/datetimepicker";
import {
  Job,
  Shift,
  amount,
  colors,
  hours,
  iso,
  localDate,
  minutes,
  validDate,
  validTime,
  addDays,
} from "./domain";
import { Button, Card, Chips, Field, Txt, C, s } from "./ui";
import { CopyKey, roleLabel } from "./copy";
export type Translate = (key: CopyKey) => string;
const val = (n: number | null) => (n === null ? "" : String(n / 100));
export function DateField({
  label,
  value,
  onChange,
  time = false,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  time?: boolean;
}) {
  const [visible, show] = useState(false);
  if (Platform.OS === "web")
    return <Field label={label} value={value} onChange={onChange} />;
  const d = time
    ? new Date(2026, 0, 1, Number(value.slice(0, 2)), Number(value.slice(3)))
    : localDate(value);
  return (
    <View style={{ gap: 7 }}>
      <Txt style={s.label}>{label}</Txt>
      <Button label={value} secondary onPress={() => show(true)} />
      {visible && (
        <DateTimePicker
          value={Number.isNaN(d.getTime()) ? new Date() : d}
          mode={time ? "time" : "date"}
          is24Hour
          onChange={(event, date) => {
            show(false);
            if (event.type === "set" && date)
              onChange(
                time
                  ? `${String(date.getHours()).padStart(2, "0")}:${String(date.getMinutes()).padStart(2, "0")}`
                  : iso(date),
              );
          }}
        />
      )}
    </View>
  );
}
export function JobForm({
  initial,
  index,
  t,
  onSave,
}: {
  initial?: Job;
  index: number;
  t: Translate;
  onSave: (j: Omit<Job, "id">) => Promise<void>;
}) {
  const [name, N] = useState(initial?.name ?? ""),
    [role, R] = useState(initial?.role ?? "Server"),
    [rate, W] = useState(val(initial?.rate ?? 1330)),
    [color, K] = useState(initial?.color ?? colors[index % colors.length]),
    [start, S] = useState(initial?.start ?? "17:00"),
    [end, E] = useState(initial?.end ?? "23:30"),
    [brk, B] = useState(initial?.brk ?? 30),
    [error, X] = useState(""),
    [busy, Q] = useState(false);
  return (
    <>
      <Txt kind="title">{t("jobTitle")}</Txt>
      <Field label={t("name")} value={name} onChange={N} />
      <Txt>{t("role")}</Txt>
      <Chips
        value={role}
        onChange={R}
        items={["Server", "Bartender", "Busser", "Host", "Barback"].map(
          (v, i) => ({
            value: v,
            label: roleLabel(v, t),
          }),
        )}
      />

      <Field label={t("rate")} money value={rate} onChange={W} />
      {amount(rate) !== undefined &&
        amount(rate) !== null &&
        amount(rate)! < 1330 && (
          <Card tint={C.blush}>
            <Txt kind="small">{t("lowRate")}</Txt>
          </Card>
        )}
      <View style={s.wrap}>
        {colors.map((c) => (
          <Pressable
            accessibilityRole="radio"
            accessibilityLabel={c}
            accessibilityState={{ checked: color === c }}
            aria-checked={color === c}
            key={c}
            onPress={() => K(c)}
            style={{
              width: 44,
              height: 44,
              borderRadius: 22,
              backgroundColor: c,
              borderWidth: color === c ? 3 : 0,
              borderColor: C.ink,
            }}
          />
        ))}
      </View>
      <Txt kind="section">{t("defaultHours")}</Txt>
      <View style={s.split}>
        <View style={{ flex: 1 }}>
          <DateField label={t("startTime")} value={start} onChange={S} time />
        </View>
        <View style={{ flex: 1 }}>
          <DateField label={t("endTime")} value={end} onChange={E} time />
        </View>
      </View>
      <Txt>{t("break")}</Txt>
      <Chips
        value={String(brk)}
        onChange={(v) => B(Number(v))}
        items={[0, 15, 30, 45, 60].map((v) => ({
          value: String(v),
          label: v ? v + " min" : t("none"),
        }))}
      />
      {!!error && <Txt style={s.error}>{error}</Txt>}
      <Button
        label={t("continue")}
        disabled={busy}
        onPress={() => {
          const cents = amount(rate);
          if (!name.trim()) {
            X(t("jobRequired"));
            return;
          }
          if (cents === null || cents === undefined) {
            X(t("invalid"));
            return;
          }
          if (!validTime(start) || !validTime(end)) {
            X(t("invalidTime"));
            return;
          }
          Q(true);
          void onSave({
            name: name.trim(),
            role: role.trim(),
            rate: cents,
            color,
            start,
            end,
            brk,
          })
            .catch(() => X(t("storageError")))
            .finally(() => Q(false));
        }}
      />
    </>
  );
}
export function HoursForm({
  draft,
  jobs,
  t,
  onNext,
  onDraft,
  planned = false,
}: {
  draft: Shift;
  jobs: Job[];
  t: Translate;
  onNext: () => void;
  onDraft: (s: Shift) => void;
  planned?: boolean;
}) {
  const [error, E] = useState("");
  const set = (v: Partial<Shift>) => onDraft({ ...draft, ...v });
  return (
    <>
      <Txt kind="eyebrow">{planned ? t("planned") : "1 / 2"}</Txt>
      <Txt kind="title">{t("log")}</Txt>
      <Txt>{t("job")}</Txt>
      {jobs
        .filter((j) => !j.archived || j.id === draft.job)
        .map((j) => (
          <Pressable
            key={j.id}
            accessibilityRole="radio"
            accessibilityState={{ checked: j.id === draft.job }}
            aria-checked={j.id === draft.job}
            onPress={() =>
              set({
                job: j.id,
                rate: j.rate,
                start: j.start,
                end: j.end,
                brk: j.brk,
              })
            }
          >
            <Card style={{ borderColor: draft.job === j.id ? C.ink : C.line }}>
              <View style={s.row}>
                <View style={[s.dot, { backgroundColor: j.color }]} />
                <View style={{ flex: 1 }}>
                  <Txt>{j.name}</Txt>
                  <Txt kind="small">
                    {roleLabel(j.role, t)} · {(j.rate / 100).toFixed(2)} $/h
                  </Txt>
                </View>
                <Txt>{draft.job === j.id ? "●" : "○"}</Txt>
              </View>
            </Card>
          </Pressable>
        ))}
      <Txt>{t("when")}</Txt>
      <Chips
        value={
          draft.date === iso()
            ? "today"
            : draft.date === addDays(iso(), -1)
              ? "yesterday"
              : "other"
        }
        items={["today", "yesterday", "other"].map((k) => ({
          value: k,
          label: t(k as CopyKey),
        }))}
        onChange={(v) => {
          if (v !== "other")
            set({ date: v === "today" ? iso() : addDays(iso(), -1) });
        }}
      />
      <DateField
        label={t("date")}
        value={draft.date}
        onChange={(date) => set({ date })}
      />
      <View style={s.split}>
        <View style={{ flex: 1 }}>
          <DateField
            label={t("startTime")}
            value={draft.start}
            onChange={(start) => set({ start })}
            time
          />
        </View>
        <View style={{ flex: 1 }}>
          <DateField
            label={t("endTime")}
            value={draft.end}
            onChange={(end) => set({ end })}
            time
          />
        </View>
      </View>
      <Card tint={C.paper}>
        <Txt>
          {Number.isFinite(hours(draft))
            ? hours(draft).toLocaleString(undefined, {
                maximumFractionDigits: 2,
              })
            : "—"}{" "}
          h · {t("hours")}
        </Txt>
        {minutes(draft.end) <= minutes(draft.start) && (
          <Txt kind="small">{t("overnight")}</Txt>
        )}
      </Card>
      <Txt>{t("break")}</Txt>
      <Chips
        value={String(draft.brk)}
        onChange={(v) => set({ brk: Number(v) })}
        items={[0, 15, 30, 45, 60].map((v) => ({
          value: String(v),
          label: v ? v + " min" : t("none"),
        }))}
      />
      {!!error && <Txt style={s.error}>{error}</Txt>}
      <Button
        label={planned ? t("save") : t("next")}
        onPress={() => {
          if (
            !jobs.some((j) => j.id === draft.job) ||
            !validDate(draft.date) ||
            !validTime(draft.start) ||
            !validTime(draft.end) ||
            hours(draft) <= 0
          ) {
            E(t("invalidTime"));
            return;
          }
          onNext();
        }}
      />
    </>
  );
}
export function TipsForm({
  draft,
  t,
  onSave,
  money,
  job,
}: {
  draft: Shift;
  t: Translate;
  onSave: (s: Shift) => Promise<void>;
  money: (n: number) => string;
  job: Job;
}) {
  const fields = ["cash", "card", "tipIn", "tipOut", "sales", "other"] as const;
  const [values, V] = useState(
      Object.fromEntries(fields.map((k) => [k, val(draft[k])])) as Record<
        (typeof fields)[number],
        string
      >,
    ),
    [note, N] = useState(draft.note),
    [more, M] = useState(false),
    [error, E] = useState(""),
    [busy, B] = useState(false);
  const set = (k: (typeof fields)[number], v: string) =>
    V({ ...values, [k]: v });
  const a = (k: (typeof fields)[number]) => amount(values[k]);
  const total =
    (a("cash") ?? 0) +
    (a("card") ?? 0) +
    (a("tipIn") ?? 0) +
    (a("other") ?? 0) -
    (a("tipOut") ?? 0);
  return (
    <View
      style={{ flex: 1, width: "100%", maxWidth: 600, alignSelf: "center" }}
    >
      <ScrollView
        keyboardShouldPersistTaps="handled"
        contentContainerStyle={s.content}
      >
        <Txt kind="eyebrow">2 / 2</Txt>
        <Txt kind="title">{t("net")}</Txt>
        <Txt kind="small">
          {job.name} · {draft.date} · {hours(draft)} h
        </Txt>
        <Field
          label={t("cash")}
          money
          value={values.cash}
          onChange={(v) => set("cash", v)}
        />
        <View style={s.wrap}>
          {[5, 10, 20, 50].map((n) => (
            <Button
              small
              secondary
              key={n}
              label={"+" + n}
              onPress={() =>
                set("cash", String(((a("cash") ?? 0) + n * 100) / 100))
              }
            />
          ))}
        </View>
        <Field
          label={t("card")}
          money
          value={values.card}
          onChange={(v) => set("card", v)}
          hint={t("cardHint")}
        />
        <Field
          label={t("in")}
          money
          value={values.tipIn}
          onChange={(v) => set("tipIn", v)}
          hint={t("inHint")}
        />
        <Field
          label={t("out")}
          money
          value={values.tipOut}
          onChange={(v) => set("tipOut", v)}
          hint={t("outHint")}
        />
        <Button
          secondary
          label={t("more") + (more ? " −" : " +")}
          onPress={() => M(!more)}
        />
        {more && (
          <>
            <Field
              label={t("sales")}
              money
              value={values.sales}
              onChange={(v) => set("sales", v)}
            />
            <Field
              label={t("tipOther")}
              money
              value={values.other}
              onChange={(v) => set("other", v)}
            />
            <Field label={t("note")} value={note} onChange={N} multiline />
          </>
        )}
      </ScrollView>
      <View
        style={{
          padding: 16,
          gap: 8,
          borderTopWidth: 1,
          borderColor: C.line,
          backgroundColor: C.bg,
        }}
      >
        <Card tint={C.soft}>
          <Txt>{t("net")}</Txt>
          <Txt kind="section">{money(total)}</Txt>
          <Txt kind="small">{t("netHint")}</Txt>
        </Card>
        {!!error && <Txt style={s.error}>{error}</Txt>}
        <Button
          label={t("save")}
          disabled={busy}
          onPress={() => {
            if (fields.some((k) => a(k) === undefined)) {
              E(t("invalid"));
              return;
            }
            B(true);
            void onSave({
              ...draft,
              ...Object.fromEntries(fields.map((k) => [k, a(k)])),
              note,
              planned: false,
              updatedAt: new Date().toISOString(),
            })
              .catch(() => E(t("storageError")))
              .finally(() => B(false));
          }}
        />
      </View>
    </View>
  );
}
