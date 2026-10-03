import { selectableEmployers } from '../employers';
import type { Employer } from '../types';

const active: Employer = {
  id: 'active',
  name: 'Active employer',
  color: '#2B4BD7',
  defaultHourlyRate: 1800,
  deductionRateBp: 1000,
  archived: false,
};

const archived: Employer = {
  id: 'archived',
  name: 'Archived employer',
  color: '#E8A23D',
  defaultHourlyRate: 2200,
  deductionRateBp: 2000,
  archived: true,
};

describe('employer picker archive semantics', () => {
  it('hides archived employers from a new-shift picker without deleting them', () => {
    const employers = [active, archived];
    expect(selectableEmployers(employers).map((employer) => employer.id)).toEqual(['active']);
    expect(employers).toHaveLength(2);
  });

  it('keeps an archived employer visible while editing its historical shift', () => {
    expect(selectableEmployers([active, archived], 'archived')).toEqual([active, archived]);
  });
});
