import {
  appLockActionForState,
  nextSystemPromptDepth,
  shouldLockAfterSystemPrompt,
  systemPromptFinishAction,
} from '../../security/appLifecycle';

describe('app lock lifecycle', () => {
  it('keeps the database unlocked during an app-owned system permission prompt', () => {
    expect(appLockActionForState('background', true, true)).toBe('defer');
  });

  it('locks normally when a protected app leaves the foreground', () => {
    expect(appLockActionForState('background', true, false)).toBe('lock');
    expect(appLockActionForState('inactive', true, false)).toBe('lock');
    expect(appLockActionForState('active', true, false)).toBe('none');
  });

  it('locks after a prompt only when the app is still outside the foreground', () => {
    expect(shouldLockAfterSystemPrompt('background', true)).toBe(true);
    expect(shouldLockAfterSystemPrompt('active', true)).toBe(false);
    expect(shouldLockAfterSystemPrompt('background', false)).toBe(false);
  });

  it('waits through transient inactive and background states before a prompt returns', () => {
    expect(systemPromptFinishAction('inactive', true)).toBe('wait');
    expect(systemPromptFinishAction('background', true)).toBe('wait');
    expect(systemPromptFinishAction('active', true)).toBe('resume');
  });

  it('keeps suppression active until all overlapping system prompts finish', () => {
    let depth = nextSystemPromptDepth(0, true);
    depth = nextSystemPromptDepth(depth, true);
    expect(depth).toBe(2);
    depth = nextSystemPromptDepth(depth, false);
    expect(depth).toBe(1);
    depth = nextSystemPromptDepth(depth, false);
    expect(depth).toBe(0);
    expect(nextSystemPromptDepth(depth, false)).toBe(0);
  });
});
