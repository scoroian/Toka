// functions/test/integration/helpers/global_setup.js
// Se ejecuta una sola vez antes de todos los tests de integración.
// Establece las variables de entorno necesarias para que firebase-admin
// apunte a los emuladores.

module.exports = async function () {
  process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
  process.env.FIREBASE_AUTH_EMULATOR_HOST = 'localhost:9099';
  process.env.FIREBASE_STORAGE_EMULATOR_HOST = 'localhost:9199';
  process.env.GCLOUD_PROJECT = 'demo-toka-integration';
};
