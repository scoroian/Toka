// Seed the `languages` collection in real Firebase.
//
// One-time setup:
//   1. Firebase Console → Project Settings → Service Accounts
//      → Generate new private key → save as scripts/service-account.json
//   2. npm install -g ts-node   (if not already installed)
//
// Run:
//   npx ts-node scripts/seed_languages.ts
//
// ⚠️  scripts/service-account.json must NOT be committed to git.

import * as admin from 'firebase-admin';
import * as path from 'path';

const serviceAccount = require(path.resolve(__dirname, 'service-account.json'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const languages = [
  { code: 'es', name: 'Español', flag: '🇪🇸', arb_key: 'app_es', enabled: true, sort_order: 1 },
  { code: 'en', name: 'English', flag: '🇬🇧', arb_key: 'app_en', enabled: true, sort_order: 2 },
  { code: 'ro', name: 'Română',  flag: '🇷🇴', arb_key: 'app_ro', enabled: true, sort_order: 3 },
];

async function seed(): Promise<void> {
  for (const lang of languages) {
    await db.collection('languages').doc(lang.code).set(lang);
    console.log(`✓ Seeded: ${lang.code}`);
  }
  console.log('Done.');
  process.exit(0);
}

seed().catch((err) => {
  console.error(err);
  process.exit(1);
});
