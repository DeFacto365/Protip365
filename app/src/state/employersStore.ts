import { create } from 'zustand';
import type { Employer, Role } from '../domain/types';
import { employersRepo, rolesRepo } from '../data/repositories';

interface EmployersState {
  employers: Employer[];
  roles: Role[];
  loaded: boolean;
  load: () => void;
  addEmployer: (input: Omit<Employer, 'id'>) => Employer;
  updateEmployer: (employer: Employer) => void;
  /** Returns false (and changes nothing) when the employer has historical shifts (DEF-08). */
  removeEmployer: (id: string) => boolean;
  addRole: (input: Omit<Role, 'id'>) => Role;
  updateRole: (role: Role) => void;
  removeRole: (id: string) => void;
  rolesForEmployer: (employerId: string) => Role[];
}

export const useEmployersStore = create<EmployersState>((set, get) => ({
  employers: [],
  roles: [],
  loaded: false,

  load: () => {
    set({ employers: employersRepo.list(), roles: rolesRepo.list(), loaded: true });
  },

  addEmployer: (input) => {
    const employer = employersRepo.create(input);
    set((s) => ({ employers: [...s.employers, employer] }));
    return employer;
  },

  updateEmployer: (employer) => {
    employersRepo.update(employer);
    set((s) => ({
      employers: s.employers.map((e) => (e.id === employer.id ? employer : e)),
    }));
  },

  removeEmployer: (id) => {
    try {
      employersRepo.remove(id);
    } catch {
      return false; // employer_has_shifts — never hard-delete history (DEF-08)
    }
    set((s) => ({
      employers: s.employers.filter((e) => e.id !== id),
      roles: s.roles.filter((r) => r.employerId !== id),
    }));
    return true;
  },

  addRole: (input) => {
    const role = rolesRepo.create(input);
    set((s) => ({ roles: [...s.roles, role] }));
    return role;
  },

  updateRole: (role) => {
    rolesRepo.update(role);
    set((s) => ({ roles: s.roles.map((r) => (r.id === role.id ? role : r)) }));
  },

  removeRole: (id) => {
    rolesRepo.remove(id);
    set((s) => ({ roles: s.roles.filter((r) => r.id !== id) }));
  },

  rolesForEmployer: (employerId) => get().roles.filter((r) => r.employerId === employerId),
}));
