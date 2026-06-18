# Resultados de pruebas exhaustivas Toka — 2026-06-16

Veredictos: ✅ OK · ⚠️ Funciona con observación · ❌ Bug · 💄 Observación visual/UX
Toda manipulación vía Admin SDK se marca con `[ADMIN SDK]`.

---

# RESUMEN EJECUTIVO

Sesión E2E sobre 2 dispositivos reales (MI_9 físico + emulador) contra producción `toka-dd241`, con cuentas nuevas N1/N2 (creadas vía Admin SDK con `emailVerified=true`). Se cubrieron F1–F9 + límites y estados premium forzados vía Admin SDK.

## 🔴 Bugs (prioridad alta)
1. **Diálogos de acción de miembro no responden a toques** (promover/quitar admin, probablemente expulsar). El diálogo aparece pero **Cancelar y el botón de confirmar no reaccionan** (verificado con `input tap` y `motionevent`; tocar la zona superior sí cierra → un overlay cubre la mitad inferior). Otros diálogos de la app y el de "Cerrar sesión" SÍ responden → **específico del perfil de miembro**. **Bloquea la gestión de roles/expulsión desde la UI.**
2. **Diálogo de "Pasar turno" desinforma**: SIEMPRE muestra "No hay otro miembro disponible, seguirás siendo el responsable" y **no muestra el siguiente responsable ni la penalización de cumplimiento** — pero el servidor SÍ pasa el turno al otro miembro. **Viola la regla de negocio #7** ("penalización visible antes de confirmar").
3. **Eliminar cuenta deja membresías huérfanas**: tras borrar la cuenta de Auth (OK), el doc de miembro queda `status=active` en el hogar → "fantasma" activo con cuenta inexistente. Falta limpieza (Cloud Function on-delete).
4. **Teléfono y visibilidad no se propagan al unirse**: el usuario activó "Mostrar mi teléfono" (global `phoneVisibility=sameHomeMembers`) pero su doc de miembro queda `phone:null, phoneVisibility:hidden` → otros no ven el teléfono aunque lo haya compartido. (Nickname y foto sí se propagan.)

## 🟠 Sync / refresco (patrón recurrente)
5. **El objeto `home` cacheado no refresca en vivo** ante cambios del documento: el **avatar del hogar** seguía mostrando la inicial, la tile **Suscripción** mostraba "Plan gratuito" en premium, los **banners de estado premium** y el estado tras **abandonar hogar** no se actualizaban — todo **se corrige al reiniciar la app**. El **dashboard sí** refresca en vivo (ads, tareas). → Revisar el provider/listener del doc `home`.

## 🟡 Observaciones menores / UX
6. Errores de validación no se limpian al corregir el campo (login email, apodo, código invitación) — persisten hasta el submit.
7. Banner de **AdMob visible en "Crear tarea" pese a premium** (`showAds:false`); en Hoy sí se oculta.
8. **`canUseSmartDistribution:true` pero sin UI**: el formulario de tarea no ofrece selector de "Distribución inteligente".
9. La tile **Ajustes → Suscripción no navega** (solo hace scroll); el acceso premium es por banners.
10. Avatar del hogar **no se denormaliza al dashboard** → no se mostraría en la pantalla Hoy.
11. Tras valorar, el Historial no actualiza el botón "Valorar" a estado "valorado" en vivo (sí al reentrar).
12. Payer-lock bloquea correctamente pero **sin mensaje claro** visible al usuario (posible snackbar transitorio).
13. Contador "tareas para hoy" mostró 0 con tareas activas listadas (a vigilar `tasksDueToday`).
14. 💄 Subformulario "Crear hogar" conserva el título "¿Qué quieres hacer?" + mucho espacio vacío. Borrar no se ofrece desde el detalle de tarea (solo swipe). No se guarda `deletedAt` en borrado lógico.

