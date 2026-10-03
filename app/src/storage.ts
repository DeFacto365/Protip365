import { Platform } from "react-native";
import * as SQLite from "expo-sqlite";
import * as SecureStore from "expo-secure-store";
import { randomUUID } from "expo-crypto";
import { getLocales } from "expo-localization";
import { Data, validData } from "./domain";
const KEY = "protip365.new-app.v1";
let db: SQLite.SQLiteDatabase;
export const fresh = (): Data => ({
  version: 1,
  onboarded: false,
  jobs: [],
  shifts: [],
  settings: {
    language: getLocales()[0]?.languageCode === "en" ? "en" : "fr",
    weekStart: 1,
    reminder: true,
    offset: 15,
    goal: null,
    name: "",
  },
});
async function database() {
  if (db) return db;
  let key = await SecureStore.getItemAsync("protip365.new-app.database-key");
  if (!key) {
    key = randomUUID().replace(/-/g, "") + randomUUID().replace(/-/g, "");
    await SecureStore.setItemAsync("protip365.new-app.database-key", key);
  }
  const opened = await SQLite.openDatabaseAsync("protip365-redesign.db");
  await opened.execAsync(
    `PRAGMA key = "x'${key}'"; CREATE TABLE IF NOT EXISTS state (id INTEGER PRIMARY KEY, value TEXT NOT NULL);`,
  );
  db = opened;
  return db;
}
export async function load() {
  const text =
    Platform.OS === "web"
      ? localStorage.getItem(KEY)
      : (
          await (
            await database()
          ).getFirstAsync<{ value: string }>(
            "SELECT value FROM state WHERE id=1",
          )
        )?.value;
  if (!text) return fresh();
  const data = JSON.parse(text);
  if (!validData(data)) throw new Error("Invalid saved data");
  return data;
}
let writes: Promise<void> = Promise.resolve();
export function save(data: Data) {
  const pending = writes.then(() => write(data));
  writes = pending.catch(() => {});
  return pending;
}
async function write(data: Data) {
  if (!validData(data)) throw new Error("Invalid data");
  const text = JSON.stringify(data);
  if (Platform.OS === "web") localStorage.setItem(KEY, text);
  else
    await (
      await database()
    ).runAsync(
      "INSERT INTO state(id,value) VALUES(1,?) ON CONFLICT(id) DO UPDATE SET value=excluded.value",
      text,
    );
}
