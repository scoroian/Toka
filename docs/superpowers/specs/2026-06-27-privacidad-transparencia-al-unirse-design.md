# Diseño — Hallazgo #09: transparencia "esto compartes con el hogar" al unirse

> Lote **UX Hallazgos 2026-06-25**. Prioridad 🟠 Alto. Eje de privacidad (coherente con 08 y 28).
> No toca reglas ni backend: es **UI/copy**.

## Problema

Al unirse a un hogar (por código o en onboarding), el backend copia el perfil del usuario
(`nickname`, `photoUrl`, `phone` si es visible) y empieza a exponer sus estadísticas
(`complianceRate`, `passedCount`, `currentStreak`) a **todos los miembros**; `syncMemberProfile`
propaga en vivo cualquier cambio futuro. **En ningún punto del flujo de unión se informa de esto.**
El usuario teclea un código y aparece dentro con su PII y métricas expuestas, sin aviso ni vista previa.

Evidencia:
- `functions/src/homes/index.ts:331-350` — al unirse se construye el doc de miembro con el perfil; `:1126-1175` `syncMemberProfile` propaga cambios futuros.
- `firestore.rules:189` — `members/{uid}` legible por `isCurrentMember` (incluye stats y teléfono si visible).
- Flujos de unión sin aviso: `lib/features/onboarding/presentation/widgets/home_join_form.dart` (onboarding), `lib/features/homes/presentation/home_selector_widget.dart` `_AddHomeSheet._buildJoinCode` (selector).
- Teléfono: su visibilidad ya está saneada en servidor (`functions/src/homes/member_factory.ts:64-69`); aquí el problema es **informar**, no una fuga.

## Decisión de producto (confirmada)

- **Formato: banner inline informativo.** Un bloque (icono `info_outline` + texto + acción opcional)
  **siempre visible** dentro del formulario de unión, encima del botón "Unirse". Cumple "un solo paso
  ligero" sin añadir un diálogo extra ni bloquear. (Se descartó el diálogo de confirmación por la
  fricción añadida y por tener que interceptar además el camino de auto-unión por QR.)
- **Acceso a la visibilidad del teléfono: enlace directo donde proceda.** En el **selector** (ya dentro
  de la app) un enlace "Cambiar" navega a `/profile/edit`. En el **onboarding** (donde no procede
  navegar fuera del flujo) se usa una **mención textual** ("Puedes ajustarlo en tu perfil"); el propio
  onboarding ya configura el teléfono y su visibilidad en su paso de perfil previo.
- **Sin aviso al CREAR hogar.** Fuera de alcance (YAGNI): el hallazgo se centra en la unión, que es
  donde "tecleas un código y entras". Crear hogar es un acto más deliberado y no expone a terceros.

## Estado real de la visibilidad del teléfono

`phoneVisibility` toma dos valores en el modelo (`lib/features/profile/domain/user_profile.dart:13`,
`lib/features/members/domain/member.dart:38`): `'hidden'` (default) y `'sameHomeMembers'`.
Se define un único booleano derivado para el aviso:

```
phoneShared = (phone no vacío) && (phoneVisibility == 'sameHomeMembers')
```

- **Selector:** se lee del perfil real en Firestore vía `userProfileProvider(uid)`.
- **Onboarding:** se lee del estado del onboarding (`onboarding_state.dart`):
  `vm.phoneVisible && (vm.phoneNumber?.trim().isNotEmpty ?? false)`. No se toca Firestore.

El copy **nunca promete** mostrar el teléfono si no se va a compartir: con `phoneShared == false`
dice explícitamente que permanece oculto.

## Alcance

**Solo cliente Flutter + ARB.** Sin backend, sin reglas, sin cambios de modelo. Un widget nuevo y su
integración en las dos entradas de unión, más 5 claves i18n.

## Cambios

### 1. Componente nuevo: `JoinPrivacyNotice`

`lib/features/homes/presentation/widgets/join_privacy_notice.dart` — widget **puro y sin estado**
(no lee providers; recibe todo por parámetro para ser testeable de forma aislada).

```dart
class JoinPrivacyNotice extends StatelessWidget {
  const JoinPrivacyNotice({
    super.key,
    required this.phoneShared,        // teléfono se compartirá con los miembros
    this.onChangeVisibility,          // no-null → enlace "Cambiar"; null → mención textual
  });
  final bool phoneShared;
  final VoidCallback? onChangeVisibility;
}
```