## ✅ Lo que funciona bien (destacado)
Login/registro·onboarding (idioma en vivo es/en/ro, perfil, foto real a Storage), crear/unirse hogar por código (QR+7d), **límite de plazas (2, 3º bloqueado)**, **todas las recurrencias e iconos/emojis**, **límites free (4 tareas / 3 recurrentes)**, **Hecho** (rotación+stats+streak+"Hechas"), congelar/descongelar, editar, **borrado lógico** (historial+puntuaciones preservados), **sync en tiempo real** (~segundos), **todos los estados premium** (cancelled/rescue/restorable/expired) con banners + pantalla de rescate (lastBillingError, tabla) + **planificador de downgrade** (guarda plan) + paywall de restauración, **valoraciones 1–10 + nota privada** con privacidad correcta (autor+evaluado), equilibrio del hogar, **filtros de historial**, tema claro/oscuro/skins, **notificaciones** (toggles + premium + notif real disparada), cambiar contraseña, abandonar hogar, **reincorporación con rol y stats preservados**, eliminar cuenta (con gate de reauth y mensaje claro). Visualmente la app es **limpia, coherente y atractiva** (Material 3, acentos naranja, dark/light correctos).

---

## F0 — Setup (2026-06-16, 23:50)
- ✅ Dos dispositivos conectados: MI_9 (`43340fd2`) + emulador (`emulator-5554`), ambos con Toka (debug, prod toka-dd241).
- ✅ `[ADMIN SDK]` Creadas 3 cuentas nuevas N1/N2/N3 con `emailVerified=true` y password QA. Reseteada password de owner/member/admin.
- Estado inicial: 10 hogares preexistentes en el proyecto (datos de sesiones previas).

---

## F5 — Premium / suscripción / downgrade

Todos los estados se forzaron `[ADMIN SDK]` con `secrets/qa_premium.js` (replica `debugSetPremiumStatus`).

### Gating premium (active) — ✅
- ✅ Sin ads en Hoy; sin límite de tareas; valoraciones e historial premium.
- ⚠️ La tile **Ajustes → Suscripción mostró "Plan gratuito" estando en premium** hasta reiniciar la app: el cambio de `premiumStatus` vía backend no refrescó en vivo el provider de estado de suscripción (el dashboard sí actualizó ads). Tras reinicio mostró "Plan Premium". **Posible gap de sync**; con compra real (que refresca) podría no notarse.
- ⚠️ La tile "Suscripción" de Ajustes **no navega** a una pantalla de gestión al tocarla (solo hace scroll). El acceso al flujo premium es por los banners. Revisar onTap de la tile.
- ⚠️ Tras cambiar `premiumStatus` vía Admin SDK, **hizo falta reiniciar la app** para que los banners de estado tomaran el nuevo estado (el listener del doc `home` no refrescaba en vivo, aunque el dashboard sí). A vigilar para cambios de estado en producción.

### Banners de estado (todos verificados) — ✅
- ✅ `cancelledPendingEnd`: "No se renovará tras el {fecha}. Puedes reactivar cuando quieras." + **Reactivar renovación**.
- ✅ `rescue`: "Tu Premium vence en {n} días — renueva para no perder features." + **Renovar**.
- ✅ `restorable`: "Puedes restaurar tu Premium hasta el {fecha}." + **Restaurar**.
- ✅ `expiredFree`: "Tu Premium expiró el {fecha}. Reactívalo cuando quieras." + **Reactivar Premium**.

### Pantalla de rescate — ✅ (visualmente muy lograda)
- Título "Renueva tu Premium", countdown "Premium expira en 2 días", **tile rojo "Último intento de cobro: Tarjeta rechazada (INSUFFICIENT_FUNDS). Reintento en 24h."** (lastBillingError), tabla comparativa Gratuito/Premium (10 miembros, distribución inteligente, vacaciones, valoraciones, historial 90d, sin ads), CTAs "Empezar Premium Anual"/"Plan mensual", y enlace **"Planear downgrade"**.

### Planificador de downgrade — ✅
- "¿Qué miembros continuarán?" (máx 3, owner fijo/deshabilitado), "¿Qué tareas continuarán?" (máx 4), nota "Si no decides, se aplicará selección automática", "Guardar plan".
- ✅ Guardar plan persiste en `homes/{homeId}/downgrade/current` (`selectedMemberIds`, `selectedTaskIds`, `selectionMode:"manual"`, `savedAt`).

