# 13 · 🟡 Medio — Cancelar Google no es un error; desglosar errores genéricos

> Lee primero `_CONVENCIONES.md`. Marca 🔄 En progreso en `INDICE.md` y ✅ al cerrar.

## Contexto del hallazgo
Cancelar el diálogo de Google (acción normal del usuario) se mapea a `error_generic` → "Algo salió mal. Inténtalo de nuevo." Es una alarma falsa. Lo mismo ocurre con `accountExistsWithDifferentCredential` y `emailNotVerified`, todos colapsados al genérico, perdiendo la oportunidad de un mensaje útil (p. ej. ofrecer iniciar sesión o vincular). Además el spinner de carga bloquea Google/Apple/email a la vez sin indicar cuál acción está en curso.

## Evidencia
- `lib/features/auth/presentation/login_screen.dart:119-131` — `operationCancelled`/`accountExistsWithDifferentCredential`/`emailNotVerified` → `error_generic`.
- `lib/features/auth/presentation/register_screen.dart:66-70` — mismo colapso.
- `lib/features/auth/presentation/login_screen.dart:71,80,98` — `isLoading` global a los tres métodos.
- Repo: `auth_repository_impl.dart:209-225` (mapeo); `:122-172` `linkWith*` existen pero no se usan.

## Objetivo
1. Tratar la **cancelación** del usuario como **no-op silencioso** (sin SnackBar de error).
2. Dar mensaje específico a `email-already-in-use`/`account-exists-with-different-credential` (sugerir "iniciar sesión" o, si se aborda aquí, ofrecer vinculación — ver alcance abajo).
3. (Opcional, esfuerzo bajo) indicar qué método está cargando en vez de bloquear los tres con un spinner global.

## Alcance
- Núcleo de esta tarea: cancelación silenciosa + mensajes específicos. La **vinculación de proveedores** (UI que invoque `linkWith*`) es mayor (spec-02 §5/§9); si no se aborda aquí, deja anotado un sub-hallazgo en el índice para una tarea futura.

## Criterios de aceptación
- [ ] Cancelar Google/Apple no muestra ningún error.
- [ ] `email-already-in-use` ofrece un mensaje accionable ("¿Ya tienes cuenta? Inicia sesión").
- [ ] `account-exists-with-different-credential` da un mensaje claro (o flujo de vinculación si se decide incluirlo).
- [ ] Strings localizadas (es/en/ro).

## Pruebas obligatorias
### Unit / Widget
- Test de mapeo: `operationCancelled` → no produce mensaje de error.
- Widget test: cancelar el flujo social no pinta SnackBar; `email-already-in-use` muestra el copy accionable.

### Verificación en dispositivo (Firebase real)
1. En MI_9, inicia login con Google y **cancela** el diálogo → no debe aparecer ningún error. Captura.
2. Registra un email ya existente → mensaje específico, no genérico. Captura.
3. (Si se incluye spinner por método) verifica que solo el método pulsado muestra carga.

## Al terminar
Actualiza `INDICE.md` (✅ + fecha + nota; anota si dejas la vinculación de proveedores como sub-tarea futura). Lista archivos y capturas.
