# QA Exhaustiva Toka — 2026-06-24

**Build:** `app-debug.apk` (main.dart → producción toka-dd241), compilado 2026-06-24 con Windows Flutter.
**Dispositivos:** emulator-5554 (1080x2400) + MI_9 físico (1080x2340).
**Metodología:** usuarios nuevos creados por el formulario de registro (dominio `@tokatest.dev`, sin verificación de email — el router no la exige, `app.dart:135`). Admin SDK (`toka-sa.json`) usado SOLO para alternar premium/free/tier de los hogares de prueba. Fuente de verdad: el código, no documentos. Capturas analizadas y borradas tras cada análisis.

**Cuentas de prueba:**
- Usuario A (emulador): `toka.real.ana@tokatest.dev` / `TokaReal2024!`
- Usuario B (MI_9): `toka.real.beto@tokatest.dev` / `TokaReal2024!`

**Escala de severidad:** 🔴 Blocker · 🟠 Grave · 🟡 Menor · 🔵 Cosmético/UX · ✅ OK

---

## Hallazgos

### Entorno / arranque
- ✅ App arranca conectada a producción; pantalla Hoy renderiza sin overflow. Banner "Test Ad" 320x50 visible en hogar Free (showAds=true, ad_banner_enabled). NavigationBar con 5 tabs (Hoy/Historial/Miembros/Tareas/Ajustes).

### Ajustes (cuenta previa QA_Post_Fix, Free)
- ✅ Pantalla Ajustes completa renderiza sin overflow. Secciones: Cuenta (Editar perfil, Cambiar contraseña, Eliminar cuenta, Idioma), Apariencia (skins Clásico/Océano, tema Claro/Oscuro/Sistema), Toka Plus (Toka Plus, Mis métricas, Notificaciones), Privacidad (Visibilidad del teléfono, Exportar mis datos), Suscripción (Plan gratuito, Restaurar compras), Hogar (Ajustes del hogar, Abandonar hogar), Acerca de (Versión 1.0.0 (1), Términos, Política privacidad), Cerrar sesión.
- ✅ Flags de prod observados ON: `toka_plus_enabled` (sección Toka Plus + skin Océano gated con 🔒 "Requiere Toka Plus"), `ad_differentiated_enabled`+`ad_interstitial_enabled` (intersticial test apareció al cambiar de tab Hoy→Ajustes), `ad_banner_enabled`.
- 🔵 El intersticial de AdMob saltó en el **primer** cambio de pestaña de la sesión (Hoy→Ajustes). Es test ad; comportamiento esperado por diseño (cap por intervalo/sesión) pero conviene revisar que no sea demasiado agresivo en primer uso. Cierra con botón "Close".
- ✅ Logout: diálogo de confirmación "¿Cerrar sesión?" (Cancelar/Cerrar sesión) → tras confirmar, splash → Login. Correcto.

### Login
- ✅ Pantalla Login limpia: "Continuar con Google", email + contraseña (toggle "Mostrar contraseña"), "Iniciar sesión", "¿Olvidaste tu contraseña?", "¿No tienes cuenta? Crear cuenta", icono idioma. Semántica accesible correcta (content-desc en todos los controles).

### Registro + Onboarding (usuario nuevo Ana, emulador)
- ✅ Registro por formulario funciona: email+contraseña+confirmar. Cuenta creada (uid jFNBvm25...), `emailVerified=false`, y la app pasa directa a onboarding sin exigir verificación (consistente con `app.dart:135`). Email de verificación se envía pero no bloquea.
- ✅ Validación del formulario de registro correcta: email sin `@` → "Introduce un email válido"; contraseña <8 → "La contraseña debe tener al menos 8 caracteres"; confirmar vacío → "Este campo es obligatorio". Mínimo 8 (más estricto que Firebase 6).
- ✅ Onboarding paso 0 "Get started" responde correctamente (el blocker histórico de "Empezar no responde" NO se reproduce).
- ✅ Paso 1 idioma: 3 opciones (Español/English/Română) desde colección `languages`. Arranca en inglés (locale del sistema del emulador, sin selección previa); al elegir Español la UI cambia de idioma al instante. Correcto.
- 🔵 Onboarding arranca en inglés para usuario nuevo (toma locale del dispositivo). Esperable, pero si se quisiera default ES se podría revisar. No es bug.
- ✅ Paso 2 perfil: nickname (0/30), teléfono opcional, toggle "Mostrar mi teléfono a miembros del hogar" **OFF por defecto** (buen default de privacidad). Guardado: nickname=Ana, locale=es.
- ✅ Paso 3 "¿Qué quieres hacer?": Crear/Unirme a un hogar. Crear hogar (campo nombre 0/40) → hogar creado `xBjacg2JdYhHTpX6NsI1` name="Casa" premiumStatus=free maxMembers=3, Ana=owner/active.
- ✅ Rationale de notificaciones tras crear hogar → "Activar notificaciones" dispara permiso del SO (POST_NOTIFICATIONS), concedido. Llega a pantalla Hoy.
- ✅ Banner de ads (468x60 test) aparece en Hoy tras ~unos segundos de carga de AdMob (en hogar Free). La ausencia inicial era latencia, no bug.
- 🟡 El doc `users/{uid}` de Ana no tiene campos de slots (`baseHomeSlots`/`lifetimeUnlockedHomeSlots`/`homeSlotCap` = undefined). Revisar si el modelo "2 base + 3 extra permanentes" depende de estos campos y si su ausencia afecta el límite de hogares (a verificar al crear 2º/3er hogar).

