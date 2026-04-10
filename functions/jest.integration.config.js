// functions/jest.integration.config.js
// Configuración separada para tests de integración contra emuladores.
// Se usa --runInBand porque los tests comparten estado de Firestore.

module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  testMatch: ['**/test/integration/**/*.test.ts'],
  moduleFileExtensions: ['ts', 'js'],
  transform: {
    '^.+\\.ts$': ['ts-jest', { tsconfig: 'tsconfig.test.json' }],
  },
  testEnvironmentOptions: {},
  globalSetup: './test/integration/helpers/global_setup.js',
};
