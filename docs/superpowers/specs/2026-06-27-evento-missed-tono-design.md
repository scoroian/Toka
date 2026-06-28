# Diseño — Hallazgo #08: el evento "missed" no debe ser una acusación personal en el feed común

> Lote **UX Hallazgos 2026-06-25**. Prioridad 🟠 Alto. Forma parte del reencuadre de
> tono cooperativo (07, 08, 11, 12, 29).

## Problema

Cuando una tarea vence sin completarse, un **cron** crea automáticamente un evento `missed`
que aparece en el **feed de historial compartido** del hogar como **"{name} no completó"**,
con el **avatar de la persona** como leading, icono de alarma (naranja) y, en datos,
`penaltyApplied:true` + bajada de `complianceRate`. Es vigilancia (registro automático) +
juicio (etiqueta de fallo) + exposición (muro común) sin que ningún humano lo decida. En una
app cooperativa para parejas/familias, esto erosiona la confianza.

Evidencia:
- `functions/src/jobs/process_expired_tasks.ts:194-225` — `eventType:"missed"`, `penaltyApplied:true`, bajada de `complianceRate`.
- `lib/features/history/presentation/widgets/history_event_tile.dart:243-284` — `_MissedTile` (avatar de la persona, título `"{name} no completó"`, icono `timer_off_outlined` en `Colors.orange`).
- `lib/features/history/presentation/skins/history_event_detail_screen_v2.dart:128` — resumen `history_event_missed(_name(actorUid))`.
- ARB `history_event_missed: "{name} no completó"` (es), `"{name} didn't complete"` (en), `"{name} nu a finalizat"` (ro).
- `firestore.rules:218` — `taskEvents` legibles por cualquier `isCurrentMember` (lo expone a todo el hogar).

## Decisión de producto (confirmada)

- **Enfoque elegido: A — Encuadre neutro.** El evento se reformula para hablar del **estado de
  la tarea**, no de la persona. Se descartó el **Enfoque B (visibilidad privada)** por su coste
  y fragilidad: Firestore no filtra resultados por reglas (una query del feed que devuelva un doc
  no legible falla **entera** con permission-denied), de modo que "visible solo para el responsable"
  en la misma colección exigiría un campo `visibility`, doble query + merge + paginación combinada,
  cambios de reglas y tests de reglas. No aporta lo suficiente frente al riesgo dado que A ya elimina
  la acusación.
- **Penalización estadística: se mantiene.** El backend sigue registrando `penaltyApplied:true` y
  bajando `complianceRate` (uso interno de la métrica). El #08 solo reencuadra la **presentación**;
  el tono de la métrica "Cumplimiento" es territorio del **#12**. Como el feed nunca mostró el número,
  el reencuadre de copy ya satisface el criterio "la penalización deja de exhibirse como etiqueta
  pública de fallo".

## Alcance

**Solo cliente Flutter + ARB.** Sin backend, sin reglas, sin cambios de modelo, sin nuevos providers.
El backend crea el evento exactamente igual que hoy; solo cambia cómo se presenta en el feed y en el
detalle.

## Cambios

### 1. `_MissedTile` (`history_event_tile.dart:243-284`)

- **Título:** usar `l10n.history_event_missed` **sin placeholder** → "Tarea vencida". Desaparece toda
  referencia nominal (`actorName`).
- **Leading:** sustituir el `_Avatar` de la persona por un **icono neutro** (despersonalizar). Un
  `CircleAvatar` con fondo `cs.surfaceContainerHighest` e `Icon(Icons.event_busy, color: cs.onSurfaceVariant)`
  (icono exacto refinable en la revisión del golden). Mantiene el hueco de 40px para alinear con el
  resto de tiles del feed.
- **Color:** el icono trailing `Icons.timer_off_outlined` deja de ser `Colors.orange` → `cs.onSurfaceVariant`
  (neutro, sin alarma). Sin naranja/rojo en el tile.
- **Limpieza:** se eliminan de `_MissedTile` los parámetros ya no usados `actorName` y `actorPhotoUrl`
  (el padre `HistoryEventTile` deja de pasarlos al construir el sub-tile `missed`).
- **Subtítulo** (etiqueta de la tarea + timestamp): **sin cambios**.

### 2. Detalle (`history_event_detail_screen_v2.dart:128`)

