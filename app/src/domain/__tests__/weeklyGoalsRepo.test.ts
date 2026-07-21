jest.mock('../../data/db', () => ({
  getDb: jest.fn(),
  nowIso: () => '2026-07-21T00:00:00.000Z',
}));
jest.mock('../../data/ids', () => ({ uuid: () => 'new-goal' }));

import { getDb } from '../../data/db';
import { weeklyGoalsRepo } from '../../data/repositories';

const getDbMock = getDb as jest.MockedFunction<typeof getDb>;
const runSync = jest.fn();
const getFirstSync = jest.fn();

beforeEach(() => {
  runSync.mockReset();
  getFirstSync.mockReset();
  getDbMock.mockReset();
  getDbMock.mockReturnValue({ runSync, getFirstSync } as unknown as ReturnType<typeof getDb>);
});

describe('weeklyGoalsRepo', () => {
  const input = {
    weekStart: '2026-07-20',
    metric: 'actual_gross' as const,
    target: 50000,
    employerId: null,
    repeat: true,
  };

  it('updates the matching weekly goal instead of creating a duplicate', () => {
    getFirstSync.mockReturnValue({ id: 'existing-goal' });

    expect(weeklyGoalsRepo.upsert(input)).toEqual({ id: 'existing-goal', ...input });
    expect(runSync).toHaveBeenCalledWith(
      expect.stringContaining('UPDATE weekly_goals'),
      [50000, 1, '2026-07-21T00:00:00.000Z', 'existing-goal']
    );
    expect(runSync.mock.calls.flat().join(' ')).not.toContain('INSERT INTO weekly_goals');
  });

  it('deletes only the requested goal', () => {
    weeklyGoalsRepo.remove('goal-1');

    expect(runSync).toHaveBeenCalledWith('DELETE FROM weekly_goals WHERE id = ?;', ['goal-1']);
  });
});
