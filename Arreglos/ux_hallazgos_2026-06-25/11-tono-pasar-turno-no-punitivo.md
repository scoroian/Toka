# 11 · 🟡 Medio-Alto — Reencuadrar el diálogo de "pasar turno" (no punitivo)

> Lee primero `_CONVENCIONES.md`. Marca 🔄 En progreso en `INDICE.md` y ✅ al cerrar.

## Contexto del hallazgo
Pasar turno muestra el aviso de penalización en un **recuadro rojo de error** con "Tu cumplimiento bajará de X% a ~Y%", y el backend marca `penaltyApplied:true` **siempre**, incluso cuando el impacto redondea a 0. Mostrar el impacto antes de confirmar es correcto (regla de producto #7), pero el **registro emocional** (rojo de alarma + lenguaje de castigo + obligatoriedad) hace que delegar por un motivo legítimo (viaje, enfermedad) se sienta como "hacer trampa". Es disuasorio y culpabilizador en una app cooperativa.

## Evidencia
- `lib/features/tasks/presentation/widgets/pass_turn_dialog.dart:65-82` — recuadro con `AppColors.error` (fondo rojo, texto rojo w600).
- `lib/features/tasks/presentation/widgets/pass_turn_dialog.dart:50-55` — comentario "pasar turno SIEMPRE penaliza… el aviso debe mostrarse SIEMPRE".
- ARB: `app_es.arb:406` `pass_turn_compliance_warning`; `:425` `pass_turn_minimal_impact`; `:404` título.
- Backend: `functions/src/tasks/pass_task_turn.ts:107` (`penaltyApplied:true`).

## Objetivo
Mantener la **transparencia** del dato (mostrar el impacto antes de confirmar) pero cambiar el **encuadre**: color neutro/informativo en vez de rojo de error, y copy cooperativo ("Esta tarea pasará a {name}. Cuenta como turno cedido en tus estadísticas") en lugar de "Tu cumplimiento bajará". Para el caso de impacto ~0, no usar tono de alarma.

## Criterios de aceptación
- [ ] El aviso ya no usa color de error/alarma; usa un tono informativo (neutro/ámbar suave).
- [ ] El copy reencuadra la acción como reparto legítimo, sin perder la información del impacto real.
- [ ] El caso `pass_turn_minimal_impact` no se pinta como advertencia roja.
- [ ] Se sigue mostrando el siguiente responsable y el campo de motivo opcional.
- [ ] Localizado (es/en/ro). No se toca la lógica de penalización del backend (solo presentación), salvo decisión explícita.

## Pruebas obligatorias
### Widget / Golden
- Golden del diálogo en: impacto notable (nuevo color/copy), impacto mínimo (sin alarma), sin candidato siguiente.
- Test de que el dato de impacto sigue mostrándose antes de confirmar (regla #7 intacta).

### Verificación en dispositivo (Firebase real, dos perfiles)
1. Pasa turno de una tarea propia en MI_9 con impacto notable → captura el diálogo (debe verse informativo, no de error).
2. Caso impacto mínimo (cumplimiento alto) → captura (sin rojo de alarma).
3. Confirma que el siguiente responsable (cuenta del emulador) recibe el turno y lo ve. Captura del sync.

## Dependencias
- "Reencuadre de tono cooperativo" junto a **07**, **08**, **12**.

## Al terminar
Actualiza `INDICE.md` (✅ + fecha + nota). Lista archivos y capturas.
