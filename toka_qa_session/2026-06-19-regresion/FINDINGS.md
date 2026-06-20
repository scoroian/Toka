# Hallazgos QA — sesión 2026-06-19 (regresión exhaustiva, 2 dispositivos)

**Build:** `app-debug.apk` recompilado HOY del working tree (Flutter Windows), instalado en emulador `emulator-5554` (1080x2400, GMT, tema claro) y MI_9 `43340fd2` (1080x2340, Madrid, tema oscuro). Contra producción `toka-dd241`.
**Cuentas:** Luna `toka.sync.luna@tokatest.dev` (uid Q7Cg…), Sol `toka.sync.sol@tokatest.dev` (uid WAqQ…). Hogar de trabajo: **Hogar Real QA** `mAJXlAhwRV1kdy4O05hG` (owner=Sol, free).
**Leyenda:** 🔴 crítico · 🟠 medio · 🟡 menor · ⚠️ observación · ✅ verificado OK.

---

## ✅ FALSO POSITIVO (era candidato 🔴) — "Unirse por código" NO es un bug; fallaba por mi método de input

**Conclusión:** el join por código **funciona correctamente** en ambos dispositivos. El fallo que veía era un **artefacto del testing**: `adb shell input text "<código>"` (escritura de golpe vía Gboard) corrompe el valor del campo de código (que tiene un input formatter de mayúsculas/longitud/IME-composing), de forma que el cliente envía un código que la función no puede resolver → error → cliente muestra el genérico "Algo salió mal".

**Prueba decisiva (matriz):**
| Cuenta | Dispositivo | Método input | Resultado |
|---|---|---|---|
| Luna (rejoin) | emulador | `adb input text` | ❌ "Algo salió mal" (5/5) |
| Luna (rejoin) | Node REST | — | ✅ une |
| tres (nuevo)  | MI_9 físico | `type.sh` char-a-char | ✅ une |
| tres (rejoin) | MI_9 físico | `type.sh` char-a-char | ✅ une |
| **Luna (rejoin)** | **emulador** | **`type.sh` char-a-char** | **✅ une** |

La última fila es la que cierra el caso: **mismo emulador, misma cuenta, solo cambia el método de input → con char-a-char el join funciona.** App Check (`app:INVALID` permitido en MI_9 físico también), rate-limit, índices, backend y rejoin-vs-new quedaron todos descartados por el camino.

**Lección de tooling (corregir memoria):** NO usar `adb input text` para el campo de código de invitación (ni el emulador con Gboard lo tolera, pese a lo que decía la nota previa). Usar **siempre `type.sh` char-a-char** para campos con input formatter.

**Mejora real (menor) que sí merece la pena:** `homes_repository_impl.dart:66 joinHome()` sólo mapea `not-found`/`deadline-exceeded`; cualquier otro código de error cae en `error_generic`. Si un día el backend devuelve `failed-precondition` (límite free) o `resource-exhausted` (rate-limit), el usuario verá "Algo salió mal" en vez del motivo. Conviene mapear esos códigos a mensajes específicos. (Ver ⚠️-b.)

---

## 🟠-2 — "Abandonar hogar" ofrece "Transferir propiedad" a un NO-owner (caché stale)

**Síntoma:** Luna es `role=admin` (owner real = Sol), pero al pulsar **Ajustes → Abandonar hogar** el cliente muestra el diálogo **"Transferir propiedad del hogar / selecciona quién será el nuevo propietario"** (flujo exclusivo del owner), reproducible incluso tras reiniciar la app.

