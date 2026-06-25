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
  // setupFilesAfterEnv corre tras instalar el framework: fija el default del
  // flag de tiers (OFF, sin red) para no pegar a Remote Config en cada test.
  setupFilesAfterEnv: ['./test/integration/helpers/jest_setup.ts'],
  testTimeout: 30000,
};
