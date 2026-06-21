# Hallazgos QA — Noche 2026-06-20 (análisis independiente)

Leyenda severidad: 🔴 bloqueante · 🟠 importante · 🟡 menor · 🔵 mejora/UX · ✅ correcto

Cada cambio de estado/fecha vía **Admin SDK** se anota con `⚙️ SDK:` y el comando exacto.

---

## Campaña 0 — Setup ✅
- Dispositivos OK: MI_9 (43340fd2, 1080x2340) + emulator-5554 (1080x2400).
- Ambos arrancan en **Hogar Real QA** (MI_9=Sol owner, emu=Luna admin). 3er miembro: Tres.
- Tooling `ui.sh` funcionando: Flutter expone semántica vía `content-desc` (tap por etiqueta).
- Cuentas QA aseguradas (owner/member/admin + n1/n2/n3). n1 recién creada.
- ⚙️ SDK: `node secrets/qa_setup_accounts.js` (reset passwords + emailVerified=true; se documenta que se salta verificación email por no haber buzón real).

---

## Campaña 2 — Pantalla Hoy (Hecho / Pasar / orden / sync)

Entorno: Hogar Real QA (free). MI_9=Sol(owner), Emu=Luna(admin). Tareas: "Sacar basura" (horaria, rotación 1 persona=Luna) y "Limpiar cocina" (diaria 09:00, rotación Sol→Luna→Tres).

