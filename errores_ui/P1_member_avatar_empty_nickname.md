# P1 — Avatar "?" y nickname vacío al unirse al hogar

## Bug que corrige
- **Bug #27** — El perfil de detalle del miembro (Member) muestra avatar "?" y nombre vacío, aunque la lista de miembros muestra las iniciales y nombre correctos. La causa raíz es que `homes/index.ts` crea el documento `members/{uid}` con `nickname: ""` hardcodeado en lugar de leer el valor real de `users/{uid}`.

## Causa raíz confirmada

`functions/src/homes/index.ts` contiene al menos dos rutas que crean `members/{uid}` sin leer el nickname:

- **Línea ~174** (ruta de unirse al hogar con código): `nickname: ""`
- **Línea ~262** (ruta de creación del hogar / primer miembro): `nickname: ""`

El trigger `syncMemberProfile` (si existe) debería propagar el nickname, pero puede haber una race condition o puede que no esté implementado.

## Archivos a modificar

| Archivo | Líneas a cambiar |
|---------|-----------------|
| `functions/src/homes/index.ts` | ~174 y ~262 |

## Cambios requeridos

### 1. Leer nickname de `users/{uid}` al crear el doc de miembro

En ambas rutas que crean `members/{uid}`, leer el doc del usuario antes de crear el miembro:

```typescript
// Obtener datos del usuario
const userDoc = await db.doc(`users/${uid}`).get();
const userData = userDoc.data();
const nickname = userData?.nickname ?? userData?.displayName ?? "";
const photoURL = userData?.photoURL ?? null;

// Crear doc del miembro con datos reales
await homeRef.collection('members').doc(uid).set({
  uid,
  nickname,           // ← antes era ""
  photoURL,           // ← asegurar que también se propaga
  role: 'member',
  joinedAt: FieldValue.serverTimestamp(),
  tasksCompleted: 0,
  currentStreak: 0,
  averageScore: 0,
  complianceRate: 100,
});
```

### 2. Implementar o corregir el trigger syncMemberProfile

Si existe un trigger que sincroniza `users/{uid}` → `homes/*/members/{uid}`, verificar que:
- Se ejecuta cuando se actualiza `users/{uid}.nickname`.
- Actualiza TODOS los documentos de miembro en todos los hogares del usuario.

```typescript
export const syncMemberProfile = functions.firestore
  .document('users/{uid}')
  .onUpdate(async (change, context) => {
    const { uid } = context.params;
    const newData = change.after.data();
    
    const nickname = newData.nickname ?? newData.displayName ?? "";
    const photoURL = newData.photoURL ?? null;
    
    // Buscar todos los hogares donde este usuario es miembro
    const memberDocs = await db
      .collectionGroup('members')
      .where('uid', '==', uid)
      .get();
    
    const batch = db.batch();
    for (const doc of memberDocs.docs) {
      batch.update(doc.ref, { nickname, photoURL });
    }
    await batch.commit();
  });
```

### 3. Script de migración

Actualizar los docs `members/{uid}` existentes con nickname vacío:

```typescript
const memberDocs = await db.collectionGroup('members')
  .where('nickname', '==', '')
  .get();

for (const memberDoc of memberDocs.docs) {
  const uid = memberDoc.data().uid;
  const userDoc = await db.doc(`users/${uid}`).get();
  const userData = userDoc.data();
  const nickname = userData?.nickname ?? userData?.displayName ?? "";
  
  if (nickname) {
    await memberDoc.ref.update({ nickname });
  }
}
```

## Diferencia entre stream caché y lectura de servidor

La lista de miembros (`homeMembersProvider` — stream en tiempo real) puede mostrar "M" y "Member" si hubo un momento en que el nickname se propagó correctamente al stream. El perfil de detalle (`fetchMember` — Future, lectura directa de servidor) obtiene el valor actual vacío del doc `members/{uid}`. Esto confirma que el doc en Firestore tiene `nickname: ""` pero el stream puede haber cacheado un valor antiguo.

## Criterios de aceptación

- [ ] Al unirse un usuario nuevo con código, su doc `members/{uid}` se crea con el nickname real.
- [ ] El perfil de detalle del miembro muestra las iniciales/nombre correctos, no "?".
- [ ] La lista de miembros y el perfil de detalle muestran el mismo nombre.
- [ ] Al actualizar el nickname en `users/{uid}`, el trigger actualiza `members/{uid}` en todos los hogares.

## Tests requeridos

- Test de integración: usuario se une al hogar → leer `members/{uid}` → `nickname` no es vacío.
- Test de integración: actualizar `users/{uid}.nickname` → leer `members/{uid}` → nickname propagado.
- Test de widget: `MemberDetailScreen` con nickname vacío → no muestra "?", muestra iniciales del email como fallback.
