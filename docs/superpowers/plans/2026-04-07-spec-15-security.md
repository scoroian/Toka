# Spec-15 Security Rules & App Check — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Escribir tests exhaustivos de Security Rules de Firestore y configurar App Check en los entry points de Flutter.

**Architecture:** Tests TypeScript con `@firebase/rules-unit-testing` v3 contra el emulador Firestore (localhost:8080); cada colección tiene su propio archivo de test. App Check activado en `main_prod.dart` (providers reales) y `main_dev.dart` (providers debug).

**Tech Stack:** `@firebase/rules-unit-testing ^3`, `firebase ^10` (modular SDK para Firestore ops en tests), `ts-jest`, `firebase_app_check ^0.3`

> ⚠️ **PRERREQUISITO:** Los tests de rules requieren el emulador Firestore corriendo en `localhost:8080`.  
> Arrancar con: `firebase emulators:start --only firestore`

---

## Estructura de archivos

```
functions/
├── test/
│   └── rules/
│       ├── languages.test.ts   (NUEVO)
│       ├── users.test.ts       (NUEVO)
│       ├── homes.test.ts       (NUEVO)
│       └── reviews.test.ts     (NUEVO)
├── tsconfig.test.json          (NUEVO)
└── package.json                (MODIFICAR — deps + jest config)

lib/
├── main_prod.dart              (MODIFICAR — App Check real)
└── main_dev.dart               (MODIFICAR — App Check debug)

storage.rules                   (MODIFICAR — límite 5 MB)
```

---

## Task 1: Instalar dependencias y configurar tsconfig para tests

**Files:**
- Modify: `functions/package.json`
- Create: `functions/tsconfig.test.json`

- [ ] **Step 1: Actualizar `functions/package.json`**

Añadir devDependencies y actualizar jest config:

```json
{
  "name": "toka-functions",
  "scripts": {
    "build": "tsc",
    "test": "jest",
    "serve": "npm run build && firebase emulators:start --only functions",
    "shell": "npm run build && firebase functions:shell",
    "start": "npm run shell",
    "deploy": "firebase deploy --only functions",
    "logs": "firebase functions:log"
  },
  "engines": { "node": "20" },
  "main": "lib/index.js",
  "jest": {
    "preset": "ts-jest",
    "testEnvironment": "node",
    "testMatch": ["**/*.test.ts"],
    "moduleFileExtensions": ["ts", "js"],
    "transform": {
      "^.+\\.ts$": ["ts-jest", { "tsconfig": "tsconfig.test.json" }]
    }
  },
  "dependencies": {
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^6.0.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "@firebase/rules-unit-testing": "^3.0.0",
    "firebase": "^10.0.0",
    "typescript": "^5.0.0",
    "jest": "^29.0.0",
    "ts-jest": "^29.0.0",
    "@types/jest": "^29.0.0"
  },
  "private": true
}
```

- [ ] **Step 2: Crear `functions/tsconfig.test.json`**

```json
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "noUnusedLocals": false
  },
  "include": ["src", "test"]
}
```

- [ ] **Step 3: Instalar dependencias**

```bash
cd functions && npm install
```

Expected: se instalan `@firebase/rules-unit-testing` y `firebase` sin errores.

- [ ] **Step 4: Commit**

```bash
git add functions/package.json functions/tsconfig.test.json
git commit -m "chore(security): add rules-unit-testing deps and tsconfig.test.json"
```

---

## Task 2: Test de languages rules

**Files:**
- Create: `functions/test/rules/languages.test.ts`

- [ ] **Step 1: Crear `functions/test/rules/languages.test.ts`**

```typescript
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc } from 'firebase/firestore';
import { readFileSync } from 'fs';
import * as path from 'path';

let testEnv: RulesTestEnvironment;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-toka',
    firestore: {
      rules: readFileSync(path.resolve(__dirname, '../../../firestore.rules'), 'utf8'),
      host: 'localhost',
      port: 8080,
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

describe('languages security rules', () => {
  it('permite leer idiomas sin autenticación', async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertSucceeds(getDoc(doc(ctx.firestore(), 'languages/es')));
  });

  it('deniega escribir idiomas sin autenticación', async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(setDoc(doc(ctx.firestore(), 'languages/es'), { code: 'es' }));
  });

  it('deniega escribir idiomas con autenticación', async () => {
    const ctx = testEnv.authenticatedContext('user1');
    await assertFails(setDoc(doc(ctx.firestore(), 'languages/es'), { code: 'es' }));
  });
});
```

