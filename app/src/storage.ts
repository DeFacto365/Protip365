import { Platform } from "react-native";
import * as SQLite from "expo-sqlite";
import * as SecureStore from "expo-secure-store";
import { randomUUID } from "expo-crypto";
import { getLocales } from "expo-localization";
import {File} from "expo-file-system";
import {requireDatabaseUnlocked} from "./security/appLock";
import {importLegacy, LegacyArchive} from "./legacy";
import { Data, validData } from "./domain";
const KEY = "protip365.new-app.v1";
let db: SQLite.SQLiteDatabase;
let opening: Promise<SQLite.SQLiteDatabase> | undefined;
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
  requireDatabaseUnlocked();
  if (db) return db;
  if (opening) return opening;
  opening = openDatabase();
  try {
    db = await opening;
    return db;
  } finally {
    opening = undefined;
  }
}
async function openDatabase() {
  let key = await SecureStore.getItemAsync("protip365.new-app.database-key");
  if (!key) {
    requireDatabaseUnlocked();
    key = randomUUID().replace(/-/g, "") + randomUUID().replace(/-/g, "");
    await SecureStore.setItemAsync("protip365.new-app.database-key", key);
  }
  if (!/^[0-9a-f]{64}$/i.test(key))
    throw new Error("Invalid database encryption key");
  requireDatabaseUnlocked();
  const opened = await SQLite.openDatabaseAsync("protip365-redesign.db");
  try {
    await opened.execAsync(`PRAGMA key = "x'${key}'";`);
    const cipher = await opened.getFirstAsync<{ cipher_version: string }>(
      "PRAGMA cipher_version",
    );
    if (!cipher?.cipher_version)
      throw new Error("Encrypted database support is unavailable");
    await opened.execAsync(
      "CREATE TABLE IF NOT EXISTS state (id INTEGER PRIMARY KEY, value TEXT NOT NULL);",
    );
    requireDatabaseUnlocked();
    return opened;
  } catch (error) {
    await opened.closeAsync().catch(() => {});
    throw error;
  }

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
  if (!text) {
    const value = Platform.OS === "web" ? fresh() : await loadLegacy();
    if (value.legacyArchive) {
      requireDatabaseUnlocked();
      // The whole converted state and original archive commit together. Repeated launches never append duplicates.
      await (await database()).runAsync("INSERT OR IGNORE INTO state(id,value) VALUES(1,?)", JSON.stringify(value));
      requireDatabaseUnlocked();
    }
    return value;
  }
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
  if (Platform.OS !== "web") requireDatabaseUnlocked();
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

async function loadLegacy(): Promise<Data> {
  requireDatabaseUnlocked();
  // SQLite returns a bare Android path; File requires an absolute file URI.
  const directory = SQLite.defaultDatabaseDirectory;
  const oldFile = new File(directory.startsWith('file://') ? directory : 'file://' + directory, 'protip365.db');
  if (!oldFile.exists) return fresh();
  const key = await SecureStore.getItemAsync('protip365.database-key.v1');
  requireDatabaseUnlocked();
  if (!key || !/^[0-9a-f]{64}$/i.test(key)) {console.warn('Original database key unavailable or invalid; original records preserved'); throw new Error('Missing original database key; original records preserved');}
  const legacy = await SQLite.openDatabaseAsync('protip365.db', {useNewConnection: true});
  let stage = 'decrypt';
  try {
    await legacy.execAsync(`PRAGMA key = "x'${key}'"; PRAGMA query_only=ON;`);
    stage = 'schema';
    const tables = await legacy.getAllAsync<{name: string}>("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'");
    const archive: LegacyArchive = {database: 'protip365.db', userVersion: (await legacy.getFirstAsync<{user_version: number}>('PRAGMA user_version'))!.user_version, tables: {}};
    stage = 'read-tables';
    for (const table of tables) {
      requireDatabaseUnlocked();
      archive.tables[table.name] = await legacy.getAllAsync(`SELECT * FROM "${table.name.replace(/"/g, '""')}"`);
    }
    requireDatabaseUnlocked();
    stage = 'convert';
    return importLegacy(archive, fresh());
  } catch {
    console.warn('Legacy record import failed at stage: ' + stage);
    throw new Error('Legacy import failed: ' + stage);
  } finally {await legacy.closeAsync();}
}
export async function closeForLock() {
  await writes;
  const opened = db; db = undefined as unknown as SQLite.SQLiteDatabase;
  if (opened) await opened.closeAsync();
}
