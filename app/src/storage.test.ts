const mockDb = {
  execAsync: jest.fn(async (_sql: string) => {}),
  getFirstAsync: jest.fn(async (sql: string) =>
    sql === "PRAGMA cipher_version" ? { cipher_version: "4.6" } : null),
  runAsync: jest.fn(async () => {}),
  closeAsync: jest.fn(async () => {}),
};
jest.mock("expo-file-system", () => ({File: class {
  exists = false;
  constructor(uri: string) {if (!uri.startsWith('file://')) throw new Error('File requires an absolute file URI');}
}}));
jest.mock("./security/appLock", () => ({requireDatabaseUnlocked: jest.fn()}));
jest.mock("react-native", () => ({ Platform: { OS: "android" } }));
jest.mock("expo-sqlite", () => ({
  defaultDatabaseDirectory: "/data/user/0/com.defacto365.protip365/files/SQLite",
  openDatabaseAsync: jest.fn(async () => mockDb),
}));
jest.mock("expo-secure-store", () => ({
  getItemAsync: jest.fn(async () => null),
  setItemAsync: jest.fn(async () => {}),
}));
jest.mock("expo-crypto", () => ({
  randomUUID: () => "01234567-89ab-4cde-8fab-0123456789ab",
}));
jest.mock("expo-localization", () => ({ getLocales: () => [] }));

beforeEach(() => {
  jest.resetModules();
  jest.clearAllMocks();
  mockDb.getFirstAsync.mockImplementation(async (sql: string) =>
    sql === "PRAGMA cipher_version" ? { cipher_version: "4.6" } : null);
});

test("concurrent loads generate one key and open one encrypted connection", async () => {
  const storage = await import("./storage");
  const secure = await import("expo-secure-store");
  const sqlite = await import("expo-sqlite");
  await Promise.all([storage.load(), storage.load(), storage.save(storage.fresh())]);
  expect(secure.setItemAsync).toHaveBeenCalledTimes(1);
  expect(sqlite.openDatabaseAsync).toHaveBeenCalledTimes(1);
  expect(mockDb.execAsync.mock.calls[0][0]).toContain("PRAGMA key");
  expect(mockDb.runAsync).toHaveBeenCalledTimes(1);
});

test("missing encryption support closes connection and permits safe retry", async () => {
  const storage = await import("./storage");
  mockDb.getFirstAsync.mockResolvedValueOnce(null);
  await expect(storage.load()).rejects.toThrow("Encrypted database");
  expect(mockDb.closeAsync).toHaveBeenCalledTimes(1);
  expect(mockDb.runAsync).not.toHaveBeenCalled();
  await expect(storage.load()).resolves.toEqual(storage.fresh());
});

test("invalid stored key is rejected before opening database", async () => {
  const storage = await import("./storage");
  const secure = await import("expo-secure-store");
  const sqlite = await import("expo-sqlite");
  (secure.getItemAsync as jest.Mock).mockResolvedValueOnce("invalid-key");
  await expect(storage.load()).rejects.toThrow("Invalid database encryption key");
  expect(sqlite.openDatabaseAsync).not.toHaveBeenCalled();
});

test("a failed write is reported and does not poison subsequent saves", async () => {
  const storage = await import("./storage");
  mockDb.runAsync.mockRejectedValueOnce(new Error("disk full"));
  await expect(storage.save(storage.fresh())).rejects.toThrow("disk full");
  await expect(storage.save(storage.fresh())).resolves.toBeUndefined();
  expect(mockDb.runAsync).toHaveBeenCalledTimes(2);
});

test("inherited lock rejects record reads and queued writes before keys or SQLite are accessed", async () => {
  const gate = jest.requireMock("./security/appLock").requireDatabaseUnlocked as jest.Mock;
  gate.mockImplementation(() => {throw new Error("App is locked");});
  const storage = await import("./storage"), sqlite = await import("expo-sqlite"), secure = await import("expo-secure-store");
  await expect(storage.load()).rejects.toThrow("App is locked");
  await expect(storage.save(storage.fresh())).rejects.toThrow("App is locked");
  expect(sqlite.openDatabaseAsync).not.toHaveBeenCalled();
  expect(secure.getItemAsync).not.toHaveBeenCalled();
  gate.mockImplementation(() => {});
});
