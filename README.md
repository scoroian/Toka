# Toka — Proyecto para Claude Code

Especificación completa lista para desarrollo con Claude Code + plugin VS Code.

---

## Estructura de este repositorio

```
toka-claude-code/
├── CLAUDE.md                    ← Instrucciones maestras (leer primero)
├── AGENTS.md                    ← Agentes especializados disponibles
├── execution-order.md           ← ORDEN DE EJECUCIÓN DE LAS SPECS
├── firestore.rules              ← Security Rules de Firestore
├── firestore.indexes.json       ← Índices compuestos de Firestore
├── storage.rules                ← Security Rules de Storage
├── architecture/
│   └── data-model.md            ← Modelo de datos completo de Firestore
└── specs/
    ├── spec-00-project-setup.md
    ├── spec-01-i18n.md
    ├── spec-02-auth.md
    ├── spec-03-onboarding.md
    ├── spec-04-homes.md
    ├── spec-05-tasks.md
    ├── spec-06-today-screen.md
    ├── spec-07-completion-pass.md
    ├── spec-08-members-profiles.md
    ├── spec-09-history.md
    ├── spec-10-subscription.md
    ├── spec-11-14-notifications-reviews-smart-settings.md
    └── spec-15-security.md
```

---

## Cómo empezar

### 1. Preparativos previos (tú, antes de usar Claude Code)

- [ ] Crear proyecto en [Firebase Console](https://console.firebase.google.com)
- [ ] Habilitar: Auth (Google, Apple, email), Firestore, Storage, Functions, FCM, Analytics, Crashlytics, Remote Config, App Check, AdMob
- [ ] Tener Flutter 3.x instalado
- [ ] Tener Node.js 20+ instalado
- [ ] Tener Firebase CLI instalado: `npm install -g firebase-tools`
- [ ] Autenticarse: `firebase login`

### 2. Copiar este directorio a tu workspace de VS Code

Coloca todos estos archivos en la raíz de tu workspace donde trabajará Claude Code.

### 3. Primer mensaje a Claude Code

```
Lee el archivo CLAUDE.md y el archivo execution-order.md para entender el proyecto.
Luego lee specs/spec-00-project-setup.md y crea el proyecto Flutter desde cero
siguiendo todas las instrucciones. Al terminar, muéstrame las pruebas manuales.
```

### 4. Mensajes sucesivos (una spec a la vez)

```
Lee specs/xxxxx.md e impleméntala completamente.
Ejecuta todos los tests al terminar y muéstrame las pruebas manuales requeridas.
```

---

## Convención de cierre de spec

Al terminar cada spec, Claude Code debe imprimir:

```
## ✅ Spec-XX completada

### Tests ejecutados
- Unit: 12/12 ✓
- Integration: 4/4 ✓
- UI: 3/3 ✓

### Archivos creados
- lib/features/xxx/...
- lib/features/yyy/...

### Archivos modificados
- pubspec.yaml
- lib/app.dart

## 🧪 Pruebas manuales requeridas
1. ...
2. ...
3. ...
```

Si algún test falla, el formato es:

```
## ❌ Spec-XX — Tests fallidos

### Fallos
- test/unit/xxx_test.dart: FAILED
  Expected: ...
  Got: ...

Corrigiendo antes de marcar la spec como completa...
```

---

## Stack de referencia rápida

| Qué             | Cómo                          |
| --------------- | ----------------------------- |
| Estado UI       | Riverpod (`flutter_riverpod`) |
| Modelos         | Freezed                       |
| Navegación      | GoRouter                      |
| Tests mock      | Mocktail                      |
| Tests Firestore | fake_cloud_firestore          |
| Tests e2e       | Patrol                        |
| i18n            | ARB + flutter_localizations   |
| Backend         | Cloud Functions TypeScript    |

---

## Idiomas soportados

| Código | Idioma  | Archivo ARB  |
| ------ | ------- | ------------ |
| `es`   | Español | `app_es.arb` |
| `en`   | English | `app_en.arb` |
| `ro`   | Română  | `app_ro.arb` |

Más idiomas se añaden creando el ARB y añadiendo el documento en la colección `languages` de Firestore.
