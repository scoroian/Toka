Eres Claude Code trabajando en la app Flutter "Toka" (proyecto Firebase: toka-dd241, rama: main).

Tu tarea es implementar y verificar la spec:
  docs/superpowers/specs/2026-04-17-home-selector-always-visible-design.md

**Bug #36:** El selector de hogar en la pantalla Hoy solo aparece cuando el usuario tiene 2+ hogares. Con un único hogar se muestra un `Text` estático y el usuario no puede crear ni unirse a otro hogar desde ahí.

---

## Flujo de trabajo obligatorio (repite hasta que la spec esté resuelta)

1. Leer la spec completa.
2. Leer `lib/features/tasks/presentation/skins/today_screen_v2.dart` y `lib/features/homes/presentation/home_selector_widget.dart`.
3. Comprobar si `TodayViewModel` expone `currentHomeId`; si no, añadirlo leyendo de `currentHomeProvider`.
4. En `today_screen_v2.dart` línea 54, reemplazar la condición ternaria por `HomeSelectorWidget(homes: vm.homes, currentHomeId: vm.currentHomeId, onSelect: vm.selectHome)`.
5. Eliminar la importación de `HomeDropdownButton` si deja de usarse.
6. Ejecutar `flutter analyze` — debe pasar sin errores.
7. Ejecutar `flutter run -d emulator-5554`.
8. Login como owner → pantalla Hoy → verificar que el selector de hogar aparece en el AppBar aunque solo haya 1 hogar.
9. Capturar pantalla:
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
10. Leer `/tmp/screen.png` y verificar visualmente que el selector está visible.
11. Tap sobre el selector (x=540, y=80 aprox.) → verificar que se abre el sheet con opciones.
12. Capturar el sheet abierto con el mismo comando de screenshot.
13. Cuando esté resuelto, marcar **Bug #36** como CORREGIDO en `toka_qa_session/QA_SESSION.md`.

---

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
