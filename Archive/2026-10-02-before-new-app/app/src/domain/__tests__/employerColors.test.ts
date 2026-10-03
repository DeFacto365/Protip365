jest.mock('react-native', () => ({ useColorScheme: jest.fn(() => 'light') }));

import {
  EMPLOYER_PALETTE,
  LEGACY_BLUE_EMPLOYER_COLOR,
  RUST_EMPLOYER_COLOR,
  normalizeEmployerColor,
} from '../employerColors';
import { dark, light } from '../../ui/tokens';

describe('no-blue app palette', () => {
  it('uses one teal action accent per theme', () => {
    expect([light.pen, light.cobalt, light.cobaltLink]).toEqual([
      light.pen,
      light.pen,
      light.pen,
    ]);
    expect([dark.pen, dark.cobalt, dark.cobaltLink]).toEqual([
      dark.pen,
      dark.pen,
      dark.pen,
    ]);
  });

  it('does not offer the retired cobalt employer swatch', () => {
    expect(EMPLOYER_PALETTE).not.toContain(LEGACY_BLUE_EMPLOYER_COLOR);
    expect(normalizeEmployerColor(LEGACY_BLUE_EMPLOYER_COLOR)).toBe(RUST_EMPLOYER_COLOR);
    expect(normalizeEmployerColor('#2b4bd7')).toBe(RUST_EMPLOYER_COLOR);
  });
});
