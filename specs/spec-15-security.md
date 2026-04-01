# Spec-15: Security Rules y App Check

**Dependencias previas:** Spec-00 → Spec-14  
**Oleada:** Transversal — validar antes de producción

---

## Objetivo

Validar y refinar las Security Rules de Firestore y Storage, configurar App Check, y ejecutar una batería completa de tests de seguridad.

---

## Reglas a validar

El archivo `firestore.rules` ya está definido en la raíz del proyecto. Esta spec se encarga de:

1. Escribir **tests de Security Rules** usando `@firebase/rules-unit-testing`.
2. Verificar cada caso de acceso: autorizado y no autorizado.
3. Configurar App Check en la app Flutter (DeviceCheck en iOS, Play Integrity en Android).
4. Verificar que en producción, las llamadas sin App Check son rechazadas.

---

## Tests de Security Rules (JavaScript/TypeScript)

Crear en `functions/test/rules/`:

### `test/rules/languages.test.ts`
```typescript
// languages/{code}: lectura pública, escritura denegada
it('permite leer idiomas sin autenticación', ...);
it('deniega escribir idiomas sin autenticación', ...);
it('deniega escribir idiomas con autenticación', ...);
```

### `test/rules/users.test.ts`
```typescript
it('usuario puede leer su propio perfil', ...);
it('usuario NO puede leer perfil de otro usuario', ...);
it('usuario puede actualizar su perfil', ...);
it('usuario NO puede modificar baseHomeSlots', ...);
it('usuario NO puede modificar lifetimeUnlockedHomeSlots', ...);
it('usuario puede leer sus membresías', ...);
it('usuario NO puede leer membresías de otro', ...);
```

### `test/rules/homes.test.ts`
```typescript
it('miembro activo puede leer el hogar', ...);
it('miembro congelado puede leer el hogar', ...);
it('NO miembro NO puede leer el hogar', ...);
it('admin puede crear tareas', ...);
it('miembro normal NO puede crear tareas', ...);
it('miembro puede leer tareas del hogar', ...);
it('usuario externo NO puede leer tareas', ...);
```

### `test/rules/reviews.test.ts`
```typescript
it('autor de review puede leer su review', ...);
it('evaluado puede leer la review sobre él', ...);
it('tercero miembro del hogar NO puede leer la nota textual', ...);
it('usuario externo NO puede leer ninguna review', ...);
```

---

## App Check

En `main_prod.dart`:
```dart
await FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.playIntegrity,
  appleProvider: AppleProvider.deviceCheck,
);
```

En `main_dev.dart`:
```dart
await FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.debug,
  appleProvider: AppleProvider.debug,
);
```

---

## Pruebas manuales requeridas al terminar esta spec

1. **Cross-hogar:** Con dos cuentas en hogares distintos, intentar leer directamente el documento `homes/{otroHomeId}` vía la SDK → debe ser denegado.
2. **Nota privada:** Con cuenta C (mismo hogar), intentar leer `taskEvents/{id}/reviews/{uid_A}` directamente → denegado.
3. **App Check debug:** En modo dev, verificar que las llamadas a Firestore funcionan con el token de debug.
4. **Storage:** Intentar subir una foto a `users/{uid_ajeno}/` → denegado. Subir a `users/{propio_uid}/` → permitido.
5. **Tamaño de foto:** Subir un archivo de 6MB → denegado por las rules de Storage.