**Causa raíz (confirmada):** `settings_screen.dart:283` deriva `isOwner = members.any(m => m.uid==uid && m.role==owner)` leyendo `watchHomeMembers(homeId).first`. El `.first` de un stream de Firestore devuelve el primer snapshot, servido desde la **caché local persistente** (`isFromCache=true`) si ningún listener la refrescó antes — y esa caché tenía a Luna como owner (lo fue hasta el 18-jun, cuando transfirió el hogar a Sol). 
**Prueba:** la pantalla Miembros muestra correctamente Luna=Admin/Sol=Propietario (listener vivo, datos del servidor). Tras VISITAR Miembros (refresca la caché), reintentar "Abandonar hogar" muestra el diálogo CORRECTO ("¿Abandonar hogar?", flujo simple). → el bug depende de si la caché de `members` fue refrescada.
**Impacto:** UX confuso para un ex-owner re-unido como admin/member. El backend protege (leaveHome valida `role==owner`; transferOwnership valida caller=owner), así que el daño se limita a un diálogo incorrecto. **Fix sugerido:** derivar `isOwner` de `home.ownerUid` (fresco) o forzar lectura de servidor / esperar `!metadata.isFromCache`.

---

## ⚠️ Observaciones menores
- **⚠️-a:** la pantalla "Sin hogar" (y el primer frame de Hoy) muestra **"Cargando…"** como título del AppBar de forma persistente, no sólo transitoria.
- **⚠️-b:** `error_generic` ("Algo salió mal") aplasta todos los errores de join no mapeados (ver 🔴-1) — mensajes específicos del backend (límite free, expirado, rate-limit) no llegan al usuario.
- **⚠️-c:** los diálogos de acción de miembro tienen **layouts de botones inconsistentes**: en "Quitar administrador" Cancelar aparece arriba-derecha y el botón de acción debajo (escalonados); en "Expulsar" Cancelar a la izquierda y acción a la derecha (estándar). Conviene unificar.

## ✅ Área MIEMBROS
- ✅ **Lista** (MI_9/emulador): tarjeta "Equilibrio del hogar 25% · Desequilibrado" con barra, Luna (Admin, Cumplimiento 50%), Sol (Propietario, 0%), FAB Invitar. Stats actualizadas en vivo tras completar/pasar.
- ✅ **Perfil de miembro** (Sol→Luna): avatar, rol, **teléfono 600111222 visible** (fix §4 phoneVisibility), stats (1 completada / racha 1 / 0.0 media), "Puntos fuertes: sin valoraciones", acciones "Quitar administrador" / "Expulsar del hogar".
- ✅ **Fix §1** (diálogos de miembro responden): "Quitar administrador" y "Expulsar del hogar" → diálogo aparece, **Cancelar reacciona y cierra** (antes los botones no respondían). Verificado en ambos.
- ✅ **Invitar → Compartir código**: código (K3QPQD) + QR + expiración + Copiar/Regenerar. **Invitar por email**: sheet con campo email + "Enviar invitación".

## ✅ Área PERFIL + AJUSTES + i18n + TEMA + NOTIFICACIONES
- ✅ **Editar perfil**: pre-rellena avatar/Apodo (Luna)/Bio (contador 11/160)/Teléfono/toggle visibilidad. Guarda y vuelve a Ajustes.
- ✅ **Toggle "Mostrar teléfono"**: apagarlo → el teléfono de Luna **desaparece** del perfil visto por Sol (MI_9), sincronizado. Complementa fix §4 (dirección OFF→oculto).
- ✅ **Stats de perfil**: tareas completadas, racha, puntuación media, puntos fuertes.
- ✅ **Cambiar contraseña**: envía email de restablecimiento (SnackBar "Te hemos enviado un correo…"). ⚠️-d: lo envía directo sin diálogo de confirmación ni formulario in-app.
- ✅ **Apariencia/tema**: Claro/Oscuro/Sistema cambian en vivo (probado Oscuro). Skin "Clásico" con preview.
- ✅ **Idioma (i18n)**: lista desde Firestore `languages` (🇪🇸/🇬🇧/🇷🇴). es→en→ro→es cambian TODA la UI en vivo.
- ✅ **Notificaciones**: toggle "Avisar al vencer"; "Avisar antes de vencer" y "Resumen diario" con gating **Solo Premium**; 6 botones de prueba. Disparada "Tarea asignada" → notificación real (channel `toka_assignment`, "Ana te asignó una tarea · Limpiar el baño · viernes 18:00").
- ✅ **Acerca de**: versión 1.0.0 (1), Términos de uso, Política de privacidad.

