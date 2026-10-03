import { getLocales } from "expo-localization";
import { Data, validData } from "./domain";
const KEY = "protip365.new-app.v1";
// Platform-specific entry prevents the browser bundle from linking native SQLite.
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
export async function load(): Promise<Data> {
  const raw = localStorage.getItem(KEY);
  if (!raw) return fresh();
  const data = JSON.parse(raw);
  if (!validData(data)) throw new Error("Invalid saved data");
  return data;
}
export async function save(data: Data) {
  if (!validData(data)) throw new Error("Invalid data");
  localStorage.setItem(KEY, JSON.stringify(data));
}
