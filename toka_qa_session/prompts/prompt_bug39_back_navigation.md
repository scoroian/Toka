Eres Claude Code trabajando en la app Flutter "Toka" (proyecto Firebase: toka-dd241, rama: main).

Tu tarea es implementar y verificar la spec:
  docs/superpowers/specs/2026-04-17-back-navigation-design.md

**Bug #39:** Al pulsar el botón físico BACK de Android desde cualquier tab que no sea Hoy (Historial, Miembros, Tareas, Ajustes), la app se cierra directamente en lugar de navegar primero a la pantalla Hoy. El comportamiento esperado es: primer BACK → ir a Hoy; segundo BACK desde Hoy → salir de la app.

---

## Flujo de trabajo obligatorio (repite hasta que la spec esté resuelta)

1. Leer la spec completa.
2. Leer `lib/shared/widgets/skins/main_shell_v2.dart` completo.
3. Localizar el método `build` del `MainShellV2`. El `Scaffold` actual no tiene ningún mecanismo de interceptación de BACK.
4. Extraer el cálculo de `tabIndex` a una variable local (actualmente `_tabIndex(location)` se llama dos veces; unificarlo).
5. Envolver el `Scaffold` en un `PopScope`:
   - `canPop: tabIndex == 0` — solo permite salir cuando estamos en Hoy.
   - `onPopInvokedWithResult: (didPop, _) { if (!didPop) context.go(AppRoutes.home); }` — si no salió (porque `canPop` era false), navegar a Hoy.
6. Asegurar que se usa `onPopInvokedWithResult` (no el obsoleto `onPopInvoked`).
7. Ejecutar `flutter analyze` — debe pasar sin errores.
8. Ejecutar `flutter run -d emulator-5554`.
9. Login como owner.
10. Navegar a la tab Historial (x=342, y=barra inferior).
11. Pulsar BACK con ADB:
    ```bash
    adb shell input keyevent KEYCODE_BACK
    ```
12. Capturar pantalla inmediatamente:
    ```bash
    adb exec-out screencap -p > /tmp/screen_raw.png
    python3 -c "
    from PIL import Image
    img = Image.open('/tmp/screen_raw.png')
    if max(img.size) > 1900:
        img.thumbnail((1500, 1500), Image.LANCZOS)
    img.save('/tmp/screen.png')
    " 2>/dev/null || cp /tmp/screen_raw.png /tmp/screen.png
    ```
13. Leer `/tmp/screen.png` y verificar que se está mostrando la pantalla **Hoy** (no que la app se cerró).
14. Repetir el test desde las tabs Miembros (x=540), Tareas (x=738) y Ajustes (x=937): navegar a cada tab → BACK → verificar que va a Hoy.
15. Desde Hoy, pulsar BACK → verificar que la app sale (captura mostrará el launcher de Android).
16. Cuando esté resuelto, marcar **Bug #39** como CORREGIDO en `toka_qa_session/QA_SESSION.md`.

---

## Coordenadas de tabs en la barra inferior (pantalla 1080px ancho)

| Tab | X |
|-----|---|
| Hoy | 144 |
| Historial | 342 |
| Miembros | 540 |
| Tareas | 738 |
| Ajustes | 937 |

La barra flotante está a ~68px del borde inferior de la pantalla. En pantalla 2340px de alto: y ≈ 2272.

## Cuenta de prueba
- Email: toka.qa.owner@gmail.com
- Contraseña: TokaQA2024!

## Procedimiento de login en el emulador
```bash
adb shell input tap 540 1053
adb shell input text "toka.qa.owner@gmail.com"
adb shell input tap 540 1242
adb shell input text "TokaQA2024!"
adb shell input tap 540 1441
```

Responde siempre en español.
