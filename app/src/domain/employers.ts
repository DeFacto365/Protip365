import type { Employer } from './types';

/**
 * Employers available to a picker. An archived employer is retained only when
 * it is already selected on the shift being edited, so history remains legible.
 */
export function selectableEmployers(
  employers: readonly Employer[],
  selectedEmployerId?: string | null
): Employer[] {
  return employers.filter(
    (employer) => !employer.archived || employer.id === selectedEmployerId
  );
}