### Tareas (Usuario A / hogar Casa, Free)
- ✅ Crear tarea: selector emoji/icono (default 🏠), título, descripción, recurrencias **más completas que el mapa de specs**: Puntual, **Cada hora**, Diario (default), Semanal, Mensual (día fijo), Mensual (Nth semana), Anual (fecha fija). Intervalo "Cada N días", Hora, Zona horaria (Europe/Madrid), toggle "Hora fija", checkbox "Crear ocurrencia para hoy", Miembros asignados (validación "Selecciona al menos un miembro"), Modo de asignación (Rotación básica / Distribución inteligente 🔒 gated, "requiere ≥2 miembros"), "Si vence sin completar" (Mantener asignado / Rotar al siguiente), Dificultad (slider), Próximas 3 fechas. Guardado OK → aparece en Tareas>Activas y, con "ocurrencia para hoy", en Hoy.
- ✅ "Crear ocurrencia para hoy" funciona (el fix del bug histórico "salta a mañana"): la tarea diaria aparece HOY al marcarlo.
- ✅ Completar tarea ("Hecho"): animación + confetti, pasa a sección "Hechas" con "Completada por Ana a las HH:MM". Contadores se actualizan (0 para hoy / 1 completada).
- 🟡 **Pluralización i18n**: la tarjeta de resumen muestra **"1 tareas para hoy"** (debería ser "1 tarea"). Falta plural ICU para count=1. (a confirmar clave ARB con análisis de código).
- 🟠 **A verificar (undo)**: tras "Hecho" NO observé el SnackBar "Deshacer" (o dura <1s) y la tarea ya queda commiteada en "Hechas" inmediatamente. Pendiente confirmar con código si hay ventana de undo real y SnackBar. (bug histórico [[snackbar-action-persist-flutter-344]] era lo contrario: SnackBar que NO desaparecía).
- 🟡 **A verificar (Hoy muestra futuro)**: tras completar la ocurrencia de hoy de una tarea DIARIA, la SIGUIENTE ocurrencia (jue 07:00) aparece en "Por hacer" en la propia pantalla Hoy con "Hecho" deshabilitado. Confuso para el usuario (¿por qué una tarea de mañana en "Hoy"?). Pendiente confirmar si es intencional.
- 🔵 El banner de ads (fijo abajo) solapa la parte inferior del formulario de crear tarea ("Si vence sin completar"); el form es scrollable, pero conviene padding extra para que el banner no tape controles.

- ✅ **Undo confirmado** (re-test con captura en mismo comando): al pulsar "Hecho" aparece SnackBar negro flotante "Tarea completada · Deshacer", la tarea se oculta optimistamente de "Por hacer", commit diferido `kUndoWindow=10s` (`pending_completions_provider.dart:13`). ~13s después el SnackBar ya desapareció solo (`persist:false`, `today_screen_v2.dart:46`) → el bug histórico [[snackbar-action-persist-flutter-344]] (SnackBar pegado) NO se reproduce.
- ℹ️ Confirmado por código: la ocurrencia futura en "Hoy" es intencional (`task_actionability.dart` deshabilita Hecho si la fecha aún no llegó); el dashboard backend envía la próxima ocurrencia. Sigue siendo confuso de cara al usuario (🟡 UX).
- ℹ️ La hora mostrada usa la zona del dispositivo (emulador UTC → 07:00) y no la del hogar (Madrid 09:00). A verificar en MI_9 (zona Madrid).

