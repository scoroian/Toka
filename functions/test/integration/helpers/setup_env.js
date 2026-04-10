// functions/test/integration/helpers/setup_env.js
//
// Se ejecuta en CADA worker de Jest ANTES de que se carguen módulos de test.
// setupFiles (a diferencia de globalSetup) corre en el mismo proceso que los tests,
// por lo que las variables de entorno y la inicialización de firebase-admin
// están disponibles cuando los imports de los archivos fuente se evalúan.

process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST = 'localhost:9099';
process.env.FIREBASE_STORAGE_EMULATOR_HOST = 'localhost:9199';
process.env.GCLOUD_PROJECT = 'demo-toka-integration';

const admin = require('firebase-admin');
if (!admin.apps.length) {
  admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT });
}
