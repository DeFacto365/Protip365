import { create } from 'zustand';
import type { Employer, Role } from '../domain/types';
import { employersRepo, rolesRepo } from '../data/repositories';
import { assertWriteAccess } from './entitlementStore';

interface EmployersState {
  employers: Employer[];
  roles: Role[];
  loaded: boolean;
  load: () => void;
  addEmployer: (input: Omit<Employer, 'id' | 'archived'>) => Employer;
  updateEmployer: (employer: Employer) => void;
  archiveEmployer: (id: string, archived: boolean) => void;
  /** Hard deletion is unsupported; this always returns false. */
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
    assertWriteAccess();
    const employer = employersRepo.create(input);
    set((s) => ({ employers: [...s.employers, employer] }));
    return employer;
  },

  updateEmployer: (employer) => {
    assertWriteAccess();
    employersRepo.update(employer);
    set((s) => ({
      employers: s.employers.map((e) => (e.id === employer.id ? employer : e)),
    }));
  },

  archiveEmployer: (id, archived) => {
    assertWriteAccess();
    employersRepo.archive(id, archived);
    set((s) => ({
      employers: s.employers.map((e) => (e.id === id ? { ...e, archived } : e)),
    }));
  },

  removeEmployer: (id) => {
    assertWriteAccess();
    try {
      employersRepo.remove(id);
    } catch {
      return false;
    }
    return false;
  },

  addRole: (input) => {
    assertWriteAccess();
    const role = rolesRepo.create(input);
    set((s) => ({ roles: [...s.roles, role] }));
    return role;
  },

  updateRole: (role) => {
    assertWriteAccess();
    rolesRepo.update(role);
    set((s) => ({ roles: s.roles.map((r) => (r.id === role.id ? role : r)) }));
  },

  removeRole: (id) => {
    assertWriteAccess();
    rolesRepo.remove(id);
    set((s) => ({ roles: s.roles.filter((r) => r.id !== id) }));
  },

  rolesForEmployer: (employerId) => get().roles.filter((r) => r.employerId === employerId),
}));
