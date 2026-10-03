jest.mock('../../data/db', () => ({
  getDb: jest.fn(),
  nowIso: () => '2026-07-18T00:00:00.000Z',
}));
jest.mock('../../data/ids', () => ({ uuid: () => 'new-employer' }));

import { getDb } from '../../data/db';
import { employersRepo } from '../../data/repositories';

const getDbMock = getDb as jest.MockedFunction<typeof getDb>;
const runSync = jest.fn();
const getAllSync = jest.fn();

beforeEach(() => {
  runSync.mockReset();
  getAllSync.mockReset();
  getDbMock.mockReset();
  getDbMock.mockReturnValue({ runSync, getAllSync } as unknown as ReturnType<typeof getDb>);
});

describe('employersRepo archive semantics', () => {
  it('archives and unarchives with a flag update only', () => {
    employersRepo.archive('employer-1', true);
    employersRepo.archive('employer-1', false);

    expect(runSync).toHaveBeenNthCalledWith(
      1,
      expect.stringContaining('UPDATE employers SET archived'),
      [1, '2026-07-18T00:00:00.000Z', 'employer-1']
    );
    expect(runSync).toHaveBeenNthCalledWith(
      2,
      expect.stringContaining('UPDATE employers SET archived'),
      [0, '2026-07-18T00:00:00.000Z', 'employer-1']
    );
    expect(runSync.mock.calls.flat().join(' ')).not.toContain('DELETE');
  });

  it('returns archived employers so history can still resolve their names', () => {
    getAllSync.mockReturnValue([
      {
        id: 'employer-1',
        name: 'Archived employer',
        color: '#2B4BD7',
        default_hourly_rate: 1950,
        deduction_rate_bp: 1250,
        archived: 1,
      },
    ]);

    expect(employersRepo.list()).toEqual([
      {
        id: 'employer-1',
        name: 'Archived employer',
        color: '#2B4BD7',
        defaultHourlyRate: 1950,
        deductionRateBp: 1250,
        archived: true,
      },
    ]);
  });

  it('refuses hard removal without touching the database', () => {
    expect(() => employersRepo.remove('employer-1')).toThrow('employer_remove_not_supported');
    expect(getDbMock).not.toHaveBeenCalled();
    expect(runSync).not.toHaveBeenCalled();
  });

  it('persists the employer default hourly rate on create and update', () => {
    const created = employersRepo.create({
      name: 'Cafe',
      color: '#2B4BD7',
      defaultHourlyRate: 1875,
      deductionRateBp: 2000,
    });

    expect(runSync).toHaveBeenNthCalledWith(
      1,
      expect.stringContaining('default_hourly_rate'),
      [
        'new-employer',
        'Cafe',
        '#2B4BD7',
        1875,
        2000,
        '2026-07-18T00:00:00.000Z',
        '2026-07-18T00:00:00.000Z',
      ]
    );
    expect(created.defaultHourlyRate).toBe(1875);

    employersRepo.update({ ...created, defaultHourlyRate: 2125 });
    expect(runSync).toHaveBeenNthCalledWith(
      2,
      expect.stringContaining('default_hourly_rate = ?'),
      [
        'Cafe',
        '#2B4BD7',
        2125,
        2000,
        '2026-07-18T00:00:00.000Z',
        'new-employer',
      ]
    );
  });

  it('rejects non-positive rates and out-of-range deductions before SQL', () => {
    expect(() =>
      employersRepo.create({
        name: 'Cafe',
        color: '#2B4BD7',
        defaultHourlyRate: 0,
        deductionRateBp: 2000,
      })
    ).toThrow('rate_not_positive');
    expect(() =>
      employersRepo.create({
        name: 'Cafe',
        color: '#2B4BD7',
        defaultHourlyRate: 1800,
        deductionRateBp: 10001,
      })
    ).toThrow('deduction_out_of_range');
    expect(runSync).not.toHaveBeenCalled();
  });
});
