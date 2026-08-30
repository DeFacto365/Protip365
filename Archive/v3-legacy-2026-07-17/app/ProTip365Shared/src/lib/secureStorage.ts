import * as SecureStore from "expo-secure-store";
import { Platform } from "react-native";

const memoryStorage = new Map<string, string>();
const CHUNK_SIZE = 1800;
const SECURE_STORE_KEY_PATTERN = /^[A-Za-z0-9._-]+$/;

type ChunkMetadata =
  | {
      chunkCount: number;
      chunkId: string;
      version: 1;
    }
  | {
      chunkCount: number;
      chunkId: null;
      version: 0;
    };

function chunksKey(key: string) {
  return `${nativeBaseKey(key)}.chunks`;
}

function chunkKey(key: string, chunkId: string | null, index: number) {
  return chunkId ? `${nativeBaseKey(key)}.chunk.${chunkId}.${index}` : `${nativeBaseKey(key)}.chunk.${index}`;
}

function nativeBaseKey(key: string) {
  if (SECURE_STORE_KEY_PATTERN.test(key)) {
    return key;
  }

  const encodedKey = Array.from(key)
    .map((character) =>
      SECURE_STORE_KEY_PATTERN.test(character) ? character : `_${character.charCodeAt(0).toString(16)}_`,
    )
    .join("");

  return `key.${encodedKey}`;
}

function getChunkMetadata(value: string | null): ChunkMetadata | null {
  if (!value) {
    return null;
  }

  try {
    const metadata = JSON.parse(value) as Partial<ChunkMetadata>;
    const chunkCount = metadata.chunkCount;

    if (
      metadata.version === 1 &&
      typeof metadata.chunkId === "string" &&
      Number.isInteger(chunkCount) &&
      typeof chunkCount === "number" &&
      chunkCount > 0
    ) {
      return {
        chunkCount,
        chunkId: metadata.chunkId,
        version: 1,
      };
    }
  } catch {
    return getLegacyChunkMetadata(value);
  }

  return getLegacyChunkMetadata(value);
}

function getLegacyChunkMetadata(value: string): ChunkMetadata | null {
  const chunkCount = Number(value);

  if (Number.isInteger(chunkCount) && chunkCount > 0) {
    return {
      chunkCount,
      chunkId: null,
      version: 0,
    };
  }

  return null;
}

function createChunkId() {
  return `${Date.now()}-${Math.random().toString(36).slice(2)}`;
}

async function removeNativeChunks(key: string, metadata: ChunkMetadata | null) {
  if (!metadata) {
    return;
  }

  await Promise.all(
    Array.from({ length: metadata.chunkCount }, (_unused, index) =>
      SecureStore.deleteItemAsync(chunkKey(key, metadata.chunkId, index)),
    ),
  );
}

async function removeNativeItem(key: string) {
  const metadata = getChunkMetadata(await SecureStore.getItemAsync(chunksKey(key)));

  await Promise.all([
    SecureStore.deleteItemAsync(nativeBaseKey(key)),
    SecureStore.deleteItemAsync(chunksKey(key)),
    removeNativeChunks(key, metadata),
  ]);
}

export const supabaseSecureStorage = {
  async getItem(key: string) {
    if (Platform.OS === "web") {
      return memoryStorage.get(key) ?? null;
    }

    const metadata = getChunkMetadata(await SecureStore.getItemAsync(chunksKey(key)));

    if (!metadata) {
      return SecureStore.getItemAsync(nativeBaseKey(key));
    }

    const chunks = await Promise.all(
      Array.from({ length: metadata.chunkCount }, (_unused, index) =>
        SecureStore.getItemAsync(chunkKey(key, metadata.chunkId, index)),
      ),
    );

    if (chunks.some((chunk) => chunk === null)) {
      await removeNativeItem(key);
      return null;
    }

    return chunks.join("");
  },
  async removeItem(key: string) {
    if (Platform.OS === "web") {
      memoryStorage.delete(key);
      return;
    }

    await removeNativeItem(key);
  },
  async setItem(key: string, value: string) {
    if (Platform.OS === "web") {
      memoryStorage.set(key, value);
      return;
    }

    const previousMetadata = getChunkMetadata(await SecureStore.getItemAsync(chunksKey(key)));
    const nextMetadata: ChunkMetadata = {
      chunkCount: 0,
      chunkId: createChunkId(),
      version: 1,
    };
    const chunks = value.match(new RegExp(`.{1,${CHUNK_SIZE}}`, "g")) ?? [""];
    nextMetadata.chunkCount = chunks.length;

    await Promise.all(
      chunks.map((chunk, index) => SecureStore.setItemAsync(chunkKey(key, nextMetadata.chunkId, index), chunk)),
    );
    await SecureStore.setItemAsync(chunksKey(key), JSON.stringify(nextMetadata));

    await Promise.all([
      SecureStore.deleteItemAsync(nativeBaseKey(key)),
      removeNativeChunks(key, previousMetadata),
    ]);
  },
};
