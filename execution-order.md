# Orden de ejecución de specs — Toka

Este documento define el orden estricto en que deben ejecutarse las specs con Claude Code. Cada spec tiene sus dependencias listadas. No saltes de orden.

---

## Diagrama de dependencias

```
spec-00 (setup)
    └── spec-01 (i18n)
            └── spec-02 (auth)
                    └── spec-03 (onboarding)
                            └── spec-04 (homes)
                                    └── spec-05 (tasks model)
                                            └── spec-06 (today screen)
                                                    └── spec-07 (completion + pass)
                                                            ├── spec-08 (members + profiles)
                                                            ├── spec-09 (history)
                                                            └── spec-10 (subscription)
                                                                    ├── spec-11 (notifications)
                                                                    ├── spec-12 (reviews + radar)
                                                                    ├── spec-13 (smart dist + vacations)
                                                                    └── spec-14 (settings + analytics)
```

---

## Tabla de ejecución

| #   | Spec        | Archivo                       | Oleada | Descripción breve                           | Deps       |
| --- | ----------- | ----------------------------- | ------ | ------------------------------------------- | ---------- |
| 0   | **spec-00** | `spec-00-project-setup.md`    | Pre    | Setup del proyecto Flutter + Firebase       | —          |
| 1   | **spec-01** | `spec-01-i18n.md`             | Pre    | i18n, ARBs, lista de idiomas desde Firebase | 00         |
| 2   | **spec-02** | `spec-02-auth.md`             | 1      | Auth: Google, Apple, email/pass, logout     | 00, 01     |
| 3   | **spec-03** | `spec-03-onboarding.md`       | 1      | Onboarding: idioma, perfil, crear/unirse    | 00, 01, 02 |
| 4   | **spec-04** | `spec-04-homes.md`            | 1      | Cuentas, hogares, selector multi-hogar      | 00→03      |
| 5   | **spec-05** | `spec-05-tasks.md`            | 1      | Modelo de tareas, CRUD, motor recurrencia   | 00→04      |
| 6   | **spec-06** | `spec-06-today-screen.md`     | 1      | Dashboard materializado, pantalla Hoy       | 00→05      |
| 7   | **spec-07** | `spec-07-completion-pass.md`  | 1      | Completar tarea, pasar turno, rotación      | 00→06      |
| 8   | **spec-08** | `spec-08-members-profiles.md` | 2      | Miembros, perfiles, privacidad, invites     | 00→07      |
| 9   | **spec-09** | `spec-09-history.md`          | 2      | Pantalla historial, paginación, filtros     | 00→07      |
| 10  | **spec-10** | `spec-10-subscription.md`     | 3      | Premium, rescate, downgrade, restauración   | 00→09      |
| 11  | **spec-11** | `spec-11-14…md` §Spec-11      | 4      | Notificaciones push, recordatorios          | 00→07      |
| 12  | **spec-12** | `spec-11-14…md` §Spec-12      | 5      | Valoraciones, notas privadas, radar         | 00→09, 10  |
| 13  | **spec-13** | `spec-11-14…md` §Spec-13      | 4      | Reparto inteligente, vacaciones             | 00→10      |
| 14  | **spec-14** | `spec-11-14…md` §Spec-14      | 5      | Ajustes, Analytics, Crashlytics, RC         | 00→13      |

---

## Cómo usar este documento con Claude Code

### Comando de inicio para cada spec

```
Lee el archivo specs/spec-XX-nombre.md y ejecuta TODOS los pasos descritos.
Cuando termines, ejecuta todos los tests y muéstrame los resultados.
Al final, muéstrame las pruebas manuales que debo hacer.
```

### Ejemplo para spec-00

```
Lee el archivo specs/spec-00-project-setup.md y crea el proyecto Flutter desde cero
con toda la configuración descrita. Sigue exactamente las instrucciones del CLAUDE.md
para la estructura de carpetas y convenciones. Al terminar, ejecuta los tests y
muéstrame las pruebas manuales requeridas.
```

