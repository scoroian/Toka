# 16 · 🟡 Medio — El paywall debe explicar a quién beneficia la compra y el rol de pagador

> Lee primero `_CONVENCIONES.md`. Marca 🔄 En progreso en `INDICE.md` y ✅ al cerrar.

## Contexto del hallazgo
El paywall de hogar no indica que lo que compras beneficia al **hogar entero** ni que **tú quedas como pagador** (`currentPayerUid`), un rol con implicaciones (no puedes ser expulsado mientras haya Premium vigente; gestionas la facturación). El usuario decide la compra sin entender el alcance ni el rol que asume. Solo lo descubre, ya comprado, en la pantalla de gestión.

## Evidencia
- `lib/features/subscription/presentation/skins/paywall_screen_v2.dart` — no comunica beneficiario ni rol de pagador.
- `lib/features/subscription/presentation/widgets/plan_summary_card.dart:417-438` — el rol de pagador solo aparece tras comprar (gestión).
- Reglas de negocio (CLAUDE.md): Premium por hogar (#1); el pagador no puede ser expulsado con Premium vigente (#5).

## Objetivo
Añadir al paywall de hogar un texto claro: "Esta suscripción es para **todo el hogar {nombre}**. Tú serás el responsable de la facturación (pagador)." Y, como confianza, mencionar la protección del pagador (no puede ser expulsado mientras haya Premium vigente). Sin saturar el paywall.

## Criterios de aceptación
- [ ] El paywall de hogar deja claro el **beneficiario** (el hogar) y el **rol de pagador** que asume el comprador.
- [ ] Se comunica como garantía la protección del pagador (regla #5), de forma breve.
- [ ] Localizado (es/en/ro). No interfiere con los precios/copys del prompt **05**.

## Pruebas obligatorias
### Widget / Golden
- Golden del paywall tiered mostrando el texto de beneficiario/pagador.
- Test de que el nombre del hogar se interpola correctamente.

### Verificación en dispositivo (Firebase real)
1. Abre el paywall de hogar desde un hogar concreto (MI_9): el texto debe nombrar al hogar y explicar el rol de pagador. Captura.
2. (Si llegas a comprar en entorno de prueba) verifica coherencia con la pantalla de gestión que muestra el pagador. Captura. (App Check/IAP: ver `_CONVENCIONES.md §6`.)

## Dependencias
- Coordinar ARB con **05** y **06**.

## Al terminar
Actualiza `INDICE.md` (✅ + fecha + nota). Lista archivos y capturas.
