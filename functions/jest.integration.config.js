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
  // setupFiles corre en el worker ANTES de cargar módulos de test,
  // garantizando que firebase-admin esté inicializado cuando los imports evalúan
  // archivos fuente que llaman admin.firestore() a nivel de módulo.
  setupFiles: ['./test/integration/helpers/setup_env.js'],
  testTimeout: 30000,
};