- `MissedEvent e => l10n.history_event_missed(_name(e.actorUid))` → `MissedEvent _ => l10n.history_event_missed`
  (sin nombre). El header (tarea + fecha) y el bloque de reviews no aplican al `missed` (su `_performerUid`
  ya es `null`), así que no hay otras superficies con nombre.

### 3. Copy (ARB es/en/ro)

Se **reemplaza** `history_event_missed` (que exigía placeholder `{name}`) por un copy neutro centrado
en la tarea, alineado con el vocabulario del chip de filtro ya existente. Se **elimina** el bloque
`@`-metadata `placeholders` de esa clave en los tres ARB.

| Clave | es | en | ro |
|---|---|---|---|
| `history_event_missed` (reescrita, sin placeholder) | Tarea vencida | Task overdue | Sarcină expirată |

- Filtro ya existente (sin tocar, como referencia de coherencia): `history_filter_missed` = es "Vencidas" / en "Missed" / ro "Expirate".
- Regenerar localizaciones tras editar los ARB (`flutter gen-l10n` / build de l10n).

## Criterios de aceptación

- [ ] El evento `missed` ya no se presenta como acusación personal en el feed común: sin nombre, sin
      avatar de la persona, sin color de alarma (Enfoque A).
- [ ] El detalle del evento `missed` tampoco muestra el nombre del responsable.
- [ ] La penalización estadística (que se mantiene en backend) no se exhibe como etiqueta pública de
      fallo (el feed/detalle no muestran el número ni la baja de cumplimiento).
- [ ] Localizado es/en/ro, coherente con el vocabulario del filtro.

## Pruebas

### Unit / Widget / Golden (cliente)
- **Widget `_MissedTile`** (vía `HistoryEventTile` con un `MissedEvent`): assert que **no** aparece
  ningún `actorName` ni su inicial; el título es el copy neutro `history_event_missed`; el tile no usa
  `Colors.orange` (sin alarma).
- **Golden** nuevo del tile `missed` reencuadrado (es).
- **Detalle**: montar `history_event_detail_screen_v2` con un `MissedEvent` → el resumen muestra el copy
  neutro **sin** nombre.
- Regenerar goldens del historial afectados si cambia el render.

### Backend (jest) — N/A justificado
- El backend **no se toca** con el Enfoque A: el evento conserva `eventType:"missed"`, sin campo de
  visibilidad nuevo y sin copy (el copy vive en el cliente). El test existente de
  `process_expired_tasks` sigue siendo la cobertura válida; **no se añade test backend** porque no hay
  nuevo tipo/visibilidad/copy en el servidor.

### Gates
- `flutter analyze` → sin errores en los archivos tocados.
- `flutter test test/unit/` + tests nuevos/afectados de UI de historial → verde (documentar los ~fallos
  golden ambientales por `google_fonts` sin red, ajenos al hallazgo).

### Verificación en dispositivo (Firebase real, dos perfiles)
1. Con Admin SDK crear una tarea con vencimiento inminente asignada a la cuenta de **MI_9** y dejar que
   el cron real la marque `missed` (o disparar el job en `toka-dd241` / inyectar el `taskEvent` `missed`
   con Admin SDK respetando el esquema actual).
2. Abrir Historial en **ambos** dispositivos (emulador=Ana, MI_9=Beto): el copy es **neutro**
   ("Tarea vencida"), **sin nombre** y **sin alarma** en ambos. Capturas en cada uno.
3. Verificar en `logcat` que no hay errores de permisos (no se tocan reglas, pero confirmar que el feed
   sigue cargando con normalidad).

## Fuera de alcance / no-objetivos

- **Enfoque B (visibilidad privada)**: descartado; sin tocar `firestore.rules` ni el modelo del evento.
- **La métrica de cumplimiento** y su tono ("Cumplimiento"/"Puntualidad"): territorio del **#12**.
- El evento `completed` mantiene "{name} completó" (reconocimiento positivo, no acusación).
- El diálogo de **pasar turno** (color/tono): territorio del **#11**.

## Riesgos

- **Goldens**: el cambio de título/leading/color regenerará el/los golden del historial. Revisar el diff
  visual antes de aceptar el nuevo master.
- **Coherencia de tono**: al cerrar 07/08/11/12/29, repasar el vocabulario es/en/ro en conjunto (incluida
  la unificación "vencida/overdue/expirată" con el filtro).