- ✅ **Completar (✓ Hecho)**: diálogo de confirmación "🗑️ Sacar basura — ¿Confirmas que has completado esta tarea?" → "Sí, hecha ✓" / "Cancelar". Al confirmar: contador "completadas hoy" +1, la tarea horaria avanza su `nextDueAt` +1h, y se añade fila "Completada por Luna a las HH:MM" en subgrupo Hechas.
- ✅ **Pasar turno (multi-persona, NO vencida)**: diálogo "¿Pasar turno?" muestra "El siguiente responsable será: Luna" + campo "Motivo (opcional)". Sin penalización (correcto: pasar una tarea no vencida no penaliza). Verificado en Firestore: `currentAssigneeUid` Sol→Luna, order=[Sol,Luna,Tres]. El motivo escrito se acepta.
- ✅ **Pasar turno (VENCIDA) → PENALIZACIÓN VISIBLE** (regla negocio #7): diálogo muestra en caja roja "**Tu cumplimiento bajará de 50% a ~40%**". Verificado en Firestore que se aplica de verdad: `complianceRate` 0.5→**0.4**, `passedCount`+1. La preview es fiel.
- ✅ **Caso rotación de 1 sola persona**: el diálogo avisa "No hay otro miembro disponible, seguirás siendo el responsable". Al confirmar, la tarea NO se reprograma (sigue vencida y tuya) pero SÍ aplica la penalización. Comportamiento coherente (no puedes esquivar una tarea en solitario).
- ✅ **Sincronización en vivo entre dispositivos**: completar/pasar en un device se refleja en el otro (contadores, asignado, botones de acción que aparecen/desaparecen según responsable).
- ✅ **Timezone**: la hora se muestra en el timezone LOCAL de cada dispositivo (MI_9 Madrid 15:41 / Emu GMT 13:41 para el mismo instante). Correcto y esperado.
- ✅ **Orden de secciones**: Hora → Día (las únicas presentes ahora). Verificaré Semana/Mes/Año en C3.

### Hallazgos
- 🔵 **Sin update optimista en el device que actúa**. Tras Hecho/Pasar, el dispositivo que ejecutó la acción NO actualiza su UI inmediatamente: espera la regeneración del `views/dashboard` en backend (~2-8s, más lento en emulador). Durante esa ventana muestra estado obsoleto, INCLUYENDO los botones de acción ya inválidos. El OTRO dispositivo (listener pasivo) a veces refresca antes. UX: el usuario puede pensar que "no pasó nada" y volver a tocar. Recomendación: update optimista local al confirmar.
- 🟡 **"✓ Hecho" en tarea NO vencida: deshabilitado sin feedback**. Una tarea futura (p.ej. diaria que vence mañana) muestra el botón "✓ Hecho" en gris con icono de reloj ⏰. Está deshabilitado (correcto: no completar antes de tiempo) PERO al tocarlo no da ningún feedback (ni tooltip ni snackbar). El usuario no entiende por qué "no funciona". Recomendación: snackbar "Aún no puedes completar esta tarea (vence el domingo)" o quitar el botón.
- 🔵 **Posible doble-completación en ventana stale** (hipótesis, no confirmada): como el botón sigue visible tras completar durante la ventana de latencia, tocar de nuevo podría reabrir el diálogo. Pendiente de probar idempotencia.
- ✅ Visual: diálogos limpios, penalización en rojo bien destacada, jerarquía clara, on-brand (naranja en foco). Banner de anuncio de prueba presente (correcto en hogar free).

## Campaña 3 — Tareas CRUD (todas las configuraciones)

Pantalla **Crear tarea** (muy completa). Campos: selector **Emoji / Icono** (2 pestañas; Emoji guarda `emoji:<char>`, Icono guarda `icon:<codepoint>` de Material), Título, Descripción (opcional), **8 tipos de recurrencia** (Puntual, Cada hora, Diario, Semanal, Mensual día-fijo, Mensual Nth-semana, Anual fecha-fija, Anual Nth-semana) + intervalo "Cada N", **Hora fija** (switch), **Crear ocurrencia para hoy** (checkbox), **Miembros asignados** (multi-check con handle "=" para reordenar la rotación), **Modo de asignación** (Rotación básica / Distribución inteligente 🔒premium), **Si vence sin completar** (Mantener asignado / Rotar al siguiente), **Dificultad** (slider 20%→100% = peso 1.0→3.0 paso 0.5), **Próximas 3 fechas** (preview con rotación por ocurrencia).

- ✅ **Crear Semanal**: "Compra semanal QA" con días Lu/Mi/Vi, rotación Luna→Sol→Tres, dificultad 2.5, onMiss "Rotar al siguiente". Verificado en Firestore: `recurrenceType=weekly, rule={weekdays:[MON,WED,FRI],time:09:00,tz:Europe/Madrid}, difficulty=2.5, mode=basicRotation, onMiss=nextInRotation, order=[Luna,Sol,Tres]`. **Todo persiste correcto.**
- ✅ **Preview "Próximas 3 fechas"** preciso: lun 22→Luna, mié 24→Sol, vie 26→Tres (Lu/Mi/Vi + rotación correctas). En el detalle muestra 5 próximas.
- ✅ **Crear Puntual** con **Icono** (no emoji): "Arreglar grifo QA" → `recurrenceType=oneTime, visual=icon:57622, rule={date,time,tz}`. Texto guía "Se completa una sola vez y desaparece del listado". El tab Icono funciona.
- ✅ **Zona horaria por tarea** configurable (Europe/Madrid por defecto).
- ✅ **Congelar**: instantáneo sin confirmación; `status=frozen`; sale de "Activas" y aparece en filtro "Congeladas". Botón pasa a "Descongelar".
- ✅ **Descongelar**: vuelve a `status=active` y a "Activas".
- ✅ **Editar tarea**: cambié título a "Compra semanal QA v2" (mismo ID = edición real, no duplicado). Persiste.
- ✅ **Eliminar**: confirmación "¿Eliminar tarea? Esta acción no se puede deshacer." Es **soft-delete** (`status=deleted`, doc conservado). **Las puntuaciones del miembro PERSISTEN** (Luna tasksCompleted=3, complianceRate=0.5 sin cambios tras borrar la tarea que completó). [Persistencia en Historial: ver C4]
- ✅ **Orden pantalla Hoy**: Hora → Día → Semana verificado (regla #6). Mes/Año pendientes (requieren >3 recurrentes = premium).

### Límites y gating
- ✅ **Límite plan Free = 3 tareas con recurrencia**. Al intentar la 4ª recurrente: banner "Tu plan Free permite hasta 3 tareas con recurrencia. Crea una puntual o hazte Premium" + botón "Hazte Premium" + Guardar deshabilitado. Las **Puntual NO cuentan** para el límite.
- ✅ **Gating premium "Distribución inteligente"**: en hogar free abre el **paywall** "Haz tu hogar Premium" (tabla comparativa: hasta 10 miembros, distribución inteligente, modo vacaciones, valoraciones privadas, historial 90 días, sin publicidad; Anual 29,99€ ahorra 17,89€ / Mensual 3,99€; Restaurar compras; términos). Math del ahorro correcto.

### BUGS / mejoras
- 🟠 **BUG: las tareas Puntual (oneTime) NO se renderizan en la pantalla Hoy**. La puntual "Arreglar grifo QA" (vencida hoy 21:34, asignada a Sol) está en `activeTasksPreview` del dashboard y se cuenta en "tareas para hoy" (tasksDueToday=2), pero NO aparece en ningún grupo de la pantalla Hoy (la agrupación solo maneja Hora/Día/Semana/Mes/Año, sin bucket para oneTime). Además el detalle de tarea NO tiene acción "Hecho". **Consecuencia: una tarea Puntual es prácticamente imposible de completar desde la UI.** Severidad alta (función rota end-to-end).
- 🔵 **El banner de anuncio solapa la parte inferior del formulario** Crear tarea (chips de recurrencia inferiores y "Cada N días" quedan parcialmente tras el banner). Conviene padding inferior = altura del banner.
- 🟡 **Modo asignación y onMiss solo aparecen al seleccionar ≥1 miembro** — correcto, pero "Distribución inteligente" se muestra siempre con candado (bien). El handle de reordenar rotación ("=") es poco descubrible (sin label).

### Ampliación C3 — Mensual y orden
- ✅ **Crear Mensual (día fijo)**: "Pagar alquiler QA" con picker "Día del mes" (lista 1-31, elegí 15) → `recurrenceType=monthly, rule={type:monthlyFixed, day:15, time:09:00, tz:Europe/Madrid}`. Persiste.
- ✅ **Orden Hoy completo verificado**: Hora → Día → Semana → **Mes** (regla #6). "Año" pendiente (hogar premium, requiere >3 recurrentes).
- 🟡 Tipos de recurrencia **Mensual (Nth semana), Anual (fecha fija), Anual (Nth semana)** existen en la UI pero no se pudieron crear aquí por el límite free de 3 recurrentes; se crearán en el hogar premium (C6).
- 🟡 **UX fecha en Hoy**: una tarea mensual a 3+ semanas muestra "mié 09:00" (solo día de semana) sin la fecha (15 jul) → ambiguo "¿qué miércoles?". Mostrar fecha cuando la ocurrencia no es de esta semana.

## Campaña 4 — Historial y filtros

- ✅ **Filtros funcionan**: Todos / Completadas / Pases / Vencidas. Cada uno filtra correctamente: Completadas (solo "X completó"), Pases (solo "pase de turno"), Vencidas (solo "X no completó").
- ✅ **Eventos ricos**: avatar + actor + (origen→destino en pases) + icono y nombre de tarea + tiempo relativo ("hace 24 min", "hace 9 h", "hace 1 día").
- ✅ **Motivo del pase se registra y muestra** en cursiva ("Motivo: QA noche test").
- ✅ **PERSISTENCIA tras borrado**: la tarea "Sacar basura" (borrada en C3) sigue apareciendo en el historial con todos sus eventos de completar/pasar/vencer. Confirma requisito "ver cómo se quedan en el historial una vez eliminadas".
- ✅ **Valoraciones gated a Premium**: cada completación muestra botón ☆ "Valoraciones solo en Premium"; al tocarlo abre bottom-sheet contextual "Actualiza a Premium para valorar las tareas completadas por otros miembros del hogar" + "Hazte Premium". Buen upsell contextual.
- 🟡 No hay filtro por **miembro** ni por **rango de fechas** (solo por tipo de evento). El plan Free parece mostrar historial reciente; Premium = 90 días (según paywall). No verificable el corte exacto de días sin forzar fechas masivas.

## Campaña 5 — Miembros (parte A: estado FREE)

- ✅ **Límite Free = 3 miembros**: banner "Tu plan Free permite hasta 3 miembros... 3/3 — límite del plan Free" + Hazte Premium. Con hogar lleno NO aparece el FAB de invitar.
- ✅ **Lista de miembros**: badges de rol (Propietario naranja / Admin azul / Miembro gris) + Cumplimiento %. Card "Equilibrio del hogar" (17%, "Desequilibrado · Luna +3") — informativa, no navegable.
- ✅ **Detalle de miembro**: avatar, stats (Tareas completadas, Racha actual, Puntuación media), "Puntos fuertes" (de valoraciones), botones de acción.
- ✅ **Expulsar miembro** (disponible en Free): confirmación "¿Expulsar a Tres? Esta acción no se puede deshacer" → `status=left`, pasa a sección **"Antiguos miembros"** con botón **"Reincorporar"**.
- ✅ **Reincorporar** (Free): confirmación "¿Reincorporar a Tres?" → `status=active`, vuelve a "Activos".
- ✅ **Quitar administrador** (Free, disponible): en el detalle de un admin el owner ve "Quitar administrador". **Asimetría**: PROMOVER a admin está gated ("Los roles de admin están disponibles en Premium") pero QUITAR admin no.
- ✅ **Teléfono oculto respeta privacidad**: Luna tiene phone `600111222` con `phoneVisibility=hidden`; en su perfil visto por Sol **NO se muestra el teléfono**. (El bug histórico "teléfono visible pese a hidden" NO se reproduce.)
- ✅ **Valoraciones y notas privadas (visualización en Free)**: el perfil de Luna muestra "Últimas valoraciones" con nota; el detalle del evento muestra estrellas (★★★★☆ 8.5/10), "Valoración de Sol", "Nota privada de Sol sobre Luna" y el aviso **"Sólo tú y Luna veis esta nota"** (regla #8 comunicada). Crear nuevas valoraciones SÍ está gated (ver C4).

### BUGS / a vigilar
- 🟠 **Contadores del dashboard stale tras expulsar**: tras poner a Tres en `left`, `planCounters.activeMembers` siguió en **3** (no bajó a 2) y `memberPreview` lo mantenía como `active` (>4s). El banner "3/3 — límite del plan Free" sigue mostrándose con solo 2 activos → **probablemente impide invitar un reemplazo** mientras el slot 'left' no se libere. La LISTA de miembros sí refresca (Tres va a "Antiguos"), pero el CONTADOR de plan no. Verificar regeneración de `planCounters` al cambiar `status` de un miembro.
- 🟡 El `tap` por texto "Luna" colisiona con "Desequilibrado · Luna +3" (no es bug de la app; nota de tooling).

## Campaña 5 — Miembros (parte B: PREMIUM)
⚙️ SDK: `node secrets/qa_premium.js mAJXlAhwRV1kdy4O05hG <Sol> active` (hogar→premium para probar funciones).

- ✅ **Premium quita anuncios** en ambos dispositivos (banner desaparece de Hoy/Tareas/Miembros).
- ✅ **Premium amplía límite de miembros**: el banner "3/3 Free" desaparece y aparece el **FAB "Invitar"** (oculto en free+lleno).
- ✅ **Invitar miembro**: bottom-sheet "Compartir código" / "Invitar por email". Compartir código muestra **código (V5LQCM) + QR + "Expira sáb 27 jun" + Copiar/Regenerar**. (Join end-to-end en C1.)
- ✅ **Crear valoración**: en Historial las completaciones muestran "Valorar" (ya no "solo Premium"). Diálogo "Valorar tarea": slider 0-10 + campo de nota privada + "Enviar valoración". Creé 9.5 + nota "Excelente trabajo QA noche". Verificado: `ratedEventIds` de Sol pasó de 2→3; modelo = cada miembro valora cada evento una vez.
- ✅ **Privacidad de notas (regla #8) ENFORCED EN FIRESTORE RULES** (no solo UI): `firestore.rules` líneas 304-311 restringen lectura de cada review a `reviewerUid` (autor) o `performerUid` (evaluado). Tres (tercero) **no puede leer** la nota de Sol sobre Luna ni a nivel de BD. Implementación robusta y segura.
- ✅ **Sync en vivo de valoración**: Luna (emulador) ve la nota nueva de Sol ("9.5 Excelente trabajo QA noche"); su Puntuación media subió 8.5→8.8.
- ✅ **Teléfono**: visible para el propio usuario (Luna ve su 600111222), oculto a los demás (Sol no lo ve). `phoneVisibility=hidden` correcto, sin leak.
- ✅ **Modo Vacaciones / Ausencia** (premium): botón en el perfil PROPIO. Pantalla con switch "Estoy de vacaciones / ausente" + Fecha inicio/fin (opcionales) + motivo + Guardar. Guardado verificado: `vacation.isActive=true, reason="QA noche vacaciones"`.

### BUGS / mejoras (parte B)
- 🟡 **Vacaciones sin indicador en la lista de Miembros**: con Luna `isActive=true` de vacaciones, la lista de Miembros la muestra igual que el resto (sin badge "De vacaciones"/paraguas). El usuario no sabe quién está ausente.
- 🟡 **"Próximas fechas" no respeta vacaciones**: el preview de rotación de una tarea sigue asignando a Luna (lun 22→Luna, lun 29→Luna) pese a estar de vacaciones. (El fix reciente solo afecta al preview del diálogo de pasar turno, no al schedule mostrado.) Inconsistente para el usuario.
- 🟡 **Estrella de "ya valorado" no refresca al instante**: tras enviar una valoración, el evento puede seguir mostrando la estrella outline (valorable) hasta refrescar (misma familia que la falta de update optimista).

## Campaña 6 — Premium: ciclo de cancelación / degradado / rescate / restauración
⚙️ Todos los estados forzados vía Admin SDK: `node secrets/qa_premium.js mAJXlAhwRV1kdy4O05hG <Sol> <estado>`.

- ✅ **Suscripción (active)**: Ajustes→Suscripción→"Plan Premium" → "Tu suscripción": "Premium activo · Próxima renovación: 20 julio 2026 · debug · Pagador: tú" + "Gestionar facturación" + "Cancelar renovación".
- ✅ **"Cancelar renovación" deep-linka a Google Play** (gestión nativa de suscripciones). Correcto para suscripción real; la premium "debug" no aparece ahí (por eso el resto se prueba por SDK).
- ✅ **cancelledPendingEnd**: "Premium hasta el 30 junio 2026 · No se renovará automáticamente · Pagador: tú" + "Reactivar renovación" / "Cambiar de plan". Insignia premium en verde.
- ✅ **rescue** (`rescueFlags.isInRescue`): banner rojo ⚠️ "Tu Premium vence en 1 días — renueva para no perder capacidades · Premium hasta el 22 junio 2026" + "Renovar" / "Planear downgrade".
- ✅ **PANTALLA "Planear downgrade"** (la que pidió el usuario): "¿Qué miembros continuarán? Máximo 3 (owner siempre incluido)" [Luna/Sol-fijo/Tres] + "¿Qué tareas continuarán? Máximo 4" [las 4 tareas] + "Si no decides, se aplicará selección automática" (regla #9) + "Guardar plan" → snackbar "Plan de downgrade guardado".
- ✅ **expiredFree**: banner en Hoy "Tu Premium expiró el 19/06/2026. Reactívalo cuando quieras" + "Reactivar Premium"; **los anuncios VUELVEN**. Sin pérdida de datos (hogar dentro de límites free).
- ✅ **restorable** (ventana restauración, restoreUntil=10/07/2026 ≈ 30 días): banner verde "Puedes restaurar tu Premium hasta el 10/07/2026" + "Restaurar".

### BUGS / mejoras
- 🟡 **i18n pluralización**: "Tu Premium vence en **1 días**" → debería ser "1 **día**" (singular). Revisar plurales ICU en los textos de días.
- 🟡 No verificable aquí la regla #5 "el pagador no puede ser expulsado mientras haya premium vigente" porque pagador=owner=Sol (el owner nunca es expulsable). Requiere un setup con pagador ≠ owner.
- ℹ️ "Planear downgrade" se ofrece aun cuando el hogar ya está dentro de límites free (3 miembros/3 recurrentes): no hay nada que recortar, pero la pantalla aparece igualmente (correcto de forma genérica).

### Nota C3 (recurrencia Anual) y observación FAB
- 🟡 No se completó la creación de una tarea **Anual (fecha fija)**: el config se ve correcto (Mes Enero + Día del mes + Hora + Zona horaria) pero el **checkbox del último miembro queda al borde inferior, solapando la NavigationBar** → el tap cae en la pestaña Ajustes en vez del checkbox. (Parcialmente tooling, pero indica falta de padding inferior en la lista de miembros del formulario.) Orden Hora→Día→Semana→Mes confirmado; "Año" sigue la misma lógica.
- ℹ️ El **FAB de crear tarea cambia de posición** según haya anuncio (free: y≈1812) o no (premium: y≈1988). Esperado.

## Campaña 7 — Perfil, Ajustes, Idioma, Notificaciones, Imágenes

- ✅ **Editar perfil**: avatar + "Añadir/Cambiar foto", Apodo, Bio (0/160), Teléfono, switch "Mostrar teléfono a miembros del hogar".
- ✅ **Subir foto desde galería** (la pidió el usuario): "Añadir foto" abre el selector del sistema; con la fuente **Galería** se selecciona una imagen → se sube a **Cloud Storage** (`photoUrl=https://firebasestorage.../users/<uid>/profile.jpg`). 
  - ✅ **Reflejo en Miembros**: el avatar de Sol pasa de inicial "S" a la imagen.
  - ✅ **Reflejo en Historial (retroactivo)**: los eventos de Sol muestran su foto incluso en eventos antiguos (avatares leídos en vivo del doc de miembro, no denormalizados).
- ✅ **Idioma**: selector con 🇪🇸 Español / 🇬🇧 English / 🇷🇴 Română (de la colección `languages`). Cambio a English **instantáneo** (toda la UI traducida sin reiniciar). Persiste en `users/<uid>.locale`.
- ✅ **Notificaciones**: switches (Avisar al vencer / antes de vencer / Resumen diario) + 6 botones de prueba. "Probar «Tarea asignada»" **postea una notificación real** (channel `toka_assignment`, importance alta, título "Ana te asignó una tarea", texto "Limpiar el baño · viernes 18:00").
- ✅ **Tema**: Claro / Oscuro / Sistema — cambio **instantáneo**. Skin "Clásico" (única skin; coherente con la maquinaria de skins conservada).
- ✅ **Ajustes del hogar**: avatar del hogar, nombre editable, estado premium, **Gestionar miembros**, **Administradores (3)**, **Invitaciones pendientes (1)**, **Transferir propiedad**, **Abandonar hogar**, **Cerrar hogar**. Editar nombre → se refleja en la cabecera de Hoy.
- ✅ **Visibilidad del teléfono**: control en Ajustes>Privacidad y en Editar perfil (switch "Mostrar teléfono a miembros del hogar").

### BUGS / mejoras
- 🟡 **Guardar nombre del hogar poco descubrible**: el campo "Nombre del hogar" NO tiene botón Guardar y NO persiste al pulsar "Atrás" (la edición se pierde en silencio). SOLO guarda al pulsar "Done/Enter" del teclado. Un usuario que edita y vuelve atrás pierde el cambio. Recomendación: botón Guardar explícito o auto-save on-blur.
- 🟡 **Build DEBUG en producción**: Ajustes del hogar muestra un botón "🧪 DEBUG: Estado premium / Actual: active" que permite cambiar el estado premium a mano. Es un build debug (banner DEBUG visible), correcto para QA, pero **asegurarse de que NO aparece en builds release** de producción.
- ℹ️ La bio no se guardó en un intento (probable fallo de foco del tap, no confirmado como bug).

## Campaña 1 — Onboarding y unirse a hogares

- ✅ **Cerrar sesión**: Ajustes (abajo, bajo "Acerca de") → "Cerrar sesión" con confirmación "¿Cerrar sesión?".
- ✅ **Pantalla auth**: "Bienvenido a Toka", "Continuar con Google", email/contraseña, "Iniciar sesión", "¿Olvidaste tu contraseña?", "¿No tienes cuenta? Crear cuenta".
- ✅ **Registro (Crear cuenta)**: email + contraseña + confirmar. Registré `toka.qa.night1@tokatest.dev`. Tras crear → va DIRECTO al onboarding "¿Qué quieres hacer?" (Crear un hogar / Unirme a un hogar).
- ✅ **Crear hogar (onboarding)**: "Crea tu hogar" (nombre 40 chars) → "Crear hogar" → pantalla Hoy del hogar nuevo ("Hogar Noche QA", 0 tareas). **NO se reprodujo el blocker histórico de "Empezar"** (parece corregido o era otra ruta).
- ✅ **Unirse a un hogar con código**: header → "Cambiar hogar" → "Añadir hogar" → "Unirse a un hogar" → campo de 6 chars (+ "Escanear QR") → introduje **V5LQCM** (char-a-char) → "Unirse" → se unió a "Hogar Real QA" y cambió a ese hogar. Verificado: night1 `role=member status=active`, totalMembers 3→4.
- ✅ **Sync en vivo del join**: el MI_9 (Sol) muestra al instante el 4º miembro en la lista.
- ✅ **Home switcher**: "Cambiar hogar" lista los hogares con rol + "Añadir hogar" (Crear / Unirse).
- ✅ **LÍMITE de hogares por cuenta enforced (regla #2)**: con night1 en 2 hogares base, al intentar crear un 3º → "**No tienes cupos disponibles**" (bloqueado). Extras requieren cobros.

### BUGS / mejoras
- 🟡 **Verificación de email NO obligatoria**: el registro email/contraseña deja usar la app con `emailVerified=false` (no hay paso de verificación). Posible riesgo de spam/cuentas falsas; valorar exigir verificación.
- 🟡 **Nuevo miembro sin apodo se muestra como "?"**: night1 (sin nickname tras registro) aparece como "?" en la lista de miembros. Debería pedir nombre en onboarding o usar el prefijo del email por defecto.

## Campaña 8 — Abandonar hogar y eliminar cuenta

- ✅ **Abandonar hogar (miembro)**: Ajustes → "Abandonar hogar" → confirmación "¿Abandonar hogar? Dejarás de tener acceso a las tareas de este hogar." → `status=left`. La app navega al otro hogar del usuario (Hogar Noche QA). **Sin prompt de transferencia** (correcto: night1 era miembro no-owner; la ruta limpia funciona).
- ✅ **Eliminar cuenta — re-auth requerido**: primer intento (sesión antigua) → bloqueado con mensaje claro "Por seguridad, cierra sesión y vuelve a iniciarla antes de eliminar tu cuenta" (manejo correcto de `requires-recent-login` de Firebase).
- ✅ **Eliminar cuenta — tras re-login**: confirmación "¿Eliminar cuenta? Esta acción es permanente e irreversible. Perderás acceso a todos tus hogares y datos." → borra la cuenta de **Auth** (verificado: "no user record").
- ✅ **Limpieza correcta (bug histórico de "membresía fantasma" RESUELTO)**:
  - Membresías del usuario borrado marcadas `accountDeleted=true` (status=left) y **excluidas de los contadores**: Hogar Real QA pasó a `totalMembers=3` correctamente.
  - Hogar propio sin más miembros (Hogar Noche QA) → **purgado**: `ownerUid=null, premiumStatus=purged, counters=0`.

### Observación
- 🟠 **Reconfirma el bug de contadores stale**: expulsar/abandonar (status→left) NO regenera `planCounters/memberPreview` del dashboard (siguen contando al miembro), pero **eliminar cuenta SÍ los regenera** (totalMembers correcto). El gap está en el trigger de cambio de `status` a 'left' por expulsión/abandono, no en el de borrado de cuenta. Recomendación: unificar la regeneración de contadores en todos los cambios de `members/{uid}.status`.

## Ronda 2 — Confirmaciones de severidad

- 🟠 **CONFIRMADO impacto real del bug de contadores stale (a nivel de DATOS, no solo UI)**: en Hogar Real QA (free, 3 miembros), expulsé a Tres → 2 activos reales, pero `planCounters.activeMembers` se quedó en **3** en Firestore (verificado tras navegar fuera y volver, fuerza relectura del dashboard). La pantalla Miembros sigue "3/3 — límite del plan Free" y **NO ofrece "Invitar"**. Consecuencia concreta: **un owner de hogar free que expulsa/pierde a un miembro NO puede invitar un reemplazo** (el slot del 'left' no se libera nunca, no hay acción de "eliminar definitivamente"). Severidad 🟠 alta. Reincorporar al miembro restaura el contador.

### Cluster de bugs de bookkeeping de miembros (Ronda 2) — 🟠
Durante operaciones rápidas de expulsar/abandonar/borrar/reincorporar observé un cluster de inconsistencias en los agregados de miembros (`members/{uid}.status`, `views/dashboard.planCounters`, `memberPreview`):
1. **Expulsar/abandonar no decrementa `planCounters.activeMembers`** (queda stale) → hogar free "lleno" 3/3 → **no se puede invitar reemplazo** (confirmado a nivel de datos).
2. **Una cuenta BORRADA reapareció como miembro ACTIVO** ("?" en Activos): la membresía de night1 (con `accountDeleted=true`) pasó de `status=left` a `status=active` tras operaciones de otros miembros → **miembro zombie** visible en la UI.
3. **Reincorporar quedó bloqueado** mientras el contador stale marcaba 3/3 (el check de cupo usa el contador inflado).
**Causa raíz probable**: la regeneración de `planCounters`/`memberPreview` no es consistente entre todos los triggers de cambio de `status` (sí lo hace el borrado de cuenta y el join, no la expulsión/abandono). **Recomendación**: reconciliar server-side los agregados de miembros en CUALQUIER cambio de `members/{uid}.status`, y excluir siempre `accountDeleted=true` y `status!=active`. (Requiere revisión del código de Cloud Functions; fuera del alcance de la caja negra.)

### Más bugs en "Antiguos miembros" con cuenta borrada — 🟡
- La cuenta BORRADA (night1) aparece en "Antiguos miembros" mostrando su **UID crudo** ("wyxqInZJl...") en vez de "Cuenta eliminada".
- Y ofrece botón **"Reincorporar"** → reincorporar una cuenta con `accountDeleted=true` / sin Auth crearía una **membresía fantasma de un usuario inexistente**. El botón no debería aparecer (o la cuenta borrada debería filtrarse de "Antiguos miembros").
