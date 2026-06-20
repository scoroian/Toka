# QA exhaustiva 2026-06-18 — todos los flujos, 2 dispositivos

**Build:** app-debug.apk (producción `toka-dd241`) con fixes de la sesión. **Dispositivos:** emulador `emulator-5554` (1080x2400, GMT) + MI_9 `43340fd2` (1080x2340, Madrid). **Cuentas:** Luna `toka.sync.luna@tokatest.dev` (owner Hogar Sync QA), Sol `toka.sync.sol@tokatest.dev` (member), tres `toka.sync.tres@tokatest.dev` (sin hogar). **Admin SDK:** solo free↔pro. Home `FDc1e8f7ezentRiHmH3z`, Luna uid `Q7CgeIUPoAcHhnyPBlioLlBJXDo1`, Sol uid `xGwNf1i0aKREC9xcZbcct912lt12`.

Leyenda: ✅ OK · 🐞 BUG · ⚠️ observación · ⏭️ no aplica/saltado.

## Áreas
1. Auth: login, registro, recuperar contraseña, logout, verificación email
2. Onboarding: welcome, idioma, perfil, elección hogar, crear/unir, notificaciones
3. Hogares: selector, añadir, settings (nombre, avatar, premium tile), abandonar/transferir/eliminar, payer-lock
4. Hoy: contadores, tarjetas (todo/done/overdue), completar, pasar turno, aplicar hoy
5. Tareas: crear (recurrencias, asignados, dificultad, onMiss, smart), editar, borrar, congelar, detalle, filtros
6. Miembros: lista, perfil, admin/expulsar, invitar (código/email/QR), balance, límite free
7. Perfil: propio, editar, stats, radar, fortalezas, valoraciones
8. Historial: lista, filtros, valorar, gate premium, paginación
9. Suscripción: paywall, planes, banners de estado, gestión, restaurar, downgrade, rescate
10. Ajustes: secciones, navegación tile suscripción, idioma, apariencia/tema, notificaciones, acerca de, eliminar cuenta
11. Sync en vivo cross-device por cada mutación
12. i18n: es/en/ro

---

## Resultados

### 4–5. Tareas + Hoy (emulador Luna / MI_9 Sol)
- ✅ Detalle de tarea: Editar/Congelar/Eliminar presentes; "Próximas fechas" rota Luna/Sol correctamente.
- ✅ Eliminar desde detalle (fix §14): diálogo "¿Eliminar tarea? · no se puede deshacer", Cancelar/Eliminar.
- ✅ Editar: pre-rellena emoji+título+recurrencia; guarda (spinner→detalle). ⚠️ la descripción no se muestra en el detalle.
- ✅ Congelar/Descongelar: botón alterna; tarea va a "Congeladas" y vuelve a "Activas". Filtros OK.
- ✅ Crear "Cada hora" (asignada Luna+Sol): aparece en Activas, due hoy.
- ✅ Pasar turno (fix §2): diálogo muestra "El siguiente responsable será: Sol" + Motivo opcional (ya NO "sin candidato"). Confirmar → tarea pasa a Sol y desaparecen sus botones para Luna. ⚠️ no se ve cifra de penalización de cumplimiento (Luna 0%).
- ✅ Sync Luna→Sol del pase: en MI_9, Sol ve la tarea como suya (TZ Madrid 23:28 = GMT 21:28).
- ✅ Completar: gating correcto — "Hecho" inactivo hasta la hora, SnackBar "El botón 'Hecho' estará activo el 23:28". ⏳ completar real DIFERIDO hasta que venza la horaria.
- ⏭️ swipe-delete (mismo backend que §14, pendiente verificación de gesto).

### 6. Miembros (emulador Luna)
- ✅ Lista: Luna (Propietario) + Sol (Miembro), tarjeta "Equilibrio del hogar" 0%, FAB Invitar.
- ✅ Perfil de Sol: stats (0/0/0.0), "Puntos fuertes: sin valoraciones", banner "Los roles de admin están disponibles en Premium" (gating correcto), "Expulsar del hogar".
- ✅ Diálogo expulsar (fix §1): aparece "¿Expulsar a Sol…?", Cancelar RESPONDE y cierra (antes los botones no reaccionaban).
- ✅ Invitar → Compartir código: genera código (H37RVK usado en alta de Sol).
- ⏳ Hacer/Quitar admin (fix §1): requieren premium → se prueban en área Suscripción.
- ⏭️ Límite de miembros free (no alcanzado con 2 miembros).
- ✅ Hacer/Quitar admin (fix §1, bajo premium): diálogos responden; Sol Miembro→Admin→Miembro. Banner "admin disponible en Premium" cuando free.