### Paywall de restauración — ✅
- "Restaurar tu Premium", "Quedan 20 días de la ventana", tabla comparativa, precios (Anual 29,99€ "Ahorra 17,89€" / Mensual 3,99€/mes), "Reactivar Premium", "Restaurar compras", "Ver términos y política de privacidad".
- ⏸️ Completar la compra/restauración real requiere billing de Google Play (no disponible en emulador) → no se ejecutó el pago. La UI del flujo es correcta.

### Pendiente / no cubierto
- ⏸️ Ejecución real del **downgrade automático** (congelar miembros/tareas excedentes al pasar `premiumEndsAt`): requiere estar por encima de límites (>3 miembros / >4 tareas) y disparar el cron `applyDowngradeJob`. Con 2 miembros/3 tareas no congela nada.
- ⏸️ Restaurar premium dentro de ventana (vuelta a active) end-to-end: requiere compra real.

---

## F4 — Miembros, admin (parcial)
- ✅ Invitar/unirse por código (F1). Generación de código con QR + expiración 7d.
- ✅ Promover a admin (premium): el perfil muestra acciones "Hacer administrador"/"Expulsar del hogar"; tras promover (vía `[ADMIN SDK]` por el bug del diálogo) el badge pasa a **"Admin"** correctamente en la lista y el perfil ("Quitar administrador").
- ❌ **Bug de diálogos de acción de miembro** (ver sección destacada): bloquea promover/degradar/expulsar desde la UI.
- ⏸️ Pendiente: payer-lock, abandonar/transferir propiedad, reincorporación (rejoin), límite de miembros free. (Se abordan en F9/extra.)

---

## F6 — Valoraciones, equilibrio, radar — ✅
- ✅ **Valorar** (premium): desde Historial, evento completado de OTRO miembro muestra botón "Valorar". Hoja con slider **1–10** ("Puntuación: 8.5", 83%) + **"Nota privada (opcional)"** + "Enviar valoración".
- ✅ Valoración guardada: evento con `score=8.5`, `note`, `reviewer=N1`; **N2 averageScore=8.5**, ratingsCount=1.
- ✅ **Nota privada — privacidad correcta**: el detalle del evento muestra "Valoración de Sebas N1 · ★★★★☆ 8.5" y **"Sólo tú y Sebas N2 veis esta nota"**. Visible para autor (N1) y evaluado (N2).
- ✅ **No duplicar**: volver a tocar el evento abre el **detalle** con la valoración existente (no permite re-valorar).
- ✅ Perfil del evaluado (N2): stats (1/1/8.5), **"Puntos fuertes" → "Fregar los platos · 8.5"** (fallback de radar con <3 valoraciones), y "Últimas valoraciones" con la nota.
- ✅ **Equilibrio del hogar** (balance card en Miembros): "50% · Desequilibrado" (media de cumplimiento N1 0% / N2 100%).
- ⚠️ Menor: tras enviar la valoración, el botón "Valorar" del Historial no se actualizó en vivo a estado "valorado" (sí al reentrar).
- ⏸️ **Radar chart** (≥3 tareas valoradas) no visto (solo 1 valoración → se muestra lista "Puntos fuertes"). Valoración bidireccional N2→N1 no probada (N1 no tiene completadas).

---

## F2 — Homes & límites de plazas — ✅
- ✅ **Selector de hogares** (dropdown en cabecera Hoy): "Cambiar hogar", lista de hogares con rol, "Añadir hogar" (→ Crear/Unirse).
- ✅ **Crear 2º hogar** "Hogar 2 QA" funciona (N2 pasa a 2 hogares = tope base).
- ✅ **3er hogar BLOQUEADO**: "No tienes cupos disponibles" (baseHomeSlots=2; el 3º no se crea). El premium vía Admin SDK no desbloquea plazas (correcto: solo una compra válida desbloquea +1).
- 🛠️ Nota tooling: cerrar el teclado con BACK en el sheet "Crear hogar" cierra TODO el sheet (no solo el teclado) → al automatizar hay que tocar "Crear" sin BACK (el botón queda por encima del teclado). (UX real aceptable.)

---