- [ ] **Step 2: Arrancar emulador y correr solo este test**

```bash
cd functions && npx jest test/rules/languages.test.ts --verbose
```

Expected:
```
PASS test/rules/languages.test.ts
  languages security rules
    ✓ permite leer idiomas sin autenticación
    ✓ deniega escribir idiomas sin autenticación
    ✓ deniega escribir idiomas con autenticación
```

- [ ] **Step 3: Commit**

```bash
git add functions/test/rules/languages.test.ts
git commit -m "test(security): add languages security rules tests"
```

---

## Task 3: Test de users rules

**Files:**
- Create: `functions/test/rules/users.test.ts`

- [ ] **Step 1: Crear `functions/test/rules/users.test.ts`**

```typescript
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc } from 'firebase/firestore';
import { readFileSync } from 'fs';
import * as path from 'path';

let testEnv: RulesTestEnvironment;
const USER1 = 'user1';
const USER2 = 'user2';
const HOME1 = 'home1';

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-toka',
    firestore: {
      rules: readFileSync(path.resolve(__dirname, '../../../firestore.rules'), 'utf8'),
      host: 'localhost',
      port: 8080,
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();

  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, `users/${USER1}`), {
      displayName: 'User One',
      baseHomeSlots: 2,
      lifetimeUnlockedHomeSlots: 0,
      homeSlotCap: 5,
    });
    await setDoc(doc(db, `users/${USER2}`), {
      displayName: 'User Two',
      baseHomeSlots: 2,
      lifetimeUnlockedHomeSlots: 0,
      homeSlotCap: 5,
    });
    await setDoc(doc(db, `users/${USER1}/memberships/${HOME1}`), {
      status: 'active',
      role: 'owner',
    });
  });
});

describe('users security rules', () => {
  it('usuario puede leer su propio perfil', async () => {
    const ctx = testEnv.authenticatedContext(USER1);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `users/${USER1}`)));
  });

  it('usuario NO puede leer perfil de otro usuario', async () => {
    const ctx = testEnv.authenticatedContext(USER1);
    await assertFails(getDoc(doc(ctx.firestore(), `users/${USER2}`)));
  });

  it('usuario puede actualizar su perfil', async () => {
    const ctx = testEnv.authenticatedContext(USER1);
    await assertSucceeds(
      updateDoc(doc(ctx.firestore(), `users/${USER1}`), { displayName: 'Nuevo nombre' })
    );
  });

  it('usuario NO puede modificar baseHomeSlots', async () => {
    const ctx = testEnv.authenticatedContext(USER1);
    await assertFails(
      updateDoc(doc(ctx.firestore(), `users/${USER1}`), { baseHomeSlots: 10 })
    );
  });

  it('usuario NO puede modificar lifetimeUnlockedHomeSlots', async () => {
    const ctx = testEnv.authenticatedContext(USER1);
    await assertFails(
      updateDoc(doc(ctx.firestore(), `users/${USER1}`), { lifetimeUnlockedHomeSlots: 5 })
    );
  });

  it('usuario puede leer sus membresías', async () => {
    const ctx = testEnv.authenticatedContext(USER1);
    await assertSucceeds(
      getDoc(doc(ctx.firestore(), `users/${USER1}/memberships/${HOME1}`))
    );
  });

  it('usuario NO puede leer membresías de otro', async () => {
    const ctx = testEnv.authenticatedContext(USER1);
    await assertFails(
      getDoc(doc(ctx.firestore(), `users/${USER2}/memberships/${HOME1}`))
    );
  });
});
```

- [ ] **Step 2: Correr el test**

```bash
cd functions && npx jest test/rules/users.test.ts --verbose
```