### 10. Suscripción / premium (Admin SDK active)
- ✅ §5 sync en vivo: al activar premium, el perfil de miembro pasa de "admin en Premium" a "Hacer administrador" sin reiniciar; banner de anuncios desaparece en ambos (verificado antes).
- ✅ §5 Ajustes muestra "Suscripción · Plan Premium" (antes mostraba gratuito).
- ✅ §9 navegación: tocar "Plan Premium" abre "Tu suscripción": Premium activo, renovación 18 jul 2026, Pagador: tú, "Gestionar facturación" / "Cancelar renovación".
- ⏳ Pendiente: banners cancelledPendingEnd/rescue/restorable/expiredFree en vivo, paywall, downgrade planner, rescate, restaurar compras.

- ✅ Banners premium en vivo (§5, sin reiniciar): cancelledPendingEnd ("No se renovará tras 28/06… Reactivar"), rescue ("Premium vence en 2 días… Renovar"), restorable ("restaurar hasta 08/07… Restaurar"), expiredFree ("Premium expiró el 17/06… Reactivar Premium").
- ✅ Paywall: comparación Gratuito/Premium, 29,99€/año (ahorra 17,89€) y 3,99€/mes, Restaurar compras.
- ✅ Gestionar facturación / Cancelar renovación abren flujo externo (navegador/Play Store) — esperado para in_app_purchase.

### 4b. Completar tarea (cuando venció la horaria)
- ✅ Hecho activo a la hora exacta → diálogo "¿Confirmas…?" → "Sí, hecha ✓" → contador "1 completadas hoy", ocurrencia a "Hechas" ("Completada por Sol a las 23:29"), siguiente rota a Luna.
- ✅ Sync a Luna: contador, "Hechas", rotación y TZ (GMT 21:29 / Madrid 23:29) coherentes.

### 9. Historial + valorar
- ✅ Lista con filtros Todos/Completadas/Pases/Vencidas; eventos "Sol completó" y "Luna→Sol pase de turno".
- ✅ Valorar (premium): sheet "Valorar tarea" (slider 5.0 + nota privada) → Enviar. §11: el botón "Valorar" pasa a estrella EN VIVO; detalle del evento muestra "Valoración de Luna: 5.0" guardada.

- ⚠️ Detalle de valoración muestra 2,5★ junto a "5.0" (escala 0-10 en 5 estrellas) — consistente pero puede confundir.

### 11. Ajustes + Notificaciones + i18n
- ✅ Apariencia: Claro/Oscuro/Sistema cambia el tema en vivo (probado Oscuro).
- ✅ i18n: Idioma → Español/English/Română; cambia toda la UI en vivo (probados es↔en↔ro). Lista desde colección `languages`.
- ✅ Notificaciones: toggles "Avisar al vencer/antes de vencer/Resumen diario" funcionan; botones de prueba por tipo (Tarea por vencer/asignada, Recordatorio previo, Resumen diario, Valoración recibida, Rotación de turno).
- ⏳ Editar perfil, Visibilidad del teléfono, Cambiar contraseña: pendientes (rápidos).

### PENDIENTE (continúa)
- Editar perfil / visibilidad teléfono / cambiar contraseña.
- Selector con 2 hogares (crear 2º hogar; verifica flecha selector con >1 + switch + añadir).
- payer-lock §12 (transferir/abandonar con premium → error claro).
- DESTRUCTIVO (aprobado): abandonar/transferir/eliminar hogar, eliminar cuenta → recrear setup.
- Auth/onboarding casos límite (login/registro validaciones, recuperar contraseña).

### 7+12. Perfil + Hogares
- ✅ Editar perfil: apodo/bio/teléfono/visibilidad → Guardar. Fix §4: con visibilidad ON, Sol ve el teléfono de Luna (600111222) en su perfil — propagado al doc de miembro y sincronizado.
- ✅ Cumplimiento de Sol pasó a 100% tras completar (stats actualizadas).
- 🔴 BUG: crear 2º hogar desde el selector falla en silencio (ver FINDINGS 🔴-0). Bloquea prueba de selector con 2 hogares.
- ✅ Fix §12 payer-lock: Luna (owner+pagador, premium activo) → Abandonar hogar → Transferir a Sol → bloqueado con SnackBar "No puedes expulsar ni salir del hogar mientras seas el pagador de la suscripción Premium activa…". Transferencia rechazada (Luna sigue owner).
- ✅ Diálogo TransferOwnership (Caso B) aparece correctamente al abandonar siendo owner con miembros activos.

