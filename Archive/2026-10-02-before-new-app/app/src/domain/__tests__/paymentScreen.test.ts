jest.mock('react-native', () => ({ View: 'View' }));
jest.mock('expo-router', () => ({
  Stack: { Screen: () => null },
  useLocalSearchParams: () => ({}),
  useRouter: () => ({ back: mockBack }),
}));
jest.mock('react-i18next', () => ({ useTranslation: () => ({ t: (key: string) => key }) }));
jest.mock('../../ui/FormScreen', () => ({ FormScreen: 'FormScreen' }));
jest.mock('../../ui/typography', () => ({ Text: 'Text' }));
jest.mock('../../ui/components', () => ({
  Chip: 'Chip',
  Field: 'Field',
  PrimaryButton: 'PrimaryButton',
}));
jest.mock('../../ui/DateTimeField', () => ({ DatePickerField: 'DatePickerField' }));
jest.mock('../../ui/tokens', () => ({ useTokens: () => ({ t: {} }) }));
jest.mock('../../ui/WriteAccess', () => ({
  useWriteAccess: () => ({ requireWrite: () => mockWritable }),
}));
jest.mock('../../state/employersStore', () => ({
  useEmployersStore: (fn: any) => fn({ employers: [{ id: 'e', name: 'Cafe' }] }),
}));
jest.mock('../../state/shiftsStore', () => ({
  useShiftsStore: (fn: any) =>
    fn({
      shifts: [
        { id: 'one', date: '2026-09-13' },
        { id: 'two', date: '2026-09-14' },
      ],
    }),
}));
jest.mock('../../state/settingsStore', () => ({
  useSettingsStore: (fn: any) => fn({ currencyCode: 'CAD' }),
}));
jest.mock('../../data/paymentsRepo', () => ({
  paymentsRepo: {
    list: () => ({
      expected: [
        {
          id: 'a',
          employerId: 'e',
          shiftId: 'one',
          kind: 'tips',
          amount: 10000,
          currency: 'CAD',
          dueDate: null,
          disputed: false,
        },
        {
          id: 'b',
          employerId: 'e',
          shiftId: 'two',
          kind: 'tips',
          amount: 8000,
          currency: 'CAD',
          dueDate: null,
          disputed: false,
        },
      ],
      receipts: [],
      allocations: [],
    }),
    record: (...args: any[]) => mockRecord(...args),
  },
}));
import React from 'react';
import Screen from '../../../app/record-payment';
const { create, act } = require('react-test-renderer');
const mockRecord = jest.fn();
const mockBack = jest.fn();
let mockWritable = true;
let tree: any;
beforeEach(() => {
  (globalThis as any).IS_REACT_ACT_ENVIRONMENT = true;
  mockRecord.mockReset();
  mockBack.mockReset();
  mockWritable = true;
  act(() => {
    tree = create(React.createElement(Screen));
  });
});
afterEach(() => act(() => tree.unmount()));
function fill(label: string, value: string) {
  act(() =>
    tree.root
      .findAllByType('Field')
      .find((n: any) => n.props.label.includes(label))
      .props.onChangeText(value)
  );
}
test('payment screen submits one dated payment with two allocations and blocks repeat tap', () => {
  fill('redesign.received', '150,00');
  fill('2026-09-13', '100');
  fill('2026-09-14', '50');
  const save = () => tree.root.findByType('PrimaryButton').props.onPress();
  act(save);
  act(save);
  expect(mockRecord).toHaveBeenCalledTimes(1);
  expect(mockRecord.mock.calls[0][0]).toMatchObject({
    amount: 15000,
    currency: 'CAD',
    employerId: 'e',
  });
  expect(mockRecord.mock.calls[0][1]).toEqual([
    expect.objectContaining({ expectedId: 'a', amount: 10000 }),
    expect.objectContaining({ expectedId: 'b', amount: 5000 }),
  ]);
  expect(mockBack).toHaveBeenCalledTimes(1);
});
test('failed save retains entry and permits retry', () => {
  fill('redesign.received', '150');
  mockRecord.mockImplementationOnce(() => {
    throw Error('disk');
  });
  act(() => tree.root.findByType('PrimaryButton').props.onPress());
  expect(mockBack).not.toHaveBeenCalled();
  expect(
    tree.root.findAllByType('Field').find((n: any) => n.props.label === 'redesign.received').props
      .value
  ).toBe('150');
  act(() => tree.root.findByType('PrimaryButton').props.onPress());
  expect(mockRecord).toHaveBeenCalledTimes(2);
});
test('expired write access and malformed money do not save', () => {
  fill('redesign.received', 'bad');
  act(() => tree.root.findByType('PrimaryButton').props.onPress());
  expect(mockRecord).not.toHaveBeenCalled();
  fill('redesign.received', '150');
  mockWritable = false;
  act(() => tree.root.findByType('PrimaryButton').props.onPress());
  expect(mockRecord).not.toHaveBeenCalled();
});
