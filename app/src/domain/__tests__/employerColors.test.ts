jest.mock('react-native', () => ({ useColorScheme: jest.fn(() => 'light') }));

import {
  EMPLOYER_PALETTE,
  LEGACY_BLUE_EMPLOYER_COLOR,
  RUST_EMPLOYER_COLOR,
  normalizeEmployerColor,
} from '../employerColors';
import { dark, light } from '../../ui/tokens';

describe('no-blue app palette', () => {
  it('uses receipt ink for every legacy blue interaction token', () => {
    expect([light.pen, light.cobalt, light.cobaltLink]).toEqual([
      light.ink,
      light.ink,
      light.ink,
    ]);
    expect([dark.pen, dark.cobalt, dark.cobaltLink]).toEqual([
      dark.ink,
      dark.ink,
      dark.ink,
    ]);
  });

  it('does not offer the retired cobalt employer swatch', () => {
    expect(EMPLOYER_PALETTE).not.toContain(LEGACY_BLUE_EMPLOYER_COLOR);
    expect(normalizeEmployerColor(LEGACY_BLUE_EMPLOYER_COLOR)).toBe(RUST_EMPLOYER_COLOR);
    expect(normalizeEmployerColor('#2b4bd7')).toBe(RUST_EMPLOYER_COLOR);
  });
});