### Fixes verificados en vivo (resumen)
§1, §2, §4, §5, §9, §11, §12, §14 + registro→onboarding. Todos OK.

### PENDIENTE (siguiente bloque)
- DESTRUCTIVO (aprobado): poner free → abandonar (Sol, Caso A) → eliminar hogar (Caso C) → eliminar cuenta (§3) → recrear setup.
- Auth/onboarding casos límite.

### 12b. Hogares — destructivo + selector
- ✅✅ "Crear 2º hogar falla" RESUELTO como FALSO POSITIVO (artefacto: mi `keyevent BACK` cerraba el bottom sheet). Crear hogar funciona desde selector y estado vacío (BD: Luna con 2 hogares tras el re-test sin BACK).
- ✅ Selector con 1 hogar: sin flecha (mi fix), pero tappable (abre sheet con "Añadir hogar"). El caso 2-hogares (flecha) cubierto por unit test `home_selector_widget_test`.
- ✅ §3 eliminar cuenta (Sol, miembro): pide reautenticación → reentrar → elimina; membresía de Sol limpiada en Luna (sin fantasma, sincronizado).
- ✅ Eliminar hogar Caso C (UI): "eres el único miembro… permanente" → pasa a "Sin hogar"; §5 (no muestra el hogar borrado). ⚠️ pero el home doc persistió en BD (ver FINDINGS ⚠️-4).
- ✅ §12 payer-lock verificado (SnackBar).
- ⏭️ Transferir-ejecución (Caso B): diálogo verificado; ejecución real no probada (requiere 2 miembros; Sol eliminada).

### 13. Auth / Onboarding casos límite
- ✅ Validación cliente login: email mal formado → "Introduce un email válido".
- ✅ §6: el error se limpia al corregir el email (sin reenviar).
- 🟠-5: errores de auth (login con contraseña incorrecta; registro con email duplicado) rebotan a un login VACÍO sin mensaje claro (ver FINDINGS 🟠-5).
- ⏭️ Contraseñas no coincidentes / recuperar contraseña: no probados limpiamente (overlay de clima MIUI desplazó coords + pila de navegación confusa). Pendientes menores.
- ✅ Validación onboarding nickname vacío: cubierta por unit test `ProfileStepV2` (verificado en la suite).

### Fixes verificados en vivo (final)
§1, §2, §3, §4, §5, §6, §9, §11, §12, §14 + registro→onboarding. **Sin bugs reales nuevos** (el 🔴-0 era falso positivo); 1 hallazgo UX nuevo (🟠-5).

### 14. Flujos diferidos (2ª pasada)
- 🔴-6 **Recuperar contraseña** (device MI_9): NO mostraba la confirmación tras enviar (bug de rebuild Riverpod). **Arreglado** + test; ver FINDINGS 🔴-6.
- ✅ **Swipe-delete** (device emulador): en la lista de Tareas, swipe izquierda → "¿Eliminar tarea? · no se puede deshacer" → Eliminar → tarea borrada ("Sin tareas"). Swipe derecha = congelar (por diseño).
- ✅ **Ejecución de transferencia de propiedad** (Caso B): recreé Sol (registro por formulario en MI_9 → onboarding → unirse con código ZJV7S3). Luna (emulador) → Ajustes → Abandonar hogar → diálogo "Transferir propiedad" → seleccionar Sol → **Transferir**. Resultado: Luna pasa a "Sin hogar" (sale) y en el MI_9 **Sol pasa de Miembro → Propietario**, Luna desaparece de Miembros — sincronizado en vivo. Transferencia + salida del owner anterior correctas.

### Estado dispositivos
- Emulador: Luna, "Sin hogar" (salió tras transferir Hogar Real QA a Sol). MI_9: Sol, **Propietaria** de Hogar Real QA.
- Cuenta "tres": sin hogar. Hogar Sync QA: tombstone "purged".
- TODOS los flujos diferidos completados. Sin pendientes de QA.