Render (Material 3, dentro de un `Container`/`Card` con `cs.surfaceContainerHighest` o tono suave):
- Leading: `Icon(Icons.info_outline, color: cs.onSurfaceVariant)`.
- Texto base (siempre): `l10n.join_privacy_notice_intro`
  → "Al unirte, los miembros del hogar verán tu nombre, tu foto y tus estadísticas de tareas."
- Línea de teléfono según `phoneShared`:
  - `true` → `l10n.join_privacy_notice_phone_visible` ("Tu teléfono también será visible para ellos.")
  - `false` → `l10n.join_privacy_notice_phone_hidden` ("Tu teléfono permanece oculto.")
- Acción/aclaración de visibilidad:
  - `onChangeVisibility != null` → `TextButton`(`key: Key('join_privacy_change_visibility')`) con
    `l10n.join_privacy_notice_change` ("Cambiar") que invoca el callback.
  - `onChangeVisibility == null` → `Text(l10n.join_privacy_notice_change_hint)`
    ("Puedes ajustar la visibilidad de tu teléfono en tu perfil.").

`Key('join_privacy_notice')` en la raíz para localizar el bloque en los tests de integración.

### 2. Onboarding — `HomeJoinForm` + propagación

- `HomeJoinForm` (`home_join_form.dart`): nuevo parámetro `bool phoneShared` con **default `false`**
  (valor seguro: no promete teléfono; evita romper los call sites de test existentes). Insertar
  `JoinPrivacyNotice(phoneShared: phoneShared)` **sin** `onChangeVisibility` (mención textual) entre el
  campo de código (y su error) y la `Row` de botones Atrás/Unirse.
- `HomeChoiceStepV2` (`steps/skins/home_choice_step_v2.dart`) y su wrapper `HomeChoiceStep`
  (`steps/skins/home_choice_step.dart`): nuevo parámetro `bool phoneShared` (default `false`), propagado
  hasta el `HomeJoinForm`.
- `onboarding_flow_screen.dart`: calcula `phoneShared` del view model
  (`vm.phoneVisible && (vm.phoneNumber?.trim().isNotEmpty ?? false)`) y lo pasa a `HomeChoiceStep`.

### 3. Selector — `_AddHomeSheet._buildJoinCode`

`home_selector_widget.dart` (`_AddHomeSheet` ya es `ConsumerStatefulWidget`):
- Calcular `phoneShared` leyendo el perfil propio:
  `uid = ref.read(authProvider).whenOrNull(authenticated: (u) => u.uid)` y
  `profile = ref.watch(userProfileProvider(uid)).valueOrNull`, con
  `phoneShared = (profile?.phone?.trim().isNotEmpty ?? false) && profile?.phoneVisibility == 'sameHomeMembers'`.
  Si el perfil aún no resolvió, tratar como `phoneShared = false` (no prometer de más).
- Insertar `JoinPrivacyNotice(phoneShared: phoneShared, onChangeVisibility: …)` encima del
  `FilledButton('btn_join_submit')`. El callback **cierra el sheet** y navega a editar perfil:
  `Navigator.of(context).pop(); context.push(AppRoutes.editProfile);`.

### 4. Camino QR (documentado, no se bloquea)

Tanto en onboarding (`_onDetect`) como en el selector (`_onQrDetect`) el escaneo **auto-une** al
detectar un código válido. El banner inline vive en el modo **código**, que es el modo por defecto al
elegir "Unirse a un hogar"; el usuario lo ve antes de pasar al escáner QR. No se intercepta el
auto-join (sería el "muro" que el hallazgo pide evitar). Se deja constancia como no-objetivo.

### 5. Copy (ARB es/en/ro)

Cinco claves nuevas. Regenerar localizaciones tras editar (`flutter gen-l10n` / build de l10n).

| Clave | es | en | ro |
|---|---|---|---|
| `join_privacy_notice_intro` | Al unirte, los miembros del hogar verán tu nombre, tu foto y tus estadísticas de tareas. | When you join, the household members will see your name, photo and task stats. | Când te alături, membrii casei îți vor vedea numele, fotografia și statisticile sarcinilor. |
| `join_privacy_notice_phone_visible` | Tu teléfono también será visible para ellos. | Your phone number will also be visible to them. | Numărul tău de telefon va fi de asemenea vizibil pentru ei. |
| `join_privacy_notice_phone_hidden` | Tu teléfono permanece oculto. | Your phone number stays hidden. | Numărul tău de telefon rămâne ascuns. |
| `join_privacy_notice_change` | Cambiar | Change | Modifică |
| `join_privacy_notice_change_hint` | Puedes ajustar la visibilidad de tu teléfono en tu perfil. | You can adjust your phone visibility in your profile. | Poți ajusta vizibilitatea telefonului în profilul tău. |