## ✅ Área SUSCRIPCIÓN / PREMIUM (forzando estados con qa_premium.js)
- ✅ **Fix §5** (refresco en vivo, sin reiniciar): al pasar a `active`, tile Ajustes → "Plan Premium"; ad desaparece.
- ✅ **Fix §9** (navegación): tile "Plan Premium" → "Tu suscripción" (Premium activo, renovación 19 jul 2026, Pagador: Sol, Gestionar facturación / Cancelar renovación).
- ✅ **Banners de estado en vivo** (todos refrescan sin reiniciar):
  - `cancelledPendingEnd`: "Premium hasta el 29 junio 2026 · No se renovará automáticamente · Pagador: Sol · Reactivar renovación".
  - `expiredFree`: "Premium expirado el 18 junio 2026 · Reactivar Premium".
  - `rescue`: "Tu Premium vence en 1 días — renueva… · Premium hasta el 21 junio 2026 · Renovar".
  - `restorable`: "Puedes restaurar tu Premium hasta el 9 julio 2026 (19 días) · Restaurar Premium".
- ✅ **Paywall**: comparación Gratuito/Premium (10 miembros, distribución inteligente, modo vacaciones, valoraciones privadas, historial 90 días, sin publicidad), Anual 29,99€ (ahorra 17,89€) / Mensual 3,99€, "Restaurar compras", términos.
- **⚠️-e:** pluralización: el banner rescue muestra **"vence en 1 días"** (debería ser "1 día").
- ⏳ Compra real / downgrade planner / rescate flow: no disparados (flujo externo Play Store); validados en sesión previa.

## ✅ Área HISTORIAL
- ✅ **Lista** de eventos con iconos: "Luna completó 🏠 Sacar basura" (★ tras valorar), "Luna→Sol 🏠 Limpiar cocina — pase de turno" (icono ↔).
- ✅ **Filtros** Todos/Completadas/Pases/Vencidas (probado Pases → solo el pase).
- ✅ **Valorar** (premium, desde Sol→Luna): botón "Valorar" en la tarjeta → sheet "Valorar tarea" (slider 0-10, probado 8.5) → "Enviar valoración".
- ✅ **§11** (botón→estrella en vivo): tras valorar, el botón "Valorar" pasa a **estrella dorada** sin reiniciar.
- ✅ **Detalle de valoración**: "Valoración de Sol · 8.5 / 10" (escala 0-10 legible). El usuario no se autovalora (Luna no ve "Valorar" en su propia completación).