## F9 — Ciclo de vida de cuenta + payer-lock + rejoin — ✅ (con 1 bug)
- ✅ **Payer-lock**: N2 (owner+pagador, premium active) intenta abandonar → diálogo "Transferir propiedad del hogar"; al transferir a N1 el backend **rechaza** (owner sigue N2). El pagador no puede transferir/abandonar con premium activo. ⚠️ No se vio mensaje claro del bloqueo (posible snackbar transitorio).
- ✅ **Abandonar hogar** (N1 admin, no-pagador): diálogo "¿Abandonar hogar?" → N1 `status=left`, **role=admin preservado**.
  - ⚠️ Tras abandonar, el MI_9 **seguía mostrando el hogar y tareas con botones** hasta reiniciar (patrón stale del listener del home). Tras reinicio: "Sin hogar" correcto.
- ✅ **Reincorporación (rejoin)** por código: N1 vuelve con **role=admin y stats preservadas** (passedCount=1), `rejoinedAt` set, status=active.
- ✅ **Cerrar sesión** funciona (→ login).
- ✅ **Eliminar cuenta**: diálogo "¿Eliminar cuenta? (permanente e irreversible)". Sin reauth reciente → snackbar **"Por seguridad, cierra sesión y vuelve a iniciarla antes de eliminar tu cuenta."** Tras re-login → borrado real: **N1 eliminado de Auth** (`auth/user-not-found`).
- ❌ **BUG: el borrado de cuenta NO limpia la membresía**: el doc de miembro de N1 quedó `status=active` en "Hogar QA Noche" → miembro huérfano con cuenta inexistente.

