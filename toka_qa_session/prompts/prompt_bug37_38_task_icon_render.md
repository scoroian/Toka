Eres Claude Code trabajando en la app Flutter "Toka" (proyecto Firebase: toka-dd241, rama: main).

Tu tarea es implementar y verificar la spec:
  docs/superpowers/specs/2026-04-17-task-icon-render-design.md

**Bug #37:** El preview en el picker de iconos siempre muestra un fondo naranja (`primaryContainer`) y el icono `Icons.task_alt` hardcodeado, sin importar qué icono haya seleccionado el usuario.

**Bug #38:** En la tarjeta de tarea de hoy y en el detalle de tarea, el visual de tipo `icon` se renderiza como `Text(task.visualValue)`, mostrando el codepoint numérico crudo (ej. `"57405 Fregar platos"`) en vez del icono Material correcto.

---

## Flujo de trabajo obligatorio (repite hasta que la spec esté resuelta)

1. Leer la spec completa.
2. Leer los archivos afectados:
   - `lib/features/tasks/presentation/widgets/task_visual_picker.dart`
   - `lib/features/tasks/presentation/skins/widgets/today_task_card_todo_v2.dart` (zona línea 190–210)
   - `lib/features/tasks/presentation/skins/task_detail_screen_v2.dart` (zona línea 95–115)
3. Crear el fichero helper `lib/features/tasks/presentation/utils/task_visual_utils.dart` con la función `taskVisualWidget(String kind, String value, {double size = 22})`:
   - Si `kind == 'icon'` y `value` es un entero válido → devolver `Icon(IconData(cp, fontFamily: 'MaterialIcons'), size: size)`.
   - En cualquier otro caso → devolver `Text(value.isNotEmpty ? value : '📋', style: TextStyle(fontSize: size * 0.9))`.
4. Corregir el preview en `task_visual_picker.dart` (líneas 72–88):
   - Fondo: `primaryContainer` solo cuando `selectedKind == 'emoji'`; `Colors.transparent` cuando es `icon`.
   - Contenido: usar `taskVisualWidget(widget.selectedKind, widget.selectedValue, size: 36)`.
5. Corregir `today_task_card_todo_v2.dart` línea 195: separar el visual del título en un `Row` usando `taskVisualWidget`.
6. Corregir `task_detail_screen_v2.dart` línea 99: reemplazar `Text(task.visualValue)` por `taskVisualWidget(task.visualKind, task.visualValue, size: 36)`.
7. Ejecutar `flutter analyze` — debe pasar sin errores.
8. Ejecutar `flutter run -d emulator-5554`.
9. Login como owner → Tareas → FAB crear tarea → tab "Icono" del picker → seleccionar cualquier icono.
10. Capturar el preview del picker:
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
11. Leer `/tmp/screen.png` y verificar que el preview muestra el icono seleccionado **sin fondo naranja**.
12. Guardar la tarea → volver a Hoy → capturar la tarjeta → verificar que muestra el icono, no un número.
13. Tap sobre la tarea → detalle → capturar → verificar que el icono aparece grande junto al título.
14. Cuando esté resuelto, marcar **Bug #37** y **Bug #38** como CORREGIDOS en `toka_qa_session/QA_SESSION.md`.

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
