# 22 · 🟡 Medio — Vinculación de proveedores duplicados (Google/Apple/email)

> Lee primero `_CONVENCIONES.md`. Marca 🔄 En progreso en `INDICE.md` y ✅ al cerrar. (Sub-tarea derivada del prompt **13**.)

## Contexto del hallazgo
Cuando el usuario intenta entrar con un proveedor distinto al que ya tiene asociado al email, Firebase devuelve `account-exists-with-different-credential`. Hoy el repo mapea ese error con `providers: []` (lista siempre vacía) y la UI lo colapsa a "Algo salió mal". **No hay diálogo de vinculación**, pese a que los métodos `linkWith*` ya existen en el repositorio sin usarse. La spec-02 exige ofrecer vincular, y también una "gestión de proveedores en perfil" (ver proveedores, vincular, cambiar contraseña) que no está conectada.

## Evidencia
- `lib/features/auth/data/auth_repository_impl.dart:218-222` — mapea a `accountExistsWithDifferentCredential` con `providers: []`.
- `lib/features/auth/data/auth_repository_impl.dart:122-172` — `linkWithGoogle/Apple/EmailPassword` implementados, sin invocar.
- `lib/features/auth/presentation/login_screen.dart:127` — colapsa a `error_generic`.
- Spec: `.worktrees/feature-skin-v2/specs/spec-02-auth.md:18-19,150-156` (vinculación) y §9 (gestión de proveedores en perfil).

## Objetivo
1. Al detectar `account-exists-with-different-credential`, recuperar los proveedores existentes del email y ofrecer un **diálogo de vinculación** que guíe a iniciar con el proveedor correcto y vincular el nuevo.
2. Añadir en **perfil** una sección de gestión de proveedores: ver vinculados, vincular uno nuevo, cambiar contraseña.

## Decisión de producto a confirmar
Usa `superpowers:brainstorming` para el flujo de vinculación (orden de pasos, qué proveedor pedir primero, manejo de errores) y el alcance de la gestión en perfil.

## Criterios de aceptación
- [ ] `account-exists-with-different-credential` ya no muestra "Algo salió mal": ofrece vincular con un flujo claro.
- [ ] La lista de proveedores del email se obtiene realmente (no `[]`).
- [ ] Perfil permite ver proveedores vinculados, vincular otro y cambiar contraseña.
- [ ] Strings localizadas (es/en/ro). Errores de vinculación legibles.

## Pruebas obligatorias
### Unit / Widget
- Test de mapeo: el error trae los proveedores reales.
- Widget test del diálogo de vinculación (aparece, guía, vincula) y de la sección de perfil.

### Verificación en dispositivo (Firebase real)
1. Crea una cuenta con email/contraseña; luego intenta entrar con Google del mismo email → debe aparecer el flujo de vinculación, no un error genérico. Captura.
2. Completa la vinculación y verifica que después puedes entrar con ambos métodos. Captura.
3. En perfil, comprueba la lista de proveedores y "cambiar contraseña". Captura.

## Dependencias
- Cierra el sub-hallazgo dejado abierto en **13**.

## Al terminar
Actualiza `INDICE.md` (✅ + fecha + nota). Lista archivos y capturas.
