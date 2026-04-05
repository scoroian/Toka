// Seed languages collection in the Firestore emulator.
// Usage: FIRESTORE_EMULATOR_HOST=localhost:8080 npx ts-node scripts/seed_languages.ts

import * as admin from 'firebase-admin';

process.env['FIRESTORE_EMULATOR_HOST'] = 'localhost:8080';
admin.initializeApp({ projectId: 'toka-dev' });

const db = admin.firestore();

const languages = [
  { code: 'es', name: 'Español',  flag: '🇪🇸', arb_key: 'app_es', enabled: true, sort_order: 1 },
  { code: 'en', name: 'English',  flag: '🇬🇧', arb_key: 'app_en', enabled: true, sort_order: 2 },
  { code: 'ro', name: 'Română',   flag: '🇷🇴', arb_key: 'app_ro', enabled: true, sort_order: 3 },
];

async function seed(): Promise<void> {
  for (const lang of languages) {
    await db.collection('languages').doc(lang.code).set(lang);
    console.log(`Seeded: ${lang.code}`);
  }
  console.log('Done.');
  process.exit(0);
}

seed().catch((err) => {
  console.error(err);
  process.exit(1);
});