### Ejemplo para spec-05

```
Lee specs/spec-05-tasks.md. Ya tenemos el proyecto configurado (spec-00 a spec-04
completadas). Implementa el modelo de tareas, el motor de recurrencia y el CRUD
completo. Usa @architecture-agent para validar el diseño antes de empezar.
Al terminar, ejecuta los tests y muéstrame las pruebas manuales requeridas.
```

---

## Qué hacer si una spec falla

1. **Tests unitarios fallan:** Claude Code debe corregir el código antes de continuar. No marcar la spec como completa con tests en rojo.

2. **Tests de integración fallan:** Verificar que los emuladores están corriendo:

   ```bash
   firebase emulators:start
   ```

   Si los emuladores están OK y los tests fallan → Claude Code debe depurar y corregir.

3. **Build falla:** Ejecutar `dart run build_runner build --delete-conflicting-outputs` y corregir conflictos antes de continuar.

4. **Spec parcialmente completada:** Si una spec es muy larga y Claude Code necesita múltiples sesiones, usar el comando:
   ```
   Continúa la spec-XX desde donde la dejaste. Los archivos ya creados son: [lista]
   ```

---

## Notas de implementación por oleada

### Oleada 1 (specs 00–07): Base funcional mínima

Al terminar la oleada 1 debes poder:

- Registrarte, hacer login y logout.
- Completar el onboarding y tener un hogar.
- Crear tareas con distintas recurrencias.
- Ver la pantalla Hoy con tus tareas.
- Completar una tarea y pasar turno.

### Oleada 2 (specs 08–09): Colaboración completa

Al terminar la oleada 2 debes poder:

- Invitar miembros a tu hogar.
- Ver perfiles con estadísticas.
- Consultar el historial de eventos con filtros.

### Oleada 3 (spec 10): Monetización

Al terminar la oleada 3 debes poder:

- Comprar Premium (sandbox).
- Ver el flujo de rescate y downgrade.
- Restaurar Premium dentro de los 30 días.

### Oleada 4 (specs 11, 13): Features avanzadas

Al terminar la oleada 4 debes poder:

- Recibir notificaciones push de tareas.
- Usar el reparto inteligente.
- Gestionar vacaciones/ausencias.

### Oleada 5 (specs 12, 14): Calidad y pulido

Al terminar la oleada 5 el producto está completo:

- Valoraciones, notas privadas y radar.
- Pantalla de ajustes completa.
- Analytics y Crashlytics instrumentados.

---

## Checklist de entrega final

Antes de considerar el producto listo para producción, verificar:

- [ ] Spec-00: Proyecto compila sin errores ni warnings.
- [ ] Spec-01: Los 3 idiomas funcionan y el cambio persiste.
- [ ] Spec-02: Auth con Google, Apple y email funciona en iOS y Android.
- [ ] Spec-03: Onboarding completo, incluyendo foto de perfil.
- [ ] Spec-04: Multi-hogar con selector en cabecera.
- [ ] Spec-05: CRUD de tareas, todos los tipos de recurrencia.
- [ ] Spec-06: Pantalla Hoy con un solo listener, skeleton, orden correcto.
- [ ] Spec-07: Completar y pasar turno con events en Firestore.
- [ ] Spec-08: Invitaciones, perfiles, privacidad de teléfono.
- [ ] Spec-09: Historial paginado con filtros.
- [ ] Spec-10: Premium completo: compra, rescate, downgrade, restauración.
- [ ] Spec-11: Notificaciones push desde backend.
- [ ] Spec-12: Valoraciones, notas privadas, radar.
- [ ] Spec-13: Reparto inteligente y vacaciones.
- [ ] Spec-14: Ajustes, Analytics, Crashlytics, Remote Config.
- [ ] Security Rules revisadas por @security-agent.
- [ ] `flutter analyze` → 0 errores.
- [ ] Todos los tests pasan: `flutter test test/`.
- [ ] Build release para iOS y Android sin errores.
