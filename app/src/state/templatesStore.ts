import { create } from 'zustand';

import type { RecurrenceRule, ScheduleTemplate } from '../domain/types';
import type { RecurringShiftPlan } from '../domain/copyWeek';
import {
  recurrenceRulesRepo,
  scheduleTemplatesRepo,
  type SaveRecurrenceSeriesResult,
} from '../data/repositories';
import { assertWriteAccess } from './entitlementStore';

interface TemplatesState {
  templates: ScheduleTemplate[];
  rules: RecurrenceRule[];
  loaded: boolean;
  load: () => void;
  addTemplate: (input: Omit<ScheduleTemplate, 'id' | 'archived'>) => ScheduleTemplate;
  updateTemplate: (template: ScheduleTemplate) => void;
  archiveTemplate: (id: string, archived: boolean) => void;
  addRule: (input: Omit<RecurrenceRule, 'id'> & { id?: string }) => RecurrenceRule;
  updateRule: (rule: RecurrenceRule) => void;
  saveSeries: (input: {
    rule: RecurrenceRule;
    preview: RecurringShiftPlan[];
    excludedKeys: string[];
    replaceDuplicates: boolean;
  }) => SaveRecurrenceSeriesResult;
  endRule: (id: string) => void;
}

export const useTemplatesStore = create<TemplatesState>((set) => ({
  templates: [],
  rules: [],
  loaded: false,

  load: () =>
    set({
      templates: scheduleTemplatesRepo.list(),
      rules: recurrenceRulesRepo.list(),
      loaded: true,
    }),

  addTemplate: (input) => {
    assertWriteAccess();
    const template = scheduleTemplatesRepo.create(input);
    set((state) => ({ templates: [...state.templates, template] }));
    return template;
  },

  updateTemplate: (template) => {
    assertWriteAccess();
    scheduleTemplatesRepo.update(template);
    set((state) => ({
      templates: state.templates.map((item) => (item.id === template.id ? template : item)),
    }));
  },

  archiveTemplate: (id, archived) => {
    assertWriteAccess();
    set((state) => {
      const template = state.templates.find((item) => item.id === id);
      if (!template) return state;
      const updated = { ...template, archived };
      scheduleTemplatesRepo.update(updated);
      return {
        templates: state.templates.map((item) => (item.id === id ? updated : item)),
      };
    });
  },

  addRule: (input) => {
    assertWriteAccess();
    const rule = recurrenceRulesRepo.create(input);
    set((state) => ({ rules: [...state.rules, rule] }));
    return rule;
  },

  updateRule: (rule) => {
    assertWriteAccess();
    recurrenceRulesRepo.update(rule);
    set((state) => ({
      rules: state.rules.map((item) => (item.id === rule.id ? rule : item)),
    }));
  },

  saveSeries: (input) => {
    assertWriteAccess();
    const result = recurrenceRulesRepo.saveSeries(input);
    set({ rules: recurrenceRulesRepo.list() });
    return result;
  },

  endRule: (id) => {
    assertWriteAccess();
    recurrenceRulesRepo.end(id);
    set((state) => ({
      rules: state.rules.map((rule) => (rule.id === id ? { ...rule, active: false } : rule)),
    }));
  },
}));
