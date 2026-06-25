# 03 · 🔴 Crítico — `/verify-email` es un dead-end + el email verificado no se exige

> Lee primero `_CONVENCIONES.md`. Marca 🔄 En progreso en `INDICE.md` y ✅ al cerrar.

## Contexto del hallazgo
Dos problemas acoplados:
1. **Dead-end:** tras registrarse, la app fuerza `/verify-email`, una pantalla con un único botón "Reenviar". No hay "Ya verifiqué/Continuar", ni polling de `user.reload()`, ni back. El usuario verifica en su correo, vuelve a la app y **no pasa nada**: la única salida es matar la app.
2. **Sin enforcement:** el router decide solo por `authenticated` + tener hogar; **nunca lee `user.emailVerified`**. Existe `AuthFailure.emailNotVerified` pero no se lanza ni se comprueba. Un usuario con email sin verificar opera con normalidad → la pantalla de verificación es puramente cosmética y aporta fricción sin garantía. Contradice spec-02.

## Evidencia
- `lib/features/auth/presentation/verify_email_screen.dart:17-52` — solo botón "Reenviar"; sin `reload`, sin salida.
- `lib/features/auth/application/verify_email_view_model.dart:55-74` — cooldown de 60 s de reenvío.
- `lib/app.dart:135-160` — `RouterNotifier.redirect`: decide por `authenticated` + hogar; no mira `emailVerified`.
- `lib/features/auth/domain/auth_failure.dart:12` — `emailNotVerified` definido pero sin uso.
- `lib/features/auth/application/auth_provider.dart:96-118` — `register` deja `authenticated` y dispara verificación best-effort.
- Regla de producto: `.worktrees/feature-skin-v2/specs/spec-02-auth.md:20` — "La verificación de email es obligatoria para cuentas email/contraseña antes de poder operar."

## Decisión de producto a confirmar
Antes de implementar, usa `superpowers:brainstorming` para elegir el modelo: **(A) enforcement estricto** (no operar sin verificar) o **(B) verificación diferida** ("verificar más tarde" con recordatorio no bloqueante). La spec pide (A); valora el coste de fricción. Deja la decisión registrada en el commit.

## Criterios de aceptación
- [ ] La pantalla `/verify-email` tiene **salida**: botón "Ya verifiqué / Continuar" que hace `user.reload()` y reevalúa el estado, y un "Volver" funcional. Opcional: polling suave mientras la pantalla está visible.
- [ ] El router reacciona a la verificación (al volver del correo, la app avanza sin reinicio manual).
- [ ] Según la decisión de producto: el acceso a operar respeta `emailVerified` (modelo A) o muestra recordatorio no bloqueante (modelo B). Coherente entre router y UI.
- [ ] Strings localizadas (es/en/ro).

## Pruebas obligatorias
### Unit / Widget
- Test del view model: `reload()` que pasa a verificado → estado avanza; cooldown de reenvío respetado.
- Widget test de la pantalla: botón "Continuar" presente; sin verificar muestra el estado correcto; con verificado avanza.
- Test del redirect del router: usuario `authenticated` no verificado → ruta esperada según modelo elegido.

### Verificación en dispositivo (Firebase real)
1. Registra una cuenta nueva por email en MI_9 (sin verificar). Comprueba que **no** quedas atrapado: hay salida y "Continuar".
2. Verifica el email desde el enlace real (Firebase Auth real) y vuelve a la app → debe avanzar sin matar la app. Captura antes/después.
3. Modelo A: confirma que sin verificar no puedes crear hogar/operar; con verificar sí. Modelo B: confirma el recordatorio no bloqueante.
4. Caso sin red al pulsar "Continuar" → mensaje claro, sin colgarse.

## Al terminar
Actualiza `INDICE.md` (✅ + fecha + nota: modelo A o B elegido). Lista archivos y capturas.
