jest.mock('react-native', () => ({
  View: 'View',
  ScrollView: 'ScrollView',
  Alert: { alert: jest.fn() },
}));
jest.mock('expo-router', () => ({
  Stack: { Screen: () => null },
  useLocalSearchParams: () => ({ id: 's' }),
  useRouter: () => ({ replace: mockReplace, dismissTo: jest.fn() }),
}));
jest.mock('react-i18next', () => ({ useTranslation: () => ({ t: (key: string) => key }) }));
jest.mock('../../ui/FormScreen', () => ({ FormScreen: 'FormScreen' }));
jest.mock('../../ui/typography', () => ({ Text: 'Text' }));
jest.mock('../../ui/components', () => ({
  Card: 'Card',
  Chip: 'Chip',
  Field: 'Field',
  GhostButton: 'GhostButton',
  PrimaryButton: 'PrimaryButton',
  money: String,
  signedMoney: String,
}));
jest.mock('../../ui/DateTimeField', () => ({ TimePickerField: 'TimePickerField' }));
jest.mock('../../ui/tokens', () => ({ useTokens: () => ({ t: {} }) }));
jest.mock('../../ui/WriteAccess', () => ({
  WriteAccessBanner: () => null,
  useWriteAccess: () => ({ requireWrite: () => true }),
}));
jest.mock('../../state/employersStore', () => ({
  useEmployersStore: (fn: any) =>
    fn({
      employers: [{ id: 'e', name: 'Cafe', deductionRateBp: 0 }],
      roles: [{ id: 'role', hourlyRate: 8000 }],
    }),
}));
jest.mock('../../state/settingsStore', () => ({
  useSettingsStore: (fn: any) => fn({ currencyCode: 'CAD', defaultDeductionRateBp: 0 }),
}));
jest.mock('../../state/shiftsStore', () => ({
  useShiftsStore: (fn: any) =>
    fn({
      getById: () => ({
        id: 's',
        employerId: 'e',
        roleId: 'role',
        date: '2026-09-13',
        startMin: 960,
        endMin: 1320,
        breaks: [],
        hourlyRateSnapshot: 2000,
        status: 'planned',
        updatedAt: 'v1',
      }),
      completeShift: (...args: any[]) => mockComplete(...args),
    }),
}));
jest.mock('../../data/paymentsRepo', () => ({
  paymentsRepo: { list: () => ({ expected: [], receipts: [], allocations: [] }) },
}));
jest.mock('../../data/repositories', () => ({ settingsRepo: { get: () => null } }));
jest.mock('../../data/completionDrafts', () => ({
  readCompletionDraft: () => mockDraft,
  saveCompletionDraft: (...args: any[]) => mockSaveDraft(...args),
}));
import React from 'react';
import Screen from '../../../app/complete/[id]';
const { create, act } = require('react-test-renderer');
const mockComplete = jest.fn();
const mockReplace = jest.fn();
const mockSaveDraft = jest.fn();
let mockDraft: any = null;
let tree: any;
beforeEach(() => {
  (globalThis as any).IS_REACT_ACT_ENVIRONMENT = true;
  mockDraft = null;
  mockComplete.mockReset().mockResolvedValue({ id: 's' });
  mockReplace.mockReset();
  mockSaveDraft.mockReset();
  act(() => {
    tree = create(React.createElement(Screen));
  });
});
afterEach(() => act(() => tree.unmount()));
function button(label: string) {
  return tree.root.findAllByType('PrimaryButton').find((n: any) => n.props.label === label);
}
function fill(label: string, value: string) {
  act(() =>
    tree.root
      .findAllByType('Field')
      .find((n: any) => n.props.label === label)
      .props.onChangeText(value)
  );
}
test('close-out saves earnings and receipt timing together, then shows the result', async () => {
  act(() => button('common.next').props.onPress());
  fill('redesign.directTips', '200');
  fill('redesign.tipOut', '40');
  fill('redesign.received', '60');
  fill('redesign.awaiting', '100');
  await act(async () => {
    await button('complete.saveWorked').props.onPress();
  });
  expect(mockComplete).toHaveBeenCalledWith(
    's',
    expect.objectContaining({
      actualHourlyRateSnapshot: 2000,
      directTips: 20000,
      tipOutPaid: 4000,
      settlement: expect.objectContaining({ received: 6000, later: 10000, currency: 'CAD' }),
    })
  );
  expect(mockReplace).toHaveBeenCalledWith({ pathname: '/shift-result/[id]', params: { id: 's' } });
});
test('receipt timing is restored after an interrupted form', () => {
  act(() => button('common.next').props.onPress());
  fill('redesign.received', '60');
  fill('redesign.awaiting', '100');
  mockDraft = mockSaveDraft.mock.calls.at(-1)[2];
  act(() => tree.unmount());
  act(() => {
    tree = create(React.createElement(Screen));
  });
  expect(
    tree.root.findAllByType('Field').find((n: any) => n.props.label === 'redesign.received').props
      .value
  ).toBe('60');
  expect(
    tree.root.findAllByType('Field').find((n: any) => n.props.label === 'redesign.awaiting').props
      .value
  ).toBe('100');
});
test('malformed tips cannot silently become zero earnings', async () => {
  act(() => button('common.next').props.onPress());
  fill('redesign.directTips', 'abc');
  await act(async () => {
    await button('complete.saveWorked').props.onPress();
  });
  expect(mockComplete).not.toHaveBeenCalled();
});
