import type { AppStateStatus } from 'react-native';

export type AppLockAction = 'none' | 'defer' | 'lock';
export type SystemPromptFinishAction = 'wait' | 'resume' | 'lock';

export function appLockActionForState(
  state: AppStateStatus,
  lockEnabled: boolean,
  systemPromptOpen: boolean
): AppLockAction {
  if (!lockEnabled || state === 'active') return 'none';
  return systemPromptOpen ? 'defer' : 'lock';
}

export function shouldLockAfterSystemPrompt(
  currentState: AppStateStatus,
  lockEnabled: boolean
): boolean {
  return lockEnabled && currentState !== 'active';
}

export function nextSystemPromptDepth(currentDepth: number, opening: boolean): number {
  return opening ? currentDepth + 1 : Math.max(0, currentDepth - 1);
}

export function systemPromptFinishAction(
  currentState: AppStateStatus,
  lockEnabled: boolean
): SystemPromptFinishAction {
  if (lockEnabled && currentState !== 'active') return 'wait';
  return 'resume';
}