## ✅ Área AUTH + ONBOARDING + HOGARES + DESTRUCTIVO
- ✅ **Login**: pantalla completa (Google, email/contraseña con ojo, Iniciar sesión, ¿Olvidaste?, Crear cuenta, selector idioma). Login exitoso end-to-end (tres y Sol) → home/onboarding.
- ✅ **Validación login**: email mal formado → "Introduce un email válido".
- ✅ **Logout**: diálogo "¿Cerrar sesión?" → confirma → login.
- ✅ **🔴-6 (regresión OK)**: "Recuperar contraseña" → email + "Enviar enlace" → **muestra la confirmación** "Te hemos enviado un correo para restablecer tu contraseña" (el bug de rebuild del 18-jun está arreglado).
- ✅ **Onboarding**: welcome ("Bienvenido a Toka · Empezar"); pasos idioma/perfil/elección-hogar (cubiertos por regresión 18 + unit tests). ⚠️-f: el botón "Empezar" del welcome **no respondió a `adb input tap`** en el MI_9 (probable artefacto de hit-testing adb sobre el `FilledButton` dentro del `PageView`; el código es correcto `onPressed: vm.nextStep` y el 18-jun el onboarding funcionó manual). No reproducido como bug de producto.
- ✅ **Selector de hogares**: "Cambiar hogar" + hogar actual con rol + "Añadir hogar". Caso 2-hogares (flecha) cubierto por unit test `home_selector_widget_test`.
- ✅ **Ajustes del hogar**: avatar, nombre editable, **estado premium en vivo** ("Premium · Vence el 19/7/2026"), Gestionar miembros, Administradores (2), Abandonar hogar.
- ✅ **Abandonar hogar** (leaveHome, hoy): Luna admin → "¿Abandonar hogar?" → sale → "Sin hogar" + backend `left` + sync. (Caso A.)
- ✅ **Downgrade** (active→free, hoy): el hogar vuelve a `free` en vivo (tile "Plan gratuito" reaparece, ad vuelve).
- ⏭️ **Eliminar hogar (Caso C) / Eliminar cuenta (§3) / Transferir propiedad (Caso B)**: validados E2E en la sesión del 18-jun (sin cambios de código en esas rutas en el build de hoy); no re-ejecutados para preservar el setup.
- ⏭️ Registro (email duplicado) / contraseña incorrecta (rebote 🟠-5): validados en sesión 18; no re-probados.

---

## ✅ Verificado OK durante el setup
- ✅ **Invitar → Compartir código** (MI_9): genera código + QR + expiración + Copiar/Regenerar.
- ✅ **leaveHome desde cliente** (emulador, Luna admin): "¿Abandonar hogar?" → Confirmar → sale, va a "Sin hogar", backend `status=left`. Sync OK.
- ✅ **Pantalla Miembros** (emulador): roles correctos (Luna Admin, Sol Propietario), tarjeta Equilibrio, FAB Invitar.

## ✅ Área TAREAS + HOY (cliente Flutter sano para escrituras/callables)
- ✅ **Crear tarea**: recurrencias completas (Puntual/Cada hora/Diario/Semanal/Mensual día fijo/Mensual Nth/Anual fecha/Anual Nth), selector emoji+icono, título+descripción, hora+zona horaria, asignación múltiple/única, **modo de asignación con gating "Disponible con Premium"** (Distribución inteligente bloqueada en free), **onMiss** (Mantener asignado/Rotar al siguiente), dificultad, **Próximas 3 fechas con rotación correcta**. El título de campo de pantalla completa SÍ se captura (contraste con 🔴-1).
- ✅ **Pantalla Hoy**: contadores (N para hoy / N completadas), agrupación **Hora→Día**, subgrupos **Por hacer/Hechas**, botones ✓ Hecho / ↻ Pasar.
- ✅ **Pasar turno** (fix §2): "El siguiente responsable será: Sol", rota Luna→Sol, sync a ambos. ⚠️ sin cifra de penalización (Luna 0%).
- ✅ **Gating "Hecho"**: botón deshabilitado + SnackBar "El botón 'Hecho' estará activo el HH:MM" hasta vencer.
- ✅ **Completar** (forzando vencimiento): diálogo "¿Confirmas…?" → "Sí, hecha ✓" → contador +1, ocurrencia a **Hechas** ("Completada por Luna a las HH:MM"), tarea horaria reaparece con siguiente ocurrencia.
- ✅ **Detalle**: responsable, próxima vez, dificultad, próximas 5 fechas con rotación.
- ✅ **Editar**: pre-rellena emoji+título+recurrencia. **Congelar/Descongelar**: toggle, mueve a/desde **Congeladas**. **Filtros** Activas/Congeladas. **Swipe-delete**: "¿Eliminar tarea? · no se puede deshacer".
- ✅ **Sync cross-device + zona horaria**: todas las mutaciones se propagan emulador(GMT)↔MI_9(Madrid) con conversión TZ correcta. El dashboard del dispositivo ORIGINADOR refresca con ~6s de lag (no es bug; `updateHomeDashboard` async).