- ✅ **Límite Free recurrentes (3)**: con 3 tareas recurrentes, el form de Crear tarea muestra arriba banner "Tu plan Free permite hasta 3 tareas con recurrencia. Crea una puntual o hazte Premium." + botón "Hazte Premium". Gate proactivo (mejor UX que bloquear al guardar). Límite de 4 tareas activas (`maxActiveTasks`) por código, mismo mecanismo.
- ✅ Detalle de tarea: Responsable, Próxima vez, Dificultad, Próximas fechas (5), iconos Editar/Congelar/Eliminar.
- ✅ Congelar (⏸️→▶️) sin diálogo (acción reversible). Reanudar OK.
- ✅ Editar tarea: form pre-llena correctamente (título, recurrencia, emoji); no muestra banner de límite (no añade recurrente). 
- ✅ Borrar: diálogo "¿Eliminar tarea? Esta acción no se puede deshacer." (Cancelar/Eliminar) → elimina y vuelve a la lista sin residuos.
- 🟠 **Inconsistencia de zona horaria entre vistas**: la MISMA tarea (09:00 Europe/Madrid) se muestra como **07:00** en lista de Tareas y en Hoy (hora del dispositivo, emulador UTC) pero como **09:00** en el Detalle ("Próxima vez"/"Próximas fechas", hora del hogar). Para un usuario en otra zona que la del hogar, las horas no cuadran entre pantallas. (En MI_9/Madrid coincidirían — verificar). Revisar qué zona debe ser la canónica en la UI.

### Miembros / Invitación / Multi-dispositivo (Beto en MI_9)
- ✅ Invitar (emulador, Ana owner): pantalla Miembros con "Equilibrio del hogar 100% · Bien repartido", FAB Invitar → sheet "Invitar miembro" → "Compartir código" genera código **LCUT89** + QR + "Expira el mié 1 jul" + Copiar/Regenerar código.
- ✅ Registro 2º usuario Beto en MI_9 por formulario (email con `@` correcto, sin corrupción MIUI esta vez). Onboarding en **español** (MI_9 locale ES) — confirma que el idioma inicial toma el locale del dispositivo.
- ✅ Unirse por código: campo "Código de invitación" (6 chars, contador 0/6→6/6). **Escritura char-a-char OK** (el bug histórico [[qa-regression-2026-06-19]] de `adb input text` corrompiendo el código se evita escribiendo carácter a carácter). "Unirme" → rationale notif → "Ahora no" → entra a Hoy del hogar Casa.
- ✅ **Sincronización en vivo entre dispositivos**: Beto (MI_9) ve de inmediato las tareas creadas por Ana (Fregar platos, Sacar basura) y sus completados ("Completada por Ana a las 16:17/16:24"). 
- ✅ Tema oscuro en MI_9 renderiza bien (la app respeta el tema del sistema).
- ✅ Banner de ads SÍ aparece en MI_9 ("Anuncio de prueba" 320x50, **localizado al español** — en emulador inglés salía "Test Ad"). 
- ℹ️ **Zona horaria (resuelto el contexto)**: la MISMA tarea (09:00 Madrid) se ve 09:00 en MI_9 (Madrid) y 07:00 en emulador (UTC) en lista/Hoy, porque la lista usa la hora del DISPOSITIVO. El Detalle siempre usa la del hogar (09:00). Para un usuario en la zona del hogar todo cuadra; la inconsistencia lista(device-tz) vs detalle(home-tz) solo aparece si el dispositivo está en otra zona que el hogar. Severidad 🟡 (edge case real: miembro viajando).

- ✅ Perfil de miembro (Beto visto por Ana owner): avatar, badge Miembro, stats (Tareas completadas/Racha/Puntuación media), "Puntos fuertes: Sin valoraciones todavía", botón "Expulsar del hogar".
- ✅ **Gate Free de roles admin**: banner rojo "Los roles de admin están disponibles en Premium." (con 🔒) — el toggle admin no está en Free (maxAdminsTotal=1). Correcto.
- ✅ Privacidad teléfono: el perfil de Beto NO muestra teléfono (Beto no lo puso y dejó el toggle OFF). El bug histórico "teléfono visible pese a hidden" NO se reproduce.

