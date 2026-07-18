/** Jest runs the pure domain layer only (no React Native runtime needed). */
module.exports = {
  testEnvironment: 'node',
  roots: ['<rootDir>/src/domain'],
  transform: {
    '^.+\\.tsx?$': [
      'ts-jest',
      { tsconfig: { jsx: 'react-jsx', module: 'commonjs', types: ['jest'] } },
    ],
  },
  moduleFileExtensions: ['ts', 'tsx', 'js'],
};
