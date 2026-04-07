import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_ro.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('ro')
  ];

  /// App name
  ///
  /// In es, this message translates to:
  /// **'Toka'**
  String get appName;

  /// Generic loading message
  ///
  /// In es, this message translates to:
  /// **'Cargando...'**
  String get loading;

  /// Generic error message
  ///
  /// In es, this message translates to:
  /// **'Algo salió mal. Inténtalo de nuevo.'**
  String get error_generic;

  /// Retry button label
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// Cancel button label
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// Confirm button label
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get confirm;

  /// Save button label
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// Delete button label
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get delete;

  /// Back button label
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get back;

  /// Next button label
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get next;

  /// Done button label
  ///
  /// In es, this message translates to:
  /// **'Hecho'**
  String get done;

  /// Skip button label
  ///
  /// In es, this message translates to:
  /// **'Omitir'**
  String get skip;

  /// Auth screen title
  ///
  /// In es, this message translates to:
  /// **'Bienvenido a Toka'**
  String get auth_title;

  /// Auth screen subtitle
  ///
  /// In es, this message translates to:
  /// **'Gestiona las tareas del hogar juntos'**
  String get auth_subtitle;

  /// Google sign-in button
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get auth_google;

  /// Apple sign-in button
  ///
  /// In es, this message translates to:
  /// **'Continuar con Apple'**
  String get auth_apple;

  /// Email sign-in button
  ///
  /// In es, this message translates to:
  /// **'Continuar con email'**
  String get auth_email;

  /// Email field label
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get auth_email_label;

  /// Password field label
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get auth_password_label;

  /// Login button
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get auth_login;

  /// Register button
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get auth_register;

  /// Forgot password link
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get auth_forgot_password;

  /// Password reset email sent message
  ///
  /// In es, this message translates to:
  /// **'Te hemos enviado un correo para restablecer tu contraseña'**
  String get auth_reset_sent;

  /// Onboarding welcome title
  ///
  /// In es, this message translates to:
  /// **'Bienvenido'**
  String get onboarding_welcome;

  /// Onboarding language selection step
  ///
  /// In es, this message translates to:
  /// **'Elige tu idioma'**
  String get onboarding_select_language;

  /// Onboarding create home option
  ///
  /// In es, this message translates to:
  /// **'Crear un hogar'**
  String get onboarding_create_home;

  /// Onboarding join home option
  ///
  /// In es, this message translates to:
  /// **'Unirme a un hogar'**
  String get onboarding_join_home;

  /// Onboarding name step
  ///
  /// In es, this message translates to:
  /// **'¿Cómo te llamas?'**
  String get onboarding_your_name;

  /// Onboarding photo step
  ///
  /// In es, this message translates to:
  /// **'Añadir foto (opcional)'**
  String get onboarding_photo_optional;

  /// Settings screen title
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get settings_title;

  /// Settings language option
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get settings_language;

  /// Settings account option
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get settings_account;

  /// Settings privacy option
  ///
  /// In es, this message translates to:
  /// **'Privacidad'**
  String get settings_privacy;

  /// Settings notifications option
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get settings_notifications;

  /// Settings subscription option
  ///
  /// In es, this message translates to:
  /// **'Suscripción'**
  String get settings_subscription;

  /// Settings logout option
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get settings_logout;

  /// Language selection screen title
  ///
  /// In es, this message translates to:
  /// **'Seleccionar idioma'**
  String get language_select_title;

  /// Language selection screen subtitle
  ///
  /// In es, this message translates to:
  /// **'Elige el idioma de la aplicación'**
  String get language_select_subtitle;

  /// Confirmation message after saving language
  ///
  /// In es, this message translates to:
  /// **'Idioma guardado'**
  String get language_saved;

  /// Divider between social and email auth
  ///
  /// In es, this message translates to:
  /// **'o'**
  String get auth_or_divider;

  /// Confirm password field label
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get auth_confirm_password_label;

  /// Show password tooltip
  ///
  /// In es, this message translates to:
  /// **'Mostrar contraseña'**
  String get auth_password_show;

  /// Hide password tooltip
  ///
  /// In es, this message translates to:
  /// **'Ocultar contraseña'**
  String get auth_password_hide;

  /// Link to login from register
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta? Inicia sesión'**
  String get auth_have_account;

  /// Link to register from login
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta? Crear cuenta'**
  String get auth_no_account;

  /// Email validation error
  ///
  /// In es, this message translates to:
  /// **'Introduce un email válido'**
  String get auth_validation_email_invalid;

  /// Password length validation error
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe tener al menos 8 caracteres'**
  String get auth_validation_password_min_length;

  /// Password match validation error
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden'**
  String get auth_validation_passwords_no_match;

  /// Required field validation error
  ///
  /// In es, this message translates to:
  /// **'Este campo es obligatorio'**
  String get auth_validation_required;

  /// Verify email screen title
  ///
  /// In es, this message translates to:
  /// **'Verifica tu email'**
  String get auth_verify_email_title;

  /// Verify email body
  ///
  /// In es, this message translates to:
  /// **'Hemos enviado un enlace de verificación a {email}. Revisa tu bandeja de entrada.'**
  String auth_verify_email_body(String email);

  /// Resend verification email button
  ///
  /// In es, this message translates to:
  /// **'Reenviar email'**
  String get auth_resend_email;

  /// Resend cooldown message
  ///
  /// In es, this message translates to:
  /// **'Reenviar en {seconds}s'**
  String auth_resend_cooldown(int seconds);

  /// Network auth error
  ///
  /// In es, this message translates to:
  /// **'Error de red. Comprueba tu conexión.'**
  String get auth_error_network;

  /// Invalid credentials error
  ///
  /// In es, this message translates to:
  /// **'Email o contraseña incorrectos.'**
  String get auth_error_invalid_credentials;

  /// Email already in use error
  ///
  /// In es, this message translates to:
  /// **'Ya existe una cuenta con este email.'**
  String get auth_error_email_in_use;

  /// User not found error
  ///
  /// In es, this message translates to:
  /// **'No existe una cuenta con este email.'**
  String get auth_error_user_not_found;

  /// Weak password error
  ///
  /// In es, this message translates to:
  /// **'La contraseña es demasiado débil. Usa al menos 8 caracteres.'**
  String get auth_error_weak_password;

  /// Too many requests error
  ///
  /// In es, this message translates to:
  /// **'Demasiados intentos. Inténtalo más tarde.'**
  String get auth_error_too_many_requests;

  /// Forgot password screen title
  ///
  /// In es, this message translates to:
  /// **'Recuperar contraseña'**
  String get auth_forgot_password_title;

  /// Forgot password instructions
  ///
  /// In es, this message translates to:
  /// **'Introduce tu email y te enviaremos un enlace para restablecer tu contraseña.'**
  String get auth_forgot_password_body;

  /// Send reset link button
  ///
  /// In es, this message translates to:
  /// **'Enviar enlace'**
  String get auth_send_reset_link;

  /// Onboarding step 1 title
  ///
  /// In es, this message translates to:
  /// **'Bienvenido a Toka'**
  String get onboarding_welcome_title;

  /// Onboarding step 1 subtitle
  ///
  /// In es, this message translates to:
  /// **'Tu app cooperativa de tareas del hogar'**
  String get onboarding_welcome_subtitle;

  /// Onboarding start button
  ///
  /// In es, this message translates to:
  /// **'Empezar'**
  String get onboarding_start;

  /// Onboarding step 2 title
  ///
  /// In es, this message translates to:
  /// **'¿En qué idioma prefieres usar Toka?'**
  String get onboarding_language_title;

  /// Onboarding step 3 title
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos sobre ti'**
  String get onboarding_profile_title;

  /// Nickname field label
  ///
  /// In es, this message translates to:
  /// **'¿Cómo te llaman?'**
  String get onboarding_nickname_label;

  /// Nickname field hint
  ///
  /// In es, this message translates to:
  /// **'Tu apodo'**
  String get onboarding_nickname_hint;

  /// Nickname required error
  ///
  /// In es, this message translates to:
  /// **'El apodo es obligatorio'**
  String get onboarding_nickname_required;

  /// Nickname max length error
  ///
  /// In es, this message translates to:
  /// **'Máximo 30 caracteres'**
  String get onboarding_nickname_max_length;

  /// Phone field label
  ///
  /// In es, this message translates to:
  /// **'Teléfono (opcional)'**
  String get onboarding_phone_label;

  /// Phone visibility toggle label
  ///
  /// In es, this message translates to:
  /// **'Mostrar mi teléfono a miembros del hogar'**
  String get onboarding_phone_visible_label;

  /// Onboarding step 4 title
  ///
  /// In es, this message translates to:
  /// **'¿Qué quieres hacer?'**
  String get onboarding_home_choice_title;

  /// Create home option description
  ///
  /// In es, this message translates to:
  /// **'Crea tu hogar y añade a tus compañeros'**
  String get onboarding_create_home_description;

  /// Join home option description
  ///
  /// In es, this message translates to:
  /// **'Únete a un hogar con un código de invitación'**
  String get onboarding_join_home_description;

  /// Home name field label
  ///
  /// In es, this message translates to:
  /// **'Nombre del hogar'**
  String get onboarding_home_name_label;

  /// Home name hint
  ///
  /// In es, this message translates to:
  /// **'Casa de los García'**
  String get onboarding_home_name_hint;

  /// Home name required error
  ///
  /// In es, this message translates to:
  /// **'El nombre del hogar es obligatorio'**
  String get onboarding_home_name_required;

  /// Home name max length error
  ///
  /// In es, this message translates to:
  /// **'Máximo 40 caracteres'**
  String get onboarding_home_name_max_length;

  /// Create home button
  ///
  /// In es, this message translates to:
  /// **'Crear hogar'**
  String get onboarding_create_home_button;

  /// Invite code field label
  ///
  /// In es, this message translates to:
  /// **'Código de invitación'**
  String get onboarding_invite_code_label;

  /// Invite code hint
  ///
  /// In es, this message translates to:
  /// **'6 caracteres'**
  String get onboarding_invite_code_hint;

  /// Invite code length error
  ///
  /// In es, this message translates to:
  /// **'El código debe tener 6 caracteres'**
  String get onboarding_invite_code_length_error;

  /// Join home button
  ///
  /// In es, this message translates to:
  /// **'Unirme'**
  String get onboarding_join_home_button;

  /// Invalid invite code error
  ///
  /// In es, this message translates to:
  /// **'Código de invitación inválido'**
  String get onboarding_error_invalid_invite;

  /// Expired invite code error
  ///
  /// In es, this message translates to:
  /// **'El código de invitación ha expirado'**
  String get onboarding_error_expired_invite;

  /// No home slots error
  ///
  /// In es, this message translates to:
  /// **'No tienes plazas disponibles para crear más hogares'**
  String get onboarding_error_no_slots;

  /// Add photo button
  ///
  /// In es, this message translates to:
  /// **'Añadir foto'**
  String get onboarding_add_photo;

  /// Change photo button
  ///
  /// In es, this message translates to:
  /// **'Cambiar foto'**
  String get onboarding_change_photo;

  /// My homes screen title
  ///
  /// In es, this message translates to:
  /// **'Mis hogares'**
  String get homes_my_homes;

  /// Home selector sheet title
  ///
  /// In es, this message translates to:
  /// **'Cambiar hogar'**
  String get homes_selector_title;

  /// Home settings screen title
  ///
  /// In es, this message translates to:
  /// **'Ajustes del hogar'**
  String get homes_settings_title;

  /// Home name field label
  ///
  /// In es, this message translates to:
  /// **'Nombre del hogar'**
  String get homes_name_label;

  /// Free plan label
  ///
  /// In es, this message translates to:
  /// **'Plan gratuito'**
  String get homes_plan_free;

  /// Premium plan label
  ///
  /// In es, this message translates to:
  /// **'Premium'**
  String get homes_plan_premium;

  /// Premium ends date
  ///
  /// In es, this message translates to:
  /// **'Vence el {date}'**
  String homes_plan_ends(String date);

  /// Manage subscription button
  ///
  /// In es, this message translates to:
  /// **'Gestionar suscripción'**
  String get homes_manage_subscription;

  /// Members section label
  ///
  /// In es, this message translates to:
  /// **'Miembros'**
  String get homes_members;

  /// Invite code section label
  ///
  /// In es, this message translates to:
  /// **'Código de invitación'**
  String get homes_invite_code;

  /// Generate invite code button
  ///
  /// In es, this message translates to:
  /// **'Generar código'**
  String get homes_generate_code;

  /// Leave home button
  ///
  /// In es, this message translates to:
  /// **'Abandonar hogar'**
  String get homes_leave_home;

  /// Close home button (owner only)
  ///
  /// In es, this message translates to:
  /// **'Cerrar hogar'**
  String get homes_close_home;

  /// Leave home confirmation title
  ///
  /// In es, this message translates to:
  /// **'¿Abandonar hogar?'**
  String get homes_leave_confirm_title;

  /// Leave home confirmation body
  ///
  /// In es, this message translates to:
  /// **'Dejarás de tener acceso a las tareas de este hogar.'**
  String get homes_leave_confirm_body;

  /// Close home confirmation title
  ///
  /// In es, this message translates to:
  /// **'¿Cerrar hogar?'**
  String get homes_close_confirm_title;

  /// Close home confirmation body
  ///
  /// In es, this message translates to:
  /// **'Se eliminarán todas las tareas y miembros del hogar. Esta acción es irreversible.'**
  String get homes_close_confirm_body;

  /// Cannot leave as owner error
  ///
  /// In es, this message translates to:
  /// **'Transfiere la propiedad antes de abandonar el hogar'**
  String get homes_error_cannot_leave_as_owner;

  /// Owner role label
  ///
  /// In es, this message translates to:
  /// **'Propietario'**
  String get homes_role_owner;

  /// Admin role label
  ///
  /// In es, this message translates to:
  /// **'Administrador'**
  String get homes_role_admin;

  /// Member role label
  ///
  /// In es, this message translates to:
  /// **'Miembro'**
  String get homes_role_member;

  /// Pending tasks badge in home selector
  ///
  /// In es, this message translates to:
  /// **'Tienes tareas pendientes'**
  String get homes_pending_tasks_badge;

  /// Recurrence type: hourly
  ///
  /// In es, this message translates to:
  /// **'Hora'**
  String get recurrenceHourly;

  /// Recurrence type: daily
  ///
  /// In es, this message translates to:
  /// **'Día'**
  String get recurrenceDaily;

  /// Recurrence type: weekly
  ///
  /// In es, this message translates to:
  /// **'Semana'**
  String get recurrenceWeekly;

  /// Recurrence type: monthly
  ///
  /// In es, this message translates to:
  /// **'Mes'**
  String get recurrenceMonthly;

  /// Recurrence type: yearly
  ///
  /// In es, this message translates to:
  /// **'Año'**
  String get recurrenceYearly;

  /// Title of the Today screen
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get today_screen_title;

  /// Number of tasks due today
  ///
  /// In es, this message translates to:
  /// **'{count} tareas para hoy'**
  String today_tasks_due(int count);

  /// Number of tasks done today
  ///
  /// In es, this message translates to:
  /// **'{count} completadas hoy'**
  String today_tasks_done_today(int count);

  /// Section label: pending tasks
  ///
  /// In es, this message translates to:
  /// **'Por hacer'**
  String get today_section_todo;

  /// Section label: done tasks
  ///
  /// In es, this message translates to:
  /// **'Hechas'**
  String get today_section_done;

  /// Overdue chip label
  ///
  /// In es, this message translates to:
  /// **'Vencida'**
  String get today_overdue;

  /// Due today chip label
  ///
  /// In es, this message translates to:
  /// **'Hoy {time}'**
  String today_due_today(String time);

  /// Due this week chip label
  ///
  /// In es, this message translates to:
  /// **'{weekday} {time}'**
  String today_due_weekday(String weekday, String time);

  /// Done task completion label
  ///
  /// In es, this message translates to:
  /// **'Completada por {name} a las {time}'**
  String today_done_by(String name, String time);

  /// Mark task done button
  ///
  /// In es, this message translates to:
  /// **'Hecho'**
  String get today_btn_done;

  /// Pass turn button
  ///
  /// In es, this message translates to:
  /// **'Pasar'**
  String get today_btn_pass;

  /// Empty state title
  ///
  /// In es, this message translates to:
  /// **'Sin tareas para hoy'**
  String get today_empty_title;

  /// Empty state body
  ///
  /// In es, this message translates to:
  /// **'Todas las tareas están al día'**
  String get today_empty_body;

  /// Complete task confirmation body
  ///
  /// In es, this message translates to:
  /// **'¿Confirmas que has completado esta tarea?'**
  String get complete_task_dialog_body;

  /// Complete task confirm button
  ///
  /// In es, this message translates to:
  /// **'Sí, hecha ✓'**
  String get complete_task_confirm_btn;

  /// Pass turn dialog title
  ///
  /// In es, this message translates to:
  /// **'¿Pasar turno?'**
  String get pass_turn_dialog_title;

  /// Compliance drop warning
  ///
  /// In es, this message translates to:
  /// **'Tu cumplimiento bajará de {before}% a ~{after}%'**
  String pass_turn_compliance_warning(String before, String after);

  /// Next assignee label
  ///
  /// In es, this message translates to:
  /// **'El siguiente responsable será: {name}'**
  String pass_turn_next_assignee(String name);

  /// No other eligible member message
  ///
  /// In es, this message translates to:
  /// **'No hay otro miembro disponible, seguirás siendo el responsable'**
  String get pass_turn_no_candidate;

  /// Pass reason text field hint
  ///
  /// In es, this message translates to:
  /// **'Motivo (opcional)'**
  String get pass_turn_reason_hint;

  /// Pass turn confirm button
  ///
  /// In es, this message translates to:
  /// **'Pasar turno'**
  String get pass_turn_confirm_btn;

  /// Members screen title
  ///
  /// In es, this message translates to:
  /// **'Miembros'**
  String get members_title;

  /// FAB label on members screen
  ///
  /// In es, this message translates to:
  /// **'Invitar'**
  String get members_invite_fab;

  /// Active members section
  ///
  /// In es, this message translates to:
  /// **'Activos'**
  String get members_section_active;

  /// Frozen members section
  ///
  /// In es, this message translates to:
  /// **'Congelados'**
  String get members_section_frozen;

  /// Pending tasks badge on member card
  ///
  /// In es, this message translates to:
  /// **'{count} tareas pendientes'**
  String members_pending_tasks(int count);

  /// Compliance rate on member card
  ///
  /// In es, this message translates to:
  /// **'Cumplimiento: {rate}%'**
  String members_compliance(String rate);

  /// Owner role badge
  ///
  /// In es, this message translates to:
  /// **'Propietario'**
  String get members_role_badge_owner;

  /// Admin role badge
  ///
  /// In es, this message translates to:
  /// **'Admin'**
  String get members_role_badge_admin;

  /// Member role badge
  ///
  /// In es, this message translates to:
  /// **'Miembro'**
  String get members_role_badge_member;

  /// Frozen role badge
  ///
  /// In es, this message translates to:
  /// **'Congelado'**
  String get members_role_badge_frozen;

  /// Invite member sheet title
  ///
  /// In es, this message translates to:
  /// **'Invitar miembro'**
  String get invite_sheet_title;

  /// Share invite code option
  ///
  /// In es, this message translates to:
  /// **'Compartir código'**
  String get invite_sheet_share_code;

  /// Invite by email option
  ///
  /// In es, this message translates to:
  /// **'Invitar por email'**
  String get invite_sheet_by_email;

  /// Generated invite code label
  ///
  /// In es, this message translates to:
  /// **'Código de invitación'**
  String get invite_sheet_code_label;

  /// Email field hint
  ///
  /// In es, this message translates to:
  /// **'correo@ejemplo.com'**
  String get invite_sheet_email_hint;

  /// Send invite button
  ///
  /// In es, this message translates to:
  /// **'Enviar invitación'**
  String get invite_sheet_send;

  /// Copy code button
  ///
  /// In es, this message translates to:
  /// **'Copiar código'**
  String get invite_sheet_copy_code;

  /// Code copied snackbar
  ///
  /// In es, this message translates to:
  /// **'Código copiado'**
  String get invite_sheet_code_copied;

  /// Section header: home statistics
  ///
  /// In es, this message translates to:
  /// **'Estadísticas en este hogar'**
  String get member_profile_home_stats;

  /// Stats: tasks completed
  ///
  /// In es, this message translates to:
  /// **'Tareas completadas'**
  String get member_profile_tasks_completed;

  /// Stats: compliance rate
  ///
  /// In es, this message translates to:
  /// **'Cumplimiento'**
  String get member_profile_compliance;

  /// Stats: current streak
  ///
  /// In es, this message translates to:
  /// **'Racha actual'**
  String get member_profile_streak;

  /// Stats: average score
  ///
  /// In es, this message translates to:
  /// **'Puntuación media'**
  String get member_profile_avg_score;

  /// History 30 days tab
  ///
  /// In es, this message translates to:
  /// **'Últimos 30 días'**
  String get member_profile_history_30d;

  /// History 90 days tab
  ///
  /// In es, this message translates to:
  /// **'Últimos 90 días'**
  String get member_profile_history_90d;

  /// Own profile screen title
  ///
  /// In es, this message translates to:
  /// **'Mi perfil'**
  String get profile_title;

  /// Edit profile button
  ///
  /// In es, this message translates to:
  /// **'Editar perfil'**
  String get profile_edit;

  /// Global stats section title
  ///
  /// In es, this message translates to:
  /// **'Mis estadísticas globales'**
  String get profile_global_stats;

  /// Per-home stats accordion title
  ///
  /// In es, this message translates to:
  /// **'Estadísticas por hogar'**
  String get profile_per_home_stats;

  /// Access management section title
  ///
  /// In es, this message translates to:
  /// **'Gestionar acceso'**
  String get profile_access_management;

  /// Linked providers item
  ///
  /// In es, this message translates to:
  /// **'Proveedores vinculados'**
  String get profile_linked_providers;

  /// Change password item
  ///
  /// In es, this message translates to:
  /// **'Cambiar contraseña'**
  String get profile_change_password;

  /// Logout button
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get profile_logout;

  /// Nickname field label
  ///
  /// In es, this message translates to:
  /// **'Apodo'**
  String get profile_nickname_label;

  /// Bio field label
  ///
  /// In es, this message translates to:
  /// **'Bio'**
  String get profile_bio_label;

  /// Phone field label
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get profile_phone_label;

  /// Phone visibility toggle
  ///
  /// In es, this message translates to:
  /// **'Mostrar teléfono a miembros del hogar'**
  String get profile_phone_visibility_label;

  /// Profile saved snackbar
  ///
  /// In es, this message translates to:
  /// **'Perfil guardado'**
  String get profile_saved;

  /// Max members error
  ///
  /// In es, this message translates to:
  /// **'El hogar ha alcanzado el límite de miembros'**
  String get members_error_max_members;

  /// Max admins error
  ///
  /// In es, this message translates to:
  /// **'El plan gratuito solo permite 1 admin'**
  String get members_error_max_admins;

  /// Cannot remove owner error
  ///
  /// In es, this message translates to:
  /// **'No se puede eliminar al propietario del hogar'**
  String get members_error_cannot_remove_owner;

  /// History screen title
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get history_title;

  /// History filter: all events
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get history_filter_all;

  /// History filter: completed only
  ///
  /// In es, this message translates to:
  /// **'Completadas'**
  String get history_filter_completed;

  /// History filter: passed only
  ///
  /// In es, this message translates to:
  /// **'Pases'**
  String get history_filter_passed;

  /// History empty state title
  ///
  /// In es, this message translates to:
  /// **'Sin actividad'**
  String get history_empty_title;

  /// History empty state body
  ///
  /// In es, this message translates to:
  /// **'Aún no hay eventos en el historial'**
  String get history_empty_body;

  /// Completed event actor label
  ///
  /// In es, this message translates to:
  /// **'{name} completó'**
  String history_event_completed(String name);

  /// Pass turn label in event tile
  ///
  /// In es, this message translates to:
  /// **'pase de turno'**
  String get history_event_pass_turn;

  /// Pass reason label
  ///
  /// In es, this message translates to:
  /// **'Motivo: {reason}'**
  String history_event_reason(String reason);

  /// Relative time: just now
  ///
  /// In es, this message translates to:
  /// **'ahora'**
  String get history_time_now;

  /// Relative time: N minutes ago
  ///
  /// In es, this message translates to:
  /// **'hace {minutes} min'**
  String history_time_minutes_ago(int minutes);

  /// Relative time: N hours ago
  ///
  /// In es, this message translates to:
  /// **'hace {hours} h'**
  String history_time_hours_ago(int hours);

  /// Relative time: N days ago
  ///
  /// In es, this message translates to:
  /// **'hace {days} días'**
  String history_time_days_ago(int days);

  /// Load more button
  ///
  /// In es, this message translates to:
  /// **'Cargar más'**
  String get history_load_more;

  /// Premium banner title
  ///
  /// In es, this message translates to:
  /// **'Más historial con Premium'**
  String get history_premium_banner_title;

  /// Premium banner body
  ///
  /// In es, this message translates to:
  /// **'Accede a 90 días de historial'**
  String get history_premium_banner_body;

  /// Premium banner CTA button
  ///
  /// In es, this message translates to:
  /// **'Actualizar a Premium'**
  String get history_premium_banner_cta;

  /// Premium plan name
  ///
  /// In es, this message translates to:
  /// **'Premium'**
  String get subscription_premium;

  /// Free plan name
  ///
  /// In es, this message translates to:
  /// **'Gratuito'**
  String get subscription_free;

  /// Monthly billing period
  ///
  /// In es, this message translates to:
  /// **'Mensual'**
  String get subscription_monthly;

  /// Annual billing period
  ///
  /// In es, this message translates to:
  /// **'Anual'**
  String get subscription_annual;

  /// Monthly price
  ///
  /// In es, this message translates to:
  /// **'3,99 €/mes'**
  String get subscription_price_monthly;

  /// Annual price
  ///
  /// In es, this message translates to:
  /// **'29,99 €/año'**
  String get subscription_price_annual;

  /// Annual plan saving label
  ///
  /// In es, this message translates to:
  /// **'Ahorra 17,89 €'**
  String get subscription_annual_saving;

  /// Paywall screen title
  ///
  /// In es, this message translates to:
  /// **'Haz tu hogar Premium'**
  String get paywall_title;

  /// Paywall subtitle
  ///
  /// In es, this message translates to:
  /// **'Todo lo que necesitas para gestionar tu hogar sin límites'**
  String get paywall_subtitle;

  /// Primary paywall CTA (annual)
  ///
  /// In es, this message translates to:
  /// **'Empezar Premium Anual'**
  String get paywall_cta_annual;

  /// Secondary paywall CTA (monthly)
  ///
  /// In es, this message translates to:
  /// **'Plan mensual'**
  String get paywall_cta_monthly;

  /// Restore purchases link
  ///
  /// In es, this message translates to:
  /// **'Restaurar compras'**
  String get paywall_restore;

  /// Terms and privacy link
  ///
  /// In es, this message translates to:
  /// **'Ver términos y política de privacidad'**
  String get paywall_terms;

  /// Premium feature: members
  ///
  /// In es, this message translates to:
  /// **'Hasta 10 miembros por hogar'**
  String get paywall_feature_members;

  /// Premium feature: smart distribution
  ///
  /// In es, this message translates to:
  /// **'Distribución inteligente de tareas'**
  String get paywall_feature_smart;

  /// Premium feature: vacations
  ///
  /// In es, this message translates to:
  /// **'Modo vacaciones'**
  String get paywall_feature_vacations;

  /// Premium feature: reviews
  ///
  /// In es, this message translates to:
  /// **'Valoraciones privadas'**
  String get paywall_feature_reviews;

  /// Premium feature: 90-day history
  ///
  /// In es, this message translates to:
  /// **'Historial 90 días'**
  String get paywall_feature_history;

  /// Premium feature: no ads
  ///
  /// In es, this message translates to:
  /// **'Sin publicidad'**
  String get paywall_feature_no_ads;

  /// Rescue banner text with days remaining
  ///
  /// In es, this message translates to:
  /// **'Premium expira en {days} días'**
  String rescue_banner_text(int days);

  /// Rescue banner renew button
  ///
  /// In es, this message translates to:
  /// **'Renovar'**
  String get rescue_banner_renew;

  /// Subscription management screen title
  ///
  /// In es, this message translates to:
  /// **'Tu suscripción'**
  String get subscription_management_title;

  /// Active subscription status
  ///
  /// In es, this message translates to:
  /// **'Premium activo'**
  String get subscription_status_active;

  /// Cancelled but active until date
  ///
  /// In es, this message translates to:
  /// **'Cancelado — activo hasta {date}'**
  String subscription_status_cancelled(String date);

  /// Rescue state label
  ///
  /// In es, this message translates to:
  /// **'Expira en {days} días'**
  String subscription_status_rescue(int days);

  /// Free plan status
  ///
  /// In es, this message translates to:
  /// **'Plan gratuito'**
  String get subscription_status_free;

  /// Restorable until date
  ///
  /// In es, this message translates to:
  /// **'Puede restaurarse hasta {date}'**
  String subscription_status_restorable(String date);

  /// Restore premium button
  ///
  /// In es, this message translates to:
  /// **'Restaurar Premium'**
  String get subscription_restore_btn;

  /// Restore success snackbar
  ///
  /// In es, this message translates to:
  /// **'Premium restaurado correctamente'**
  String get subscription_restore_success;

  /// Restore window expired error
  ///
  /// In es, this message translates to:
  /// **'La ventana de restauración ya expiró'**
  String get subscription_restore_expired_error;

  /// Plan downgrade button
  ///
  /// In es, this message translates to:
  /// **'Planear downgrade'**
  String get subscription_plan_downgrade;

  /// Downgrade planner screen title
  ///
  /// In es, this message translates to:
  /// **'Planear downgrade'**
  String get downgrade_planner_title;

  /// Members section label
  ///
  /// In es, this message translates to:
  /// **'¿Qué miembros continuarán?'**
  String get downgrade_planner_members_section;

  /// Tasks section label
  ///
  /// In es, this message translates to:
  /// **'¿Qué tareas continuarán?'**
  String get downgrade_planner_tasks_section;

  /// Max members hint
  ///
  /// In es, this message translates to:
  /// **'Máximo 3 miembros (owner siempre incluido)'**
  String get downgrade_planner_max_members_hint;

  /// Max tasks hint
  ///
  /// In es, this message translates to:
  /// **'Máximo 4 tareas'**
  String get downgrade_planner_max_tasks_hint;

  /// Auto selection note
  ///
  /// In es, this message translates to:
  /// **'Si no decides, se aplicará selección automática'**
  String get downgrade_planner_auto_note;

  /// Save downgrade plan button
  ///
  /// In es, this message translates to:
  /// **'Guardar plan'**
  String get downgrade_planner_save;

  /// Downgrade plan saved snackbar
  ///
  /// In es, this message translates to:
  /// **'Plan de downgrade guardado'**
  String get downgrade_planner_saved;

  /// Premium feature gate title
  ///
  /// In es, this message translates to:
  /// **'Función Premium'**
  String get premium_gate_title;

  /// Premium feature gate body
  ///
  /// In es, this message translates to:
  /// **'{featureName} requiere Premium'**
  String premium_gate_body(String featureName);

  /// Premium gate upgrade button
  ///
  /// In es, this message translates to:
  /// **'Actualizar a Premium'**
  String get premium_gate_upgrade;

  /// Rescue screen title
  ///
  /// In es, this message translates to:
  /// **'Renueva tu Premium'**
  String get rescue_screen_title;

  /// Rescue screen body
  ///
  /// In es, this message translates to:
  /// **'Tu suscripción Premium expira pronto. Renueva ahora para no perder acceso a tus funciones.'**
  String get rescue_screen_body;

  /// Vacation screen title
  ///
  /// In es, this message translates to:
  /// **'Vacaciones / Ausencia'**
  String get vacation_title;

  /// Vacation toggle label
  ///
  /// In es, this message translates to:
  /// **'Estoy de vacaciones / ausente'**
  String get vacation_toggle_label;

  /// Vacation start date label
  ///
  /// In es, this message translates to:
  /// **'Fecha de inicio (opcional)'**
  String get vacation_start_date;

  /// Vacation end date label
  ///
  /// In es, this message translates to:
  /// **'Fecha de fin (opcional)'**
  String get vacation_end_date;

  /// Vacation reason label
  ///
  /// In es, this message translates to:
  /// **'Motivo (opcional)'**
  String get vacation_reason;

  /// Save vacation button
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get vacation_save;

  /// Vacation chip with end date
  ///
  /// In es, this message translates to:
  /// **'De vacaciones hasta {date}'**
  String vacation_chip_until(String date);

  /// Vacation chip without end date
  ///
  /// In es, this message translates to:
  /// **'De vacaciones'**
  String get vacation_chip_indefinite;

  /// Notification settings screen title
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get notification_settings_title;

  /// Notify on due toggle
  ///
  /// In es, this message translates to:
  /// **'Avisar al vencer'**
  String get notification_on_due_label;

  /// Notify before due toggle
  ///
  /// In es, this message translates to:
  /// **'Avisar antes de vencer'**
  String get notification_before_label;

  /// Minutes before label
  ///
  /// In es, this message translates to:
  /// **'Tiempo de antelación'**
  String get notification_minutes_before_label;

  /// Daily summary toggle
  ///
  /// In es, this message translates to:
  /// **'Resumen diario'**
  String get notification_daily_summary_label;

  /// Daily summary time label
  ///
  /// In es, this message translates to:
  /// **'Hora del resumen'**
  String get notification_summary_time_label;

  /// Silenced types section label
  ///
  /// In es, this message translates to:
  /// **'Silenciar tipos de tarea'**
  String get notification_silenced_types_label;

  /// Premium-only badge
  ///
  /// In es, this message translates to:
  /// **'Solo Premium'**
  String get notification_premium_only;

  /// 15 minutes option
  ///
  /// In es, this message translates to:
  /// **'15 minutos'**
  String get notification_15min;

  /// 30 minutes option
  ///
  /// In es, this message translates to:
  /// **'30 minutos'**
  String get notification_30min;

  /// 1 hour option
  ///
  /// In es, this message translates to:
  /// **'1 hora'**
  String get notification_1h;

  /// 2 hours option
  ///
  /// In es, this message translates to:
  /// **'2 horas'**
  String get notification_2h;

  /// Review dialog title
  ///
  /// In es, this message translates to:
  /// **'Valorar tarea'**
  String get review_dialog_title;

  /// Review score label
  ///
  /// In es, this message translates to:
  /// **'Puntuación (1-10)'**
  String get review_score_label;

  /// Review note label
  ///
  /// In es, this message translates to:
  /// **'Nota privada (opcional, máx. 300 caracteres)'**
  String get review_note_label;

  /// Submit review button
  ///
  /// In es, this message translates to:
  /// **'Enviar valoración'**
  String get review_submit;

  /// Premium required for reviews
  ///
  /// In es, this message translates to:
  /// **'Las valoraciones son exclusivas de Premium'**
  String get review_premium_required;

  /// Cannot review own task message
  ///
  /// In es, this message translates to:
  /// **'No puedes valorar tus propias tareas'**
  String get review_own_task;

  /// Radar chart section title
  ///
  /// In es, this message translates to:
  /// **'Puntos fuertes'**
  String get radar_chart_title;

  /// No radar data message
  ///
  /// In es, this message translates to:
  /// **'Sin valoraciones todavía'**
  String get radar_no_data;

  /// Overflow tasks section title
  ///
  /// In es, this message translates to:
  /// **'Otras tareas evaluadas'**
  String get radar_other_tasks;

  /// Generic review submission error
  ///
  /// In es, this message translates to:
  /// **'Error al enviar valoración'**
  String get review_submit_error;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'ro'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'ro':
      return AppLocalizationsRo();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
