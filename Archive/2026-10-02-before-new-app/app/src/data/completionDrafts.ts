import { settingsRepo } from './repositories';
export const draftKey = (id: string) => `completionDraft:${id}`;
export function readCompletionDraft<T>(id: string, revision: string | undefined): T | null {
  const raw = settingsRepo.get(draftKey(id));
  if (!raw) return null;
  try {
    const draft = JSON.parse(raw);
    return draft.revision === revision && draft.version === 1 ? (draft.value as T) : null;
  } catch {
    return null;
  }
}
export function saveCompletionDraft<T>(id: string, revision: string | undefined, value: T): void {
  settingsRepo.set(draftKey(id), JSON.stringify({ version: 1, revision, value }));
}