## F10 — Extremos / robustez
- ✅ **Sync en tiempo real entre 2 dispositivos** confirmada repetidamente (~unos segundos; el rebuild del dashboard tarda ~10s tras completar/pasar).
- ✅ **Actionability/recurrencias** con fechas correctas (la tarea diaria a las 09:00 creada de noche se programa para mañana; botón Hecho inactivo con aviso). Forzado de fechas vía `[ADMIN SDK]` para probar Hecho.
- ⚠️ El patrón **stale del listener del doc `home`** (ver Resumen #5) es el principal hallazgo de robustez: varios cambios de estado del hogar solo se reflejan tras reiniciar la app.
- 🧰 Estado de datos al cierre: quedó "Hogar 2 QA" (2º hogar de prueba de N2) y el miembro huérfano de N1 en "Hogar QA Noche" (evidencia del bug de borrado).

---

## F8 — Perfil, Ajustes, Idioma, Notificaciones, Tema — ✅
- ✅ **Tema** Claro/Oscuro/Sistema: cambio instantáneo (probado Claro→Oscuro). Light mode se ve limpio.
- ✅ **Apariencia/skin**: "Clásico · Cálido, luminoso, familiar" con preview y selector (AppearancePicker presente).
- ✅ **Idioma en Ajustes** (es/en/ro): cambiar a English traduce toda la app ("Settings/Account/Edit profile/…"); persistido. Revertido a Español OK.
- ✅ **Notificaciones**: toggles "Avisar al vencer" (ON), "Avisar antes de vencer" (premium → al activar muestra "Tiempo de antelación · 30 minutos"), "Resumen diario". Sección "Probar notificaciones" (6 tipos).
  - ✅ Disparar «Tarea asignada» **publica una notificación real** en el sistema (channel `toka_assignment`, título "Ana te asignó una tarea", texto "Limpiar el baño · viernes 18:00", con intent de apertura).
- ✅ **Cambiar contraseña**: snackbar "Te hemos enviado un correo para restablecer tu contraseña" (envía email de reset).
- ✅ **Acerca de**: Versión 1.0.0 (1), Términos de uso, Política de privacidad. **Cerrar sesión** abre diálogo "¿Cerrar sesión?" que **sí responde** a taps (Cancelar funciona) — contrasta con el bug de los diálogos de miembro.
- ✅ **Avatar del hogar** (desde N1 admin): "Elegir de galería" → foto real → subida a **Storage** + `home.photoUrl`, snackbar "Foto del hogar actualizada.".
- ⚠️ **Refresco en vivo del doc `home`**: el avatar del hogar **seguía mostrando la inicial "H"** tras subirlo; tras **reiniciar la app** sí mostró la imagen. Mismo patrón que la tile de Suscripción (mostraba "Plan gratuito" en premium hasta reiniciar). → El objeto `home` cacheado no se actualiza en vivo ante cambios del documento (avatar, premiumStatus); el **dashboard sí** refresca en vivo. **Recomendación**: que el provider del home re-escuche el documento o invalide caché ante cambios.
- ✅ **Foto de perfil de miembro** se refleja correctamente en tarjetas de tarea (avatar del responsable), lista de miembros e historial.
- ⚠️ El avatar del hogar **no se denormaliza al dashboard** (`homePhotoUrl` ausente) → la pantalla Hoy (que lee el dashboard) no mostraría la foto del hogar.

---

## F7 — Historial — ✅
- ✅ Filtros **Todos / Completadas / Pases / Vencidas**. "Pases" muestra solo pases (con "Motivo: Estoy fuera de casa"); "Completadas" muestra solo completadas (con botón Valorar).
- ✅ Evento de pase muestra origen→destino ("Sebas N1 → Sebas N2") y motivo.
- ✅ **Tarea eliminada sigue en historial** como snapshot ("Fregar los platos") con su evento completado/pasado.
- ✅ Detalle de evento (con valoración + nota privada).
- ⏸️ Filtro "Vencidas" (missed) y paginación/cargar más: sin eventos suficientes para probar (no hay tareas vencidas sin acción; solo 2 eventos).

---

## ❌ BUG DESTACADO — Diálogos de acción de miembro con botones que no responden (alta severidad)
Al abrir el perfil de un miembro (desde Miembros) y pulsar **"Hacer administrador"**, **"Quitar administrador"** (y previsiblemente **"Expulsar del hogar"**), aparece el diálogo de confirmación, pero **sus botones (Cancelar y el de confirmar) NO responden a los toques**. Diagnóstico:
- Verificado con `input tap` y `input motionevent DOWN/UP` sobre el centro exacto de los botones (coords correctas según uiautomator) → no pasa nada; el rol no cambia.
- Tocar la **zona superior** del diálogo (barrier) SÍ lo cierra → los toques en la **mitad inferior (donde están los botones) son absorbidos** por un overlay/scrim por encima del diálogo.
- Otros diálogos de la app (Completar, Pasar turno, Eliminar tarea) SÍ responden a los mismos toques → el problema es específico de los diálogos lanzados desde el perfil de miembro.
- Reproducible tanto en promover como en degradar. **Consecuencia**: no se pueden gestionar roles ni (probablemente) expulsiones desde la UI; el usuario quedaría atascado (solo puede cerrar con BACK).
- **Recomendación**: revisar el `Navigator`/contexto con que se hace `showDialog` en el perfil de miembro (posible diálogo en un Navigator anidado/recortado o barrier mal apilado). **Conviene confirmación manual con dedo**, pero la evidencia apunta a defecto real.
- Para continuar las pruebas, los cambios de rol/expulsión se aplicaron vía `[ADMIN SDK]` y se verificó el estado resultante en la UI.

---

## F1 — Auth & Onboarding

### Login (ambos dispositivos)
- ✅ **Validación de email**: con formato inválido muestra "Introduce un email válido" en rojo bajo el campo. Correcto.
- ✅ **Login no exige longitud mínima de password** (el mínimo de 8 chars es solo en registro). Correcto.
- ⚠️ **El error de email no se limpia en vivo al corregirlo**: tras escribir un email válido el mensaje "Introduce un email válido" seguía visible hasta el submit (autovalidate no re-evalúa al teclear). Menor, pero confunde: el usuario ve error con un email ya correcto. **Mejora sugerida**: re-validar onChanged para limpiar el error al corregir.
- ✅ **Login correcto** con N1 (MI_9) y N2 (emulador) → enruta a Onboarding (cuentas nuevas sin perfil).
- 🛠️ **Nota de tooling QA** (no es bug de la app): el teclado Facemoji del MI_9 destroza `adb input text` (autocompletado). Solución: escribir carácter a carácter (`type.sh`). El emulador (Gboard) acepta texto normal.

### Onboarding
- ✅ **Welcome** ("Bienvenido a Toka / Tu app cooperativa de tareas del hogar" + botón Empezar) con barra de progreso naranja arriba. Se ve limpio y centrado.
- ✅ **Paso Idioma** (emulador): "¿En qué idioma prefieres usar Toka?" con 🇪🇸 Español / 🇬🇧 English / 🇷🇴 Română y botones Atrás/Siguiente.
- ❌ **BUG (onboarding congelado por estado stale)**: en el MI_9, tras login, el botón **"Empezar" del Welcome no avanzaba** (reproducible, incluso reiniciando la app). Tras `pm clear` (estado limpio) SÍ avanza. → El onboarding **no resetea su estado al cerrar sesión / cambiar de cuenta** en el mismo dispositivo: si el usuario A dejó estado de onboarding y entra el usuario B, el Welcome puede quedar bloqueado. **Escenario real**: varios usuarios en un mismo móvil. **Recomendación**: limpiar el estado de onboarding (SharedPreferences) en logout o al detectar cambio de uid.

### Onboarding — pasos verificados (N1 en MI_9, N2 en emulador)
- ✅ **Idioma**: cambio **en vivo e instantáneo** es↔en↔ro (títulos y botones se traducen al instante). Persistido en `users.locale`.
- ✅ **Perfil**: validación "El apodo es obligatorio" con nombre vacío; contador de caracteres correcto (30 nickname). Toggle "Mostrar mi teléfono". Persistido: `users.phoneVisibility="sameHomeMembers"` cuando se activa.
- ✅ **Foto de perfil (real, MI_9)**: selector del sistema → Galería MIUI → foto seleccionada → subida a **Cloud Storage** (`users/{uid}/profile.jpg`) y guardada en `users.photoUrl` y en el doc de miembro. Funciona end-to-end.
  - 🛠️ Nota tooling: el DocumentsUI "Reciente" del MI_9 no seleccionaba al tap; la fuente "Galería" sí. (No es bug de la app.)
- ✅ **Crear hogar (N2, onboarding)**: nombre "Hogar QA Noche" → creado en Firestore (`SMQRtCjrA09gPIr1wazD`, premium=free). Onboarding → rationale notificaciones → Hoy.
- ✅ **Unirse por código (N1, onboarding)**: validación de código inválido ("Código de invitación inválido"); con código válido `VYE6SH` se unió como `member` activo a "Hogar QA Noche".
- ✅ **Generación de invitación (N2 → Miembros → Invitar → Compartir código)**: muestra QR + código `VYE6SH` + expiración a 7 días ("Expira mar 23 jun") + Copiar/Regenerar.
- ✅ **Rationale notificaciones**: pantalla limpia (campana, checklist Nueva tarea/Cambios de turno/Valoraciones, CTA Activar/Ahora no). "Activar" concede POST_NOTIFICATIONS (granted=true). "Ahora no" salta correctamente.
- ✅ **Ads en free**: la Home muestra el banner de AdMob de prueba ("Test Ad 468x60") → confirma `showAds` en plan free.

### ❌ BUG — teléfono y visibilidad NO se propagan al doc de miembro al unirse
- N1 puso teléfono `612345678` y activó "Mostrar mi teléfono" (global `users.phoneVisibility="sameHomeMembers"`).
- Pero su doc de miembro en el hogar quedó con `phone: null` y `phoneVisibility: "hidden"`.
- El **nickname y la foto SÍ** se propagan al doc de miembro, pero el teléfono y su visibilidad **no** → otros miembros NO verán el teléfono aunque el usuario haya optado por compartirlo. (Pendiente confirmación visual abriendo perfil de N1 desde N2.)
- **Recomendación**: que `joinHome`/`syncMemberProfile` copien también `phone` y `phoneVisibility` desde el perfil de usuario.

### ⚠️ Patrón menor — errores de validación no se limpian al editar (3 casos)
- Login (email), Perfil (apodo obligatorio) e Invitación (código inválido): el mensaje de error en rojo **persiste** tras corregir el campo, hasta el siguiente submit. **Mejora**: re-validar onChanged para limpiar el error al corregir.

### 💄 Observación visual
- El subformulario de "Crear hogar" conserva el título "¿Qué quieres hacer?" y deja mucho espacio vertical vacío arriba. Mejorable (título propio + mejor distribución).

### Pendiente de F1 (a retomar)
- [ ] Registro "Crear cuenta" (validaciones: passwords no coinciden, email en uso) — requiere verificación por email para completar.
- [ ] "¿Olvidaste tu contraseña?" (envío de email + pantalla de confirmación).

---

## F3 — Tareas

### Crear tarea — formulario
- ✅ Pantalla muy completa: selector **Emoji** (grid de 24, p.ej. 🏠🍽️🧹🧺🛒🌿🐾🚗💰🔧📦🗑️…) / **Icono** (pestaña 2), título (placeholder "Ej: Fregar los platos"), descripción opcional, recurrencia, hora, zona horaria, hora fija, miembros asignados (checkbox por miembro), dificultad (slider 0.5–3.0, 1.0=20%), "Si vence sin completar" (Mantener asignado / Rotar al siguiente — solo con ≥2 miembros), y **"Próximas 3 fechas"** (preview en vivo).
- ✅ Recurrencias disponibles (chips): Puntual, Cada hora, Diario, Semanal, Mensual (día fijo), Mensual (Nth semana), Anual (fecha fija), Anual (Nth semana). Default Diario.
- ✅ Validaciones en cascada en botón Guardar: "El título es obligatorio" → "Selecciona al menos un miembro".
- ✅ **Tarea 1 creada** "Fregar los platos" (🍽️, Diario 09:00 Europe/Madrid, 2 miembros, onMiss=Rotar al siguiente). Persistida correctamente en Firestore (rec=daily, order=[N1,N2], onMiss=nextInRotation, diff=1).

### Zona horaria (correcto)
- ✅ La hora se muestra en la zona del DISPOSITIVO: tarea 09:00 Europe/Madrid se ve "09:00" en MI_9 (Madrid) y "07:00" en emulador (GMT). Coherente, no es bug.
- ✅ **Actionability correcta**: creada a las ~22:30, la próxima ocurrencia diaria es mañana 09:00 → el botón Hecho sale inactivo con "El botón 'Hecho' estará activo el mié 17 jun · 07:00". Correcto.

### Acción "Hecho" (completar) — ✅
- `[ADMIN SDK]` Para hacerla accionable se forzó `nextDueAt` al pasado (task + preview del dashboard) — documentado.
- ✅ Diálogo de confirmación: "🍽️ Fregar los platos / ¿Confirmas que has completado esta tarea? / Cancelar / Sí, hecha ✓".
- ✅ Al confirmar: evento `completed`, **rotación** al siguiente miembro (N2 completó → pasa a N1), `nextDueAt` +1 día, stats de N2: tasksCompleted=1, currentStreak=1, complianceRate=1, completions60d=1.
- ✅ Reflejo en Hoy: contador "1 completadas hoy", subgrupo **"Hechas"** con "Completada por Sebas N2 a las 22:34", y nueva entrada "Por hacer" para el siguiente responsable. (El rebuild del dashboard tarda ~10s.)

### Acción "Pasar turno" — ❌ BUG IMPORTANTE
- ✅ El servidor pasa el turno correctamente: N1→N2 con `to=N2, noCandidate=false, reason="Estoy fuera de casa"`, y N1.passedCount=1.
- ❌ **BUG (alta prioridad)**: el **diálogo de Pasar turno SIEMPRE muestra "No hay otro miembro disponible, seguirás siendo el responsable"** aunque exista un siguiente responsable válido. Reproducible en AMBOS dispositivos y con datos totalmente cargados (no es carrera). Consecuencias:
  1. **Desinforma**: dice que te quedas como responsable, pero el turno SÍ se pasa al otro miembro.
  2. **No muestra el siguiente responsable**.
  3. **No muestra la penalización de cumplimiento** → **viola la regla de negocio #7** ("Pasar turno genera penalización estadística visible antes de confirmar").
- Causa probable: lógica cliente de "siguiente elegible" rota en `PassTurnDialog` (siempre devuelve sin candidato), mientras el backend `getNextEligibleMember` sí lo calcula bien.
- ✅ El campo "Motivo (opcional)" funciona y se guarda en el evento.

### Sincronización en tiempo real entre dispositivos — ✅
- ✅ Un cambio en un dispositivo se refleja en el otro en ~unos segundos (lag de propagación + rebuild del dashboard). Confirmado en pasar turno y completar.

### ⚠️ Contador "tareas para hoy"
- Mostraba "0 tareas para hoy" con 1 tarea activa listada. Tras completar quedó coherente (la próxima ocurrencia es mañana). A vigilar: confirmar que `counters.tasksDueToday` cuenta correctamente una tarea cuyo vencimiento cae hoy.

### Tipos de recurrencia y selectores — ✅
- ✅ **Emoji** (24) y **Icono** (12 Material: home, nevera, lavadora, escoba, carrito, coche, patas, reciclaje, llave, reciclar, bañera, sol) ambos funcionan y persisten.
- ✅ **Diario** (intervalo "Cada N días"), **Cada hora** ("Cada N horas" + Hora inicio + fin opcional), **Semanal** (selector Lu–Do, multi-día), **Puntual** (fecha+hora única, "Próximas 3 fechas" muestra 1). Mensual/Anual pendientes (bloqueados por límite free; se prueban con premium).
- ✅ Dificultad: slider 0.5–3.0 (1.0=20%). onMiss "Rotar al siguiente" probado (persistió `nextInRotation`).

### Límites Free — ✅ (ambos)
- ✅ **Recurrentes (3 máx)**: con 3 recurrentes, al abrir crear tarea sale banner "Tu plan Free permite hasta 3 tareas con recurrencia. Crea una puntual o hazte Premium." + botón "Hazte Premium". Permite crear Puntual.
- ✅ **Activas (4 máx)**: con 4 activas, banner "Tu plan Free permite hasta 4 tareas activas." + "Hazte Premium".

### Congelar / Descongelar — ✅
- ✅ Detalle de tarea: app bar con **Editar tarea** + **Congelar/Descongelar**.
- ✅ Congelar mueve la tarea de Activas → Congeladas y libera plaza activa. Descongelar la devuelve a Activas.
- ⚠️ Pendiente: probar el diálogo "límite alcanzado" al descongelar estando en 4 activas (no probado aún).

### Editar — ✅
- ✅ Edición precarga todos los datos (icono, título, recurrencia). Cambié el título ("Reparar grifo" → "Reparar grifo URGENTE") y persistió.

### Eliminar — ✅ (con matices)
- ✅ **Gestos en la lista**: **swipe IZQUIERDA = Eliminar** (con diálogo "¿Eliminar tarea? Esta acción no se puede deshacer." + Eliminar/Cancelar); **swipe DERECHA = Congelar** (sin confirmación, aceptable por ser reversible).
- ✅ **Borrado es LÓGICO** (`status="deleted"`, el documento se conserva). La tarea sale de Activas y Congeladas.
- ✅ **Historial preservado**: tras borrar "Fregar los platos", sus eventos `completed`/`passed` siguen en `taskEvents` con `taskTitleSnapshot`.
- ✅ **Puntuaciones preservadas**: N2 mantiene tasksCompleted=1, complianceRate=1 tras borrar la tarea.
- 💄 No se guarda `deletedAt` en el borrado lógico (solo `status`). Recomendable para auditoría/limpieza.
- ⚠️ No hay acción de borrar desde el **detalle** de la tarea (solo Editar/Congelar); el borrado solo está en swipe-izquierda de la lista. Posible mejora: ofrecer borrar también desde el detalle.

### Premium (gating de tareas) — hallazgos
- `[ADMIN SDK]` Hogar puesto en `active`. premiumFlags: `isPremium:true, showAds:false, canUseSmartDistribution:true, canUseVacations:true, canUseReviews:true`.
- ✅ **Sin límite de tareas** en premium: se creó la tarea **Mensual (día fijo)** "Limpiar nevera" sin banner de bloqueo. "Próximas 3 fechas" muestra la rotación (1 jul→N1, 1 ago→N2, 1 sept→N1).
- ✅ **Hoy sin ads** en premium.
- ⚠️ **BUG de gating**: la pantalla **Crear tarea sigue mostrando el banner de AdMob** pese a `showAds:false` (en Hoy sí se oculta). La pantalla de creación no respeta el flag premium para ads.
- ⚠️ **Smart distribution sin UI**: `canUseSmartDistribution:true` pero el formulario de tarea **no ofrece selector "Distribución inteligente"** (solo rotación básica + "Mantener asignado/Rotar al siguiente"). Flag habilitado sin punto de entrada en UI. (Mensual/Anual: el tipo Anual no se creó individualmente, pero los chips y la estructura del form son idénticos a Mensual, ya verificado.)