### Rotación de turnos / Pasar turno
- ✅ Con 2 miembros, "Modo de asignación: Rotación básica" se selecciona por defecto; "Distribución inteligente" gated Premium 🔒. "Si vence sin completar": Mantener asignado / Rotar al siguiente.
- ✅ Rotación correcta: "Próximas 3 fechas" alternan responsables (jue→Beto, vie→Ana, sáb→Beto).
- ✅ **Pasar turno** (desde MI_9/Beto): diálogo "¿Pasar turno?" muestra **"El impacto en tu cumplimiento será mínimo"** (penalización visible antes de confirmar — regla de negocio #7), "El siguiente responsable será: Ana", y "Motivo (opcional)". Confirmar → la ocurrencia pasa a Ana (verificado en ambos dispositivos: en Beto queda deshabilitada, en Ana aparece actionable "Hoy"). El refresco del dashboard tardó ~unos segundos.
- 🔵 **Hoy filtra/ordena por usuario + posible latencia de dashboard**: tras crear la tarea de rotación, Ana no la veía inmediatamente en su Hoy (sí Beto, su responsable de hoy); tras el pase y unos segundos, Ana sí la ve. Probablemente latencia de regeneración del dashboard (Cloud Function trigger), no bug de filtrado. A confirmar con re-test controlado si se quiere descartar inconsistencia.

### Historial / Valoraciones
- ✅ Historial: lista de eventos con tiempos relativos ("hace 2 min"), pase de turno ("Beto → Ana · Limpiar bano · pase de turno"), completadas ("Ana completó X"). Filtros Todos/Completadas/Pases/Vencidas funcionan (Pases filtra correctamente).
- ✅ Gate Free de historial: banner "Más historial con Premium · Accede a 90 días de historial · Actualizar a Premium".
- ✅ Detalle de evento: tarea + emoji, fecha "24 junio 2026 · 14:24", "Ana completó", "Aún no hay valoraciones para este evento". (Valoraciones gated Premium `canUseReviews` — pendiente verificar con premium activo).

### Suscripción / Paywall
- ✅ Paywall en **modo TIERS** (`home_tiers_enabled` ON en prod): "Haz tu hogar Premium · Las mismas funciones premium en los tres planes. Solo cambia cuántos miembros caben." 3 tiers: **Toka Pareja** (≤2, 19,99€/año · 2,99€/mes), **Toka Familia** (≤5, 29,99€/año · 3,99€/mes), **Toka Grupo** (≤10, 49,99€/año · 5,99€/mes). Toggle Mensual/Anual actualiza precios correctamente. Sección "Packs de miembros" gated ("disponibles en el plan Toka Grupo · Sube a Grupo"). Restaurar compras + términos. Precios IAP cargados OK.

### Gating Premium (hogar Casa → active vía Admin SDK)
- ✅ Al activar Premium, el **banner de ads desaparece** de inmediato (showAds=false) en la pantalla Hoy.
- ✅ **Roles admin desbloqueados**: en el perfil de miembro desaparece el banner "disponibles en Premium" y aparece "Hacer administrador" → diálogo "¿Hacer administrador a Beto?" → Confirmar → badge **Admin** (azul) + botón "Quitar administrador". Backend: role=admin. Cambio de rol completo (UI+backend).

### Estados de suscripción (Admin SDK)
- ✅ **Rescate**: banner rojo en Hoy "Tu Premium vence en 2 días — renueva para no perder features · Renovar" → pantalla "Renueva tu Premium": countdown, **"Último intento de cobro: Tarjeta rechazada (INSUFFICIENT_FUNDS). Reintento en 24h"** (lastBillingError mostrado), tabla comparativa Gratuito/Premium (10 miembros, distribución inteligente, vacaciones, valoraciones privadas, historial 90 días, sin publicidad), botones Empezar Premium Anual / Plan mensual / Planear downgrade.
- ✅ **Downgrade planner**: "¿Qué miembros continuarán? Máximo 3 (owner siempre incluido)" (Ana/Propietario fija, Beto seleccionable); "¿Qué tareas continuarán? Máximo 4" (las 3 tareas); "Si no decides, se aplicará selección automática" + Guardar plan. Usa límites Free (3 miembros/4 tareas) como destino del downgrade.

### Toka Plus (individual, per-usuario)
- ✅ El premium del hogar NO desbloquea Plus: con Casa premium, el skin Océano sigue "Requiere Toka Plus" (ejes separados, correcto).
- ✅ Paywall Plus: "Desbloquea aspectos exclusivos y tus métricas personales" — 🎨 Aspectos exclusivos (skins solo Plus), 📈 Métricas personales (racha, puntualidad, reparto). Anual 14,99€ "Mejor precio" / Mensual 1,99€. Suscribirme + Restaurar compra.

- ✅ Plus activado (Admin SDK, entitlement propio): el skin **Océano se desbloquea** (sin candado) y al seleccionarlo **cambia la paleta de la app de naranja a azul** en todas las pantallas. El cliente lee el entitlement propio (la proyección `members.plusActive` no se actualizó por falta de índice COLLECTION_GROUP en prod — [[collectiongroup-index-prod-only]] — pero el gating propio funciona igual).
- ✅ **Mis métricas (Plus)**: Tareas completadas 2, Racha actual 1, Puntualidad 100%, Puntuación media 0.0, Turnos pasados 0, Tu reparto 100%, "Puntos fuertes: Sin valoraciones todavía". Datos correctos.

### Ajustes restantes
- ✅ Notificaciones: "Avisar al vencer" (ON), "Avisar antes de vencer" (premium) → al activarlo aparece selector "Tiempo de antelación: 30 minutos", "Resumen diario". Sección "Probar notificaciones" con 6 botones (Tarea por vencer/asignada, Recordatorio previo, Resumen diario, Valoración recibida, Rotación de turno) → SnackBar "Notificación de prueba enviada". 
- ✅ **Exportar mis datos (GDPR)**: SnackBar "Preparando la exportación..." → share sheet de Android "Sharing 1 file · toka_export_<uid>.json". La callable se ejecutó sin error de App Check (debug token ya registrado → las callables funcionan en este dispositivo).
- ✅ Ajustes refleja "Plan Premium" (★) cuando el hogar es premium (antes "Plan gratuito").

- ✅ Idioma in-app: selector (🇪🇸/🇬🇧/🇷🇴) → cambiar a English traduce TODA la UI al instante ("Settings", "Edit profile", "Ocean · Cool, calm blue", "My stats"). Restaurado a Español.
- ✅ **Valoraciones (premium)**: en Historial, los eventos de otros muestran botón "Valorar" (★) → diálogo "Valorar tarea" (Puntuación slider 0-10, "Nota privada (opcional)", Enviar). Guardada (Beto→Ana, 5.5/10, "Bien hecho Ana"). El detalle muestra ★★⯪ 5.5/10 + **"Nota privada · Bien hecho Ana · Sólo tú y Ana veis esta nota"** → confirma regla de negocio #8 (notas privadas: solo autor y evaluado).

### Ads diferenciadas (confirmado por código — NO es bug)
- ✅ **Intencional y documentado** (`lib/shared/widgets/ad_visibility_provider.dart:53`): `banner = !hasPlus && !(homeIsPremium && isPayer)`. Con `ad_differentiated_enabled` ON, el hogar Premium solo libra de **banner** al **pagador** (`currentPayerUid`) y a quienes tengan Toka Plus; un miembro no-pagador/no-Plus de hogar Premium SÍ ve banner (incentivo a comprar Plus individual). El **intersticial** sí es beneficio colectivo: `interstitial = !homeIsPremium && !hasPlus` → con hogar premium nadie ve intersticial (verificado: Beto cambió de tab sin intersticial). Asimetría banner(individual)/intersticial(colectivo) documentada en el código. Con el flag OFF la visibilidad sería por-hogar (`showAds`).

### Gestión de miembros: payer-locked, expulsar, abandonar (regla #5)
- ✅ **Payer-locked** (regla #5): Ana (owner+pagadora de premium activo) intenta "Abandonar hogar" → diálogo "Transferir propiedad del hogar" (selecciona nuevo owner) → al confirmar Transferir, se **bloquea**: Ana sigue siendo owner (backend) y aparece SnackBar "No puedes expulsar ni salir del hogar mientras seas el pagador de la suscripción Premium activa. Cancela la suscripción primero o espera a que expire." Feedback claro.

- ✅ **Expulsar miembro** (Beto, admin pero no pagador): diálogo "¿Expulsar a Beto del hogar? Esta acción no se puede deshacer" → Confirmar → backend status=**left**; en Ana, Beto pasa a "Antiguos miembros" con botón "Reincorporar" (no membresía fantasma — manejo correcto), equilibrio recalculado a 100%. 
- ✅ **Sync de expulsión**: Beto (MI_9) pierde acceso al instante → estado "Sin historial · Crea un hogar o únete a uno" (Crear/Unirme).
- 🔵 Si el expulsado está en una pantalla profunda (detalle de evento) en el momento de la expulsión, ve brevemente "Algo salió mal. Inténtalo de nuevo." hasta que navega; se recupera al estado "sin hogar". Menor (efecto de perder permisos de lectura en pantalla abierta).

### Perfil / Cuenta
- ✅ Selector de hogares (tap avatar/título en Hoy): bottom sheet "Cambiar hogar" (Casa · Propietario ✓ + "Añadir hogar"). 
- ✅ Editar perfil: form pre-llenado (Apodo "Ana", Teléfono "600111222", toggle "Mostrar teléfono" OFF). Editar Bio + Guardar → SnackBar "Perfil guardado".
- ✅ Cambiar contraseña: diálogo "¿Cambiar contraseña? Te enviaremos un enlace a tu correo electrónico para restablecer tu contraseña." (reset por email, seguro).
- ✅ **Eliminar cuenta**: diálogo "¿Eliminar cuenta? Esta acción es permanente e irreversible. Perderás acceso a todos tus hogares y datos." → al confirmar (sin re-login reciente), maneja el `requires-recent-login` de Firebase con mensaje claro "Por seguridad, cierra sesión y vuelve a iniciarla antes de eliminar tu cuenta." (no error técnico). Buen manejo.

- ✅ **Límite de hogares (2 base)**: Ana pudo crear un 2º hogar "CasaDos" (free) → posee 2 hogares (Casa premium + CasaDos free). El sistema asume 2 hogares base por defecto (los campos `baseHomeSlots`/`lifetimeUnlockedHomeSlots`/`homeSlotCap` están undefined en el doc users pero no bloquean). El tope (3er hogar requiere slot extra de pago) NO se probó (requeriría crear un 3º).

---

## Resumen ejecutivo (hallazgos accionables)

La app está en muy buen estado. Todos los flujos críticos funcionan correctamente (auth, onboarding, tareas, miembros multi-dispositivo, rotación, valoraciones, suscripción, gating premium/Plus, GDPR). Los bugs históricos previos NO se reproducen (Empezar onboarding, SnackBar pegado, teléfono visible, membresía fantasma, salta-a-mañana). Hallazgos a revisar, por prioridad:

**🟡 Menores (recomendado corregir):**
1. **Pluralización i18n**: "1 tareas para hoy" / "1 completadas hoy" (debería ser singular para count=1). `lib/l10n/app_es.arb:328,333` (claves `today_tasks_due`, `today_tasks_done_today`) — usar plural ICU `{count, plural, =1{...} other{...}}`. Afecta también app_en/app_ro.
2. **Zona horaria inconsistente entre vistas**: la misma tarea (09:00 hora del hogar) se muestra con la hora del DISPOSITIVO en la lista de Tareas y en Hoy (07:00 si device en UTC) pero con la hora del HOGAR en el Detalle (09:00). Solo divergen si el dispositivo está en otra zona que el hogar. Decidir cuál es la zona canónica en la UI y unificar.
3. **Ocurrencia futura en "Hoy"**: tras completar una tarea diaria, la ocurrencia de mañana aparece en "Por hacer" dentro de "Hoy" con el botón Hecho deshabilitado (intencional por `task_actionability.dart`, pero confuso de cara al usuario — una tarea de mañana en la pantalla "Hoy").

**🔵 Cosméticos / UX:**
4. El banner de ads fijo solapa la última opción del formulario de Crear tarea ("Si vence sin completar"); añadir padding inferior.
5. El intersticial de AdMob salta ya en el primer cambio de pestaña de la sesión; revisar si es demasiado agresivo en el primer uso (cap de 3/sesión e intervalo sí se respetan).
6. Al expulsar a un miembro que está en una pantalla profunda (detalle de evento), ve brevemente "Algo salió mal. Inténtalo de nuevo." hasta navegar; idealmente redirigir directo al estado "sin hogar".

**ℹ️ Comportamientos confirmados como intencionales (no bugs):**
- Ads diferenciadas: un miembro no-pagador/no-Plus de un hogar Premium SÍ ve el banner (solo el pagador y los Plus se libran; el intersticial sí es colectivo). Documentado en `ad_visibility_provider.dart:53`.
- Onboarding arranca en el idioma del dispositivo (no siempre ES).
- Roles admin / valoraciones / vacaciones / distribución inteligente / historial 90d / "sin banner para el pagador" gated correctamente por Premium.

**No cubierto (justificación):**
- Compra IAP real (no hay sandbox de pago configurado; precios sí cargan).
- Tope de 3er hogar (requiere slot extra de pago).
- Vacaciones de miembro (requería 2 miembros; Beto fue expulsado al final).
- Panel de soporte/diagnóstico (requiere custom claim `support`, no disponible para usuario normal — correcto que no sea accesible).
- Login social Google/Apple (requiere cuentas reales; el formulario email/password sí se probó a fondo).

**Datos de la sesión:** 2 usuarios reales creados por formulario (Ana@emulador owner, Beto@MI_9 member). Premium/Plus alternados vía Admin SDK solo para verificar gating; estado revertido a free/sin-Plus al terminar. Hogares de prueba creados: Casa, CasaDos (quedan en prod, son cuentas @tokatest.dev).

---

## Cierre de fixes — sesión 2026-06-25

Los 6 hallazgos accionables quedaron **corregidos y verificados** (detalle técnico de cada fix en `HANDOFF-FIXES.md`). Verificación:

| # | Fix | Test unitario | Verificación visual |
|---|-----|---------------|---------------------|
| 1 | Pluralización ICU | — | ✅ (sesión previa) |
| 2 | Zona horaria del hogar (`TokaDates.inZone` + `home.timezone`) | ✅ inZone 28/28 | ✅ emulador GMT muestra **09:00** (hora hogar Madrid) en Hoy/Tareas/form, no 07:00; MI_9 Madrid coincide |
| 3 | Sección "Próximas" en Hoy | ✅ today_view_model 14/14 | ✅ emulador: sección "Próximas" agrupa las no-accionables con Hecho deshabilitado |
| 4 | Padding banner (raíz: `AdAwareScaffold.bottomPaddingOf`→`MainShellV2.bottomContentPadding`) | ✅ ad_aware_scaffold 4/4 | ✅ form crear tarea: último control ("Próximas 3 fechas"/"Si vence sin completar") muy por encima del banner |
| 5 | Gracia intersticial 1er cambio de pestaña | ✅ 10/10 | ✅ emulador: Hoy→Tareas (1er cambio) sin intersticial |
| 6 | Redirect del expulsado (`app.dart` hasError→/home) | ✅ app_router 10/10 | cubierto por test |

`test/unit` completo = **911/911 verde**. `flutter analyze` limpio en `lib/`.
~52 goldens en `test/ui` fallan con diffs de rendering pequeños (0.03–3.47%) en TODAS las features (login, paywall, settings...): es un cambio de rendering GLOBAL preexistente del WIP, NO de estos fixes (verificado: `login_screen.png` no tocado falla igual). No regenerados.

### Hallazgos NUEVOS (sesión 2026-06-25)

- ✅ **[RESUELTO] Desajuste sección "Próximas" vs label "Hoy" con dispositivo en otra zona que el hogar.** Tras el fix #2 (el label de hora usa la zona del HOGAR), la decisión de "accionable hoy" (`task_actionability.dart`) seguía usando la zona del DISPOSITIVO. Efecto observado en el emulador GMT: "Fregar platos · **Hoy** 09:00" caía en **"Próximas"** con Hecho deshabilitado. **Corregido** (decisión del usuario 2026-06-25): `TaskActionability.isActionable` y `formatDueForMessage` ahora aceptan `timezone` (zona del hogar) y calculan las fronteras hoy/semana/mes en esa zona; cableado desde `groupByRecurrence` (via `currentHome.timezone`) y `today_task_card_todo_v2`. Sin `timezone` conservan la zona del dispositivo (compatibilidad). Tests: `task_actionability_test` 21/21 (incl. casos Madrid vs GMT). Coherencia total label+sección. **Verificado en emulador GMT**: las 3 tareas diarias 09:00 Madrid ahora salen en "Por hacer" con Hecho activo (antes caían en "Próximas").

- ✅ **[RESUELTO] Motivo de vacaciones no se rehidrataba (pérdida de datos silenciosa).** Al guardar una vacación con motivo y reabrir, el campo "Motivo" salía vacío; si luego se editaba otra cosa y se guardaba, el `reason` se reescribía como `null` → **se perdía el motivo**. Causa raíz (3 capas): `_VacationVMState` no tenía campo `reason`, `build()` no lo copiaba del doc, y el screen tenía un no-op explícito que no rehidrataba el `TextField`. **Corregido**: añadido `reason` al estado/getter, cargado en `build` (migrado de `watch`+`Future.microtask` —no testeable— a `ref.listen`, idiomático y observable), y el screen rehidrata el controller una vez. Test `vacation_view_model_test` 7/7 (incl. caso "carga el reason de una vacación existente").

---

## QA exhaustiva — flujos de la sección 7 (2026-06-25)

Continuación tras cerrar los 6 fixes. Entorno: emulador GMT (Ana, owner de Casa) + MI_9 Madrid (Beto). Premium/free alternado vía Admin SDK solo para gating; Casa revertida a **free** al terminar.

- ✅ **Vacaciones de miembro** (Premium): el botón "Vacaciones / Ausencia" solo aparece en el perfil PROPIO (`isSelf`) y es gated a Premium (en Free → paywall). Flujo verificado end-to-end: activar toggle → aparecen Fecha inicio/fin + Motivo (opcionales) → Guardar → chip "🏖 De vacaciones" en la lista de Miembros; desactivar toggle → Guardar → chip desaparece. Sin overflow. (Ver 🔵 motivo no rehidratado, arriba.)
- ✅ **Tope de 3er hogar**: Ana tiene 2 hogares (Casa+CasaDos) y `getAvailableSlots`=0 (2 base, 0 créditos). Crear un 3er hogar se **bloquea**: el hogar nunca se creó (≈6 intentos) y el código (`home_selector_widget.dart:493`) captura `NoAvailableSlotsException` mostrando el error inline **"No tienes cupos disponibles"** (`homes_error_no_slots`) sin cerrar el form. (La captura del mensaje inline no se logró por fragilidad de adb con el bottom sheet —`keyevent 111`=ESCAPE descartaba el sheet—, pero el bloqueo está confirmado por datos + código.)
- ✅ **Toggle de tema Claro/Oscuro/Sistema** (Ajustes → Apariencia): cambio instantáneo Claro↔Oscuro↔Sistema. Verificado Sistema→Oscuro (UI a fondo negro al instante) y restaurado. Skin Océano gated "Requiere Toka Plus" 🔒.
- ✅ **Pestaña "Congeladas"** (Tareas): congelar desde el detalle (icono ⏸️ "Congelar", sin diálogo) → la tarea aparece en la pestaña Congeladas con título tachado + icono ❄️; descongelar (icono "Descongelar") → vuelve a Activas y Congeladas queda vacía. Estado limpio.
- ✅ **Intersticial AdMob** (confirma fix #5): al cambiar de pestaña en hogar free (tras consumida la gracia del 1er cambio y pasado el intervalo) aparece el intersticial test; se cierra con la X (esquina sup-der, tras unos segundos). El 1er cambio de pestaña de la sesión NO lo mostró (gracia #5 OK).
- ⚠️ **Avatar/foto de perfil** (Editar perfil → "Añadir foto"): abre correctamente el **Android Photo Picker** (integración con el SO OK, no crashea). El upload end-to-end NO se completó porque la galería del emulador está vacía ("No photos yet"). El upload a Cloud Storage es código existente (`updateHomePhoto`/`updateProfilePhoto`). Pendiente probar con una imagen real en galería.

**No verificable en este entorno (documentado, sin forzar):**
- **Panel Soporte/Diagnóstico** (`/support-diagnostics`): requiere custom claim `support` + App Check (debug token no registrable por el agente, [[appcheck-blocks-device-verification]]). Lógica ya implementada/testeada/desplegada ([[hallazgo-17-support-observability]]). No es flujo de usuario final.
- **Escaneo QR** del código de invitación: la cámara del emulador no muestra un QR real (escena virtual). El código manual sí se probó.
- **Login social Google/Apple**: requiere OAuth con cuentas reales; el Google Sign-in colapsa Play Services en el emulador (CLAUDE.md). Solo email/password probado.
- **Compra IAP real**: sin sandbox de pago; precios sí cargan.