Expected:
```
PASS test/rules/users.test.ts
  users security rules
    ✓ usuario puede leer su propio perfil
    ✓ usuario NO puede leer perfil de otro usuario
    ✓ usuario puede actualizar su perfil
    ✓ usuario NO puede modificar baseHomeSlots
    ✓ usuario NO puede modificar lifetimeUnlockedHomeSlots
    ✓ usuario puede leer sus membresías
    ✓ usuario NO puede leer membresías de otro
```

- [ ] **Step 3: Commit**

```bash
git add functions/test/rules/users.test.ts
git commit -m "test(security): add users security rules tests"
```

---

## Task 4: Test de homes rules

**Files:**
- Create: `functions/test/rules/homes.test.ts`

- [ ] **Step 1: Crear `functions/test/rules/homes.test.ts`**

```typescript
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc } from 'firebase/firestore';
import { readFileSync } from 'fs';
import * as path from 'path';

let testEnv: RulesTestEnvironment;
const HOME1 = 'home1';
const ADMIN_UID = 'admin1';
const MEMBER_UID = 'member1';
const FROZEN_UID = 'frozen1';
const OUTSIDER_UID = 'outsider1';

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-toka',
    firestore: {
      rules: readFileSync(path.resolve(__dirname, '../../../firestore.rules'), 'utf8'),
      host: 'localhost',
      port: 8080,
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();

  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();

    await setDoc(doc(db, `homes/${HOME1}`), {
      ownerUid: ADMIN_UID,
      name: 'Test Home',
    });

    await setDoc(doc(db, `homes/${HOME1}/tasks/task1`), {
      title: 'Limpiar cocina',
      status: 'pending',
    });

    await setDoc(doc(db, `users/${ADMIN_UID}/memberships/${HOME1}`), {
      status: 'active',
      role: 'owner',
    });
    await setDoc(doc(db, `users/${MEMBER_UID}/memberships/${HOME1}`), {
      status: 'active',
      role: 'member',
    });
    await setDoc(doc(db, `users/${FROZEN_UID}/memberships/${HOME1}`), {
      status: 'frozen',
      role: 'member',
    });
    // OUTSIDER_UID intencionalmente sin membresía
  });
});

describe('homes security rules', () => {
  it('miembro activo puede leer el hogar', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}`)));
  });

  it('miembro congelado puede leer el hogar', async () => {
    const ctx = testEnv.authenticatedContext(FROZEN_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}`)));
  });

  it('NO miembro NO puede leer el hogar', async () => {
    const ctx = testEnv.authenticatedContext(OUTSIDER_UID);
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}`)));
  });

  it('admin puede crear tareas', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertSucceeds(
      setDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task2`), {
        title: 'Nueva tarea',
        status: 'pending',
      })
    );
  });

  it('miembro normal NO puede crear tareas', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertFails(
      setDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task3`), {
        title: 'Intento no permitido',
        status: 'pending',
      })
    );
  });

  it('miembro puede leer tareas del hogar', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task1`)));
  });

  it('usuario externo NO puede leer tareas', async () => {
    const ctx = testEnv.authenticatedContext(OUTSIDER_UID);
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task1`)));
  });
});
```

- [ ] **Step 2: Correr el test**

```bash
cd functions && npx jest test/rules/homes.test.ts --verbose
```

Expected:
```
PASS test/rules/homes.test.ts
  homes security rules
    ✓ miembro activo puede leer el hogar
    ✓ miembro congelado puede leer el hogar
    ✓ NO miembro NO puede leer el hogar
    ✓ admin puede crear tareas
    ✓ miembro normal NO puede crear tareas
    ✓ miembro puede leer tareas del hogar
    ✓ usuario externo NO puede leer tareas
```

- [ ] **Step 3: Commit**

```bash
git add functions/test/rules/homes.test.ts
git commit -m "test(security): add homes security rules tests"
```

---

## Task 5: Test de reviews rules

**Files:**
- Create: `functions/test/rules/reviews.test.ts`

- [ ] **Step 1: Crear `functions/test/rules/reviews.test.ts`**

```typescript
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc } from 'firebase/firestore';
import { readFileSync } from 'fs';
import * as path from 'path';

