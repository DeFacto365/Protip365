import { create } from 'zustand';

import { weeklyGoalsRepo } from '../data/repositories';
import { addDaysIso } from '../domain/dates';
import type { WeeklyGoal } from '../domain/types';
import { assertWriteAccess } from './entitlementStore';

interface GoalsState {
  goals: WeeklyGoal[];
  loaded: boolean;
  load: () => void;
  addGoal: (input: Omit<WeeklyGoal, 'id'>) => WeeklyGoal;
  ensureRepeatedForWeek: (weekStart: string) => void;
}

export const useGoalsStore = create<GoalsState>((set, get) => ({
  goals: [],
  loaded: false,

  load: () => set({ goals: weeklyGoalsRepo.list(), loaded: true }),

  addGoal: (input) => {
    assertWriteAccess();
    const goal = weeklyGoalsRepo.create(input);
    set((state) => ({ goals: [...state.goals, goal] }));
    return goal;
  },

  ensureRepeatedForWeek: (weekStart) => {
    const previousWeek = addDaysIso(weekStart, -7);
    const state = get();
    const repeated = state.goals.filter((goal) => goal.weekStart === previousWeek && goal.repeat);
    for (const source of repeated) {
      const exists = get().goals.some(
        (goal) =>
          goal.weekStart === weekStart &&
          goal.metric === source.metric &&
          (goal.employerId ?? null) === (source.employerId ?? null)
      );
      if (!exists) {
        const { id: _id, ...copy } = source;
        get().addGoal({ ...copy, weekStart });
      }
    }
  },
}));
