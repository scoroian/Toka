# Privacidad: borrado de cuenta y retención de datos (GDPR)

Cumplimiento del **derecho al olvido (Art. 17)**, **acceso (Art. 15)** y
**portabilidad (Art. 20)**. Referencia del Hallazgo #04 del premortem.

## Borrado de cuenta (Art. 17)

Disparador: el usuario pulsa **Ajustes → Eliminar cuenta**
(`settings_screen.dart`), que llama a `FirebaseAuth.currentUser.delete()`. Eso
activa el trigger `onAuthUserDeleted` (`functions/src/users/index.ts`) →
`cleanupDeletedUser` (`functions/src/users/cleanup_user.ts`). Cubre el borrado
por **cualquier vía** (app, consola Firebase, Admin SDK). Es **idempotente**.

### Qué se BORRA

| Dato | Ubicación | Acción |
|------|-----------|--------|
| Cuenta de autenticación | Firebase Auth | Borrada (origen del trigger) |
| Documento de usuario | `users/{uid}` | Borrado (`recursiveDelete`) |
| Membresías, slotLedger, rateLimits… | `users/{uid}/**` | Borradas (`recursiveDelete`) |
| Teléfono FCM (privado) | `users/{uid}.fcmToken` | Borrado con `users/{uid}` |
| **Teléfono** en snapshots de hogar | `homes/{h}/members/{uid}.phone` | → `null` |
| **Foto (URL)** en snapshots de hogar | `homes/{h}/members/{uid}.photoUrl` | → `null` |
| **Token FCM** residual en snapshot | `homes/{h}/members/{uid}.notificationPrefs.fcmToken` | Borrado (`FieldValue.delete()`) |
| **Foto de perfil** (objeto) | Cloud Storage `users/{uid}/` | Borrado (`bucket.deleteFiles`) |

**Por qué borrar el objeto de Storage es imprescindible:** el `photoUrl`
denormalizado en los snapshots de miembro es una *download URL tokenizada*
(`getDownloadURL()`). Esos tokens **saltan las Storage rules**: cualquier
co-miembro con la URL podía descargar la foto aunque la regla limite la lectura
al propio `uid`. Poner `photoUrl=null` en Firestore no basta; hay que borrar el
objeto, lo que invalida la URL (pasa a 404) = revocación efectiva del token.

### Qué se CONSERVA (y por qué) — pseudonimización

El documento `homes/{h}/members/{uid}` **no se borra**: se marca
`status:"left"`, `accountDeleted:true` y se conserva como **snapshot
pseudonimizado**. Se mantienen:

- `uid` (identificador interno, ya desligado de toda cuenta Auth) y `nickname`
  (alias autoelegido).
- Estadísticas agregadas de actividad (`completedCount`, `complianceRate`,
  `averageScore`, etc.) y los `taskEvents`/`reviews` históricos.

**Motivo:** estos datos son necesarios para la **integridad del historial y de
las valoraciones de OTROS miembros** ("X completó", "Y valoró a X"). Borrar el
snapshot dejaría huérfanas las referencias y rompería el historial de terceros.
Se conserva el mínimo (alias + métricas), **sin PII de contacto** (teléfono,
foto, token), equilibrando el derecho al olvido del sujeto con el interés
legítimo de los demás miembros en su propio registro de actividad. El cliente
muestra estos miembros como cuenta eliminada (`accountDeleted:true`).

> Endurecimiento futuro posible (fuera del alcance del #04): anonimizar también
> el `nickname` a un marcador genérico. Se descartó para no degradar el
> historial de terceros; documentado como decisión consciente.

## Exportación de datos (Art. 15 acceso / Art. 20 portabilidad)

Callable `exportUserData` (`functions/src/users/export_user_data.ts`), accesible
desde **Ajustes → Privacidad → Exportar mis datos**. Requiere autenticación y
exporta **solo los datos del propio usuario** (nunca de terceros). No escribe
nada. Devuelve un JSON (`schemaVersion`, `exportedAt`) con:

- `profile` — `users/{uid}` completo (incl. teléfono, locale, token: son del
  propio sujeto).
- `memberships` — `users/{uid}/memberships/*`.
- `slotLedger` — `users/{uid}/slotLedger/*`.
- `homes[]` — por cada hogar: nombre + su propio doc de miembro (rol/estado/stats).
- `reviewsAuthored[]` — reseñas que **escribió** (`collectionGroup('reviews')`
  filtrando por `reviewerUid`).

Los `Timestamp` se serializan a ISO-8601. El cliente escribe el JSON a un
archivo temporal y abre el *share sheet* (`share_plus`) para que el usuario lo
guarde/envíe.

**Fuera de alcance (decisión de producto):** las reseñas *recibidas* (notas que
otros escribieron sobre él) no se incluyen; son ampliables con el mismo
`collectionGroup` filtrando por `performerUid` si se decide ampliar.

## Notas operativas

- **Backfill histórico:** las cuentas borradas *antes* de este cambio pueden
  conservar `phone`/`photoUrl`/foto en Storage. Reutilizar
  `secrets/qa_scrub_member_pii.js` (teléfono/token) y, para fotos huérfanas, un
  barrido de Storage de `users/{uid}/` cuyos `uid` ya no existan en Auth.
- **Índice:** la query `collectionGroup('reviews').where('reviewerUid','==',…)`
  la sirve el índice de campo único automático de Firestore (no requiere índice
  compuesto). Verificar en el primer uso real en producción.