let testEnv: RulesTestEnvironment;
const HOME1 = 'home1';
const EVENT1 = 'event1';
const REVIEWER_UID = 'reviewer1';
const PERFORMER_UID = 'performer1';
const THIRD_MEMBER_UID = 'member3';
const OUTSIDER_UID = 'outsider1';

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-toka',
    firestore: {
      rules: readFileSync(path.resolve(__dirname, '../../../firestore.rules'), 'utf8'),
      host: 'localhost',
      port: 8080,
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();

  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();

    await setDoc(doc(db, `homes/${HOME1}`), { ownerUid: REVIEWER_UID });

    // El taskEvent contiene performerUid — necesario para la rule de reviews
    await setDoc(doc(db, `homes/${HOME1}/taskEvents/${EVENT1}`), {
      performerUid: PERFORMER_UID,
      taskId: 'task1',
    });

    // Review cuyo doc ID es el uid del autor (reviewerUid)
    await setDoc(
      doc(db, `homes/${HOME1}/taskEvents/${EVENT1}/reviews/${REVIEWER_UID}`),
      { rating: 5, note: 'Buen trabajo' }
    );

    await setDoc(doc(db, `users/${REVIEWER_UID}/memberships/${HOME1}`), {
      status: 'active',
      role: 'owner',
    });
    await setDoc(doc(db, `users/${PERFORMER_UID}/memberships/${HOME1}`), {
      status: 'active',
      role: 'member',
    });
    await setDoc(doc(db, `users/${THIRD_MEMBER_UID}/memberships/${HOME1}`), {
      status: 'active',
      role: 'member',
    });
    // OUTSIDER_UID sin membresía
  });
});

describe('reviews security rules', () => {
  it('autor de review puede leer su review', async () => {
    const ctx = testEnv.authenticatedContext(REVIEWER_UID);
    await assertSucceeds(
      getDoc(
        doc(ctx.firestore(), `homes/${HOME1}/taskEvents/${EVENT1}/reviews/${REVIEWER_UID}`)
      )
    );
  });

  it('evaluado puede leer la review sobre él', async () => {
    const ctx = testEnv.authenticatedContext(PERFORMER_UID);
    await assertSucceeds(
      getDoc(
        doc(ctx.firestore(), `homes/${HOME1}/taskEvents/${EVENT1}/reviews/${REVIEWER_UID}`)
      )
    );
  });

  it('tercero miembro del hogar NO puede leer la nota textual', async () => {
    const ctx = testEnv.authenticatedContext(THIRD_MEMBER_UID);
    await assertFails(
      getDoc(
        doc(ctx.firestore(), `homes/${HOME1}/taskEvents/${EVENT1}/reviews/${REVIEWER_UID}`)
      )
    );
  });

  it('usuario externo NO puede leer ninguna review', async () => {
    const ctx = testEnv.authenticatedContext(OUTSIDER_UID);
    await assertFails(
      getDoc(
        doc(ctx.firestore(), `homes/${HOME1}/taskEvents/${EVENT1}/reviews/${REVIEWER_UID}`)
      )
    );
  });
});
```

- [ ] **Step 2: Correr el test**

```bash
cd functions && npx jest test/rules/reviews.test.ts --verbose
```

Expected:
```
PASS test/rules/reviews.test.ts
  reviews security rules
    ✓ autor de review puede leer su review
    ✓ evaluado puede leer la review sobre él
    ✓ tercero miembro del hogar NO puede leer la nota textual
    ✓ usuario externo NO puede leer ninguna review
