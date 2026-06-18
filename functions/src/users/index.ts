// functions/src/users/index.ts
//
// Trigger de borrado de cuenta. Usa el trigger gen-1 `auth.user().onDelete`
// (la API gen-2 equivalente, blocking functions `beforeUserDeleted`, exige
// Identity Platform/GCIP; el onDelete clásico funciona sobre Firebase Auth a
// secas). Es el patrón canónico de la extensión oficial "Delete User Data".
//
// Cubre el borrado por CUALQUIER vía (app vía currentUser.delete(), consola
// Firebase, Admin SDK). La limpieza es idempotente (ver cleanup_user.ts).

import * as functionsV1 from "firebase-functions/v1";
import { cleanupDeletedUser } from "./cleanup_user";

export const onAuthUserDeleted = functionsV1.auth
  .user()
  .onDelete(async (user) => {
    await cleanupDeletedUser(user.uid);
  });