## Criterios de aceptación

- [ ] El flujo de unión (onboarding y selector) muestra el aviso de transparencia antes de confirmar:
      nombre, foto y estadísticas de tareas; teléfono solo si es visible.
- [ ] El aviso refleja el estado **real** de visibilidad del teléfono (si oculto, no promete mostrarlo).
- [ ] Hay acceso a cambiar la visibilidad del teléfono desde el aviso: enlace directo a editar perfil
      en el selector; mención de dónde ajustarlo en el onboarding.
- [ ] No añade fricción excesiva: un único bloque inline, no un muro de texto, no bloquea la unión.
- [ ] Localizado es/en/ro.

## Pruebas

### Widget — `test/ui/features/homes/join_privacy_notice_test.dart`
- Texto base (`join_privacy_notice_intro`) presente **siempre**.
- `phoneShared == true` → muestra `…phone_visible`; **no** muestra `…phone_hidden`.
- `phoneShared == false` → muestra `…phone_hidden`; **no** muestra `…phone_visible` (no promete mostrarlo).
- `onChangeVisibility != null` → renderiza "Cambiar" (`join_privacy_change_visibility`) y al tocarlo
  invoca el callback exactamente una vez.
- `onChangeVisibility == null` → renderiza la mención `…change_hint` y **no** el botón "Cambiar".

### Integración en las dos entradas
- **Onboarding** (`home_choice_step` / `home_join_form`): al entrar en el modo "Unirse", el
  `JoinPrivacyNotice` (`Key('join_privacy_notice')`) está presente **antes** del botón Unirse; con
  `phoneShared` calculado del estado del onboarding (cubrir visible y oculto). Sin botón "Cambiar"
  (mención textual).
- **Selector** (`_AddHomeSheet`, modo `joinCode`): el `JoinPrivacyNotice` aparece encima de
  `btn_join_submit`, reflejando el `phoneShared` del perfil mockeado (cubrir `sameHomeMembers` y
  `hidden`); el enlace "Cambiar" está presente.

### Gates
- `flutter analyze` → sin errores en los archivos tocados.
- `flutter test test/unit/` + los tests nuevos/afectados de UI de homes y onboarding → verde
  (documentar los ~6 fallos golden ambientales preexistentes del WIP, ajenos al hallazgo).

### Verificación en dispositivo (Firebase real, dos perfiles)
1. Unirse a un hogar desde **MI_9** con teléfono **oculto** y desde el **emulador** con teléfono
   **visible**: el aviso debe diferir correctamente (oculto vs "será visible"). Capturas de ambos.
2. Tras unirse, confirmar en el **otro** dispositivo qué se ve realmente del recién llegado
   (coherencia con lo prometido: teléfono visible solo cuando se prometió). Captura.
3. Verificar el acceso a cambiar la visibilidad del teléfono desde el aviso (selector → editar perfil).

## Fuera de alcance / no-objetivos

- **Reglas y backend**: no se tocan (`firestore.rules`, `functions/`). Es UI/copy.
- **Aviso al crear hogar**: descartado.
- **Interceptar el auto-join por QR** con un muro de confirmación: descartado (sería la fricción que el
  hallazgo pide evitar); el banner ya es visible en el modo código previo.
- La pantalla de **edición de la visibilidad del teléfono** en sí (`/profile/edit`): ya existe; aquí solo
  se enlaza/menciona.

## Riesgos

- **Propagación de parámetros en onboarding**: `phoneShared` cruza tres capas
  (flow → step → form). Mantener el cálculo en un único sitio (`onboarding_flow_screen`) para no
  duplicar la lógica.
- **Perfil aún sin resolver en el selector**: `userProfileProvider` es async; el fallback a
  `phoneShared = false` evita prometer de más mientras carga.
- **i18n**: regenerar localizaciones tras editar los tres ARB; verificar que las tres claves nuevas
  compilan en `app_localizations_*.dart`.