```

- [ ] **Step 3: Commit**

```bash
git add functions/test/rules/reviews.test.ts
git commit -m "test(security): add reviews security rules tests"
```

---

## Task 6: Actualizar storage.rules (límite 5 MB)

El manual test especifica que 6 MB debe ser denegado. La regla actual permite hasta 10 MB — hay que corregirla a 5 MB.

**Files:**
- Modify: `storage.rules:11`

- [ ] **Step 1: Cambiar límite de 10 MB a 5 MB**

En `storage.rules`, línea 11, cambiar:
```
request.resource.size < 10 * 1024 * 1024 && // Máx 10MB
```
por:
```
request.resource.size < 5 * 1024 * 1024 && // Máx 5MB
```

- [ ] **Step 2: Commit**

```bash
git add storage.rules
git commit -m "fix(security): reduce Storage max upload size to 5 MB"
```

---

## Task 7: App Check en main_prod.dart

**Files:**
- Modify: `lib/main_prod.dart`

- [ ] **Step 1: Añadir App Check al `main()` de producción**

Añadir el import y la llamada `activate` justo antes de `runZonedGuarded`:

```dart
import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'shared/services/analytics_service.dart';
import 'shared/services/crashlytics_service.dart';
import 'shared/services/remote_config_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.deviceCheck,
  );

  // Inicializar observabilidad antes de runApp
  final crashlyticsService = CrashlyticsService(FirebaseCrashlytics.instance);
  await crashlyticsService.init();

  final remoteConfigService = RemoteConfigService(FirebaseRemoteConfig.instance);
  await remoteConfigService.init();

  // AnalyticsService disponible pero no requiere init async
  final analyticsService = AnalyticsService(FirebaseAnalytics.instance);

  // Capturar errores no manejados de Dart
  runZonedGuarded(
    () => runApp(const ProviderScope(
      child: TokaApp(),
    )),
    (error, stack) {
      analyticsService.logEvent('unhandled_error');
      crashlyticsService.recordError(error, stack, fatal: true);
    },
  );
}
```

- [ ] **Step 2: Verificar análisis estático**

```bash
flutter analyze lib/main_prod.dart
```

Expected: sin errores.

- [ ] **Step 3: Commit**

```bash
git add lib/main_prod.dart
git commit -m "feat(security): activate App Check (PlayIntegrity/DeviceCheck) in prod"
```

---

## Task 8: App Check en main_dev.dart

**Files:**
- Modify: `lib/main_dev.dart`

- [ ] **Step 1: Añadir App Check debug al `main()` de desarrollo**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'shared/services/remote_config_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  // Connect to local emulators
  await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);

  // En dev: inicializar RemoteConfig (usa emuladores si están disponibles)
  final remoteConfigService = RemoteConfigService(FirebaseRemoteConfig.instance);
  await remoteConfigService.init();

  // En dev: Crashlytics solo captura errores localmente, no envía a producción
  FlutterError.onError = (errorDetails) {
    debugPrint('FlutterError: ${errorDetails.exceptionAsString()}');
  };

  runApp(const ProviderScope(child: TokaApp()));
}
```

- [ ] **Step 2: Verificar análisis estático**

```bash
flutter analyze lib/main_dev.dart
```

Expected: sin errores.

- [ ] **Step 3: Commit**

```bash
git add lib/main_dev.dart
git commit -m "feat(security): activate App Check (debug) in dev"
```

---

## Task 9: Correr todos los tests de rules

- [ ] **Step 1: Arrancar el emulador (terminal separada)**

```bash
firebase emulators:start --only firestore
```

- [ ] **Step 2: Correr la suite completa**

```bash
cd functions && npm test -- --verbose
```

Expected: 21 tests passing (3 languages + 7 users + 7 homes + 4 reviews).

- [ ] **Step 3: Confirmar resultado y commit final si todo pasa**

```bash
git add -A
git commit -m "test(security): all 21 security rules tests passing"
```

---

## Pruebas manuales requeridas al terminar

1. **Cross-hogar:** Con dos cuentas en hogares distintos, intentar leer directamente `homes/{otroHomeId}` vía SDK → debe ser denegado (permissionDenied).
2. **Nota privada:** Con cuenta C (mismo hogar), intentar leer `homes/{homeId}/taskEvents/{id}/reviews/{uid_A}` → denegado.
3. **App Check debug:** En modo dev con `main_dev.dart`, verificar en la consola Firebase que las llamadas a Firestore llevan token de debug.
4. **Storage — cross-user:** Intentar subir foto a `users/{uid_ajeno}/profile.jpg` → denegado.
5. **Storage — tamaño:** Subir un archivo de 6 MB → denegado (excede el límite de 5 MB).
