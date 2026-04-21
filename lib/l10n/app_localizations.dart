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

  /// Network error joining a home
  ///
  /// In es, this message translates to:
  /// **'Sin conexión a internet. Comprueba tu red e inténtalo de nuevo.'**
  String get onboarding_error_network;

  /// Unexpected error joining a home
  ///
  /// In es, this message translates to:
  /// **'Ha ocurrido un error inesperado. Inténtalo de nuevo.'**
  String get onboarding_error_unexpected;

  /// Permission denied error joining a home
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para unirte a este hogar.'**
  String get onboarding_error_permission_denied;

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

  /// Transfer ownership dialog title
  ///
  /// In es, this message translates to:
  /// **'Transferir propiedad del hogar'**
  String get homes_transfer_ownership_title;

  /// Transfer ownership dialog body
  ///
  /// In es, this message translates to:
  /// **'Para abandonar el hogar, selecciona quién será el nuevo propietario.'**
  String get homes_transfer_ownership_body;

  /// Transfer button label
  ///
  /// In es, this message translates to:
  /// **'Transferir'**
  String get homes_transfer_btn;

  /// Delete home dialog title
  ///
  /// In es, this message translates to:
  /// **'Eliminar hogar'**
  String get homes_delete_home_title;

  /// Delete home dialog body when sole member
  ///
  /// In es, this message translates to:
  /// **'Eres el único miembro de este hogar. Al abandonarlo, se eliminará permanentemente y no podrá recuperarse.'**
  String get homes_delete_home_body_sole;

  /// Delete button label
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get homes_delete_btn;

  /// Leave home dialog title when only frozen members exist
  ///
  /// In es, this message translates to:
  /// **'Abandonar hogar'**
  String get homes_frozen_only_title;

  /// Leave home dialog body when only frozen members exist
  ///
  /// In es, this message translates to:
  /// **'Solo hay miembros congelados. Puedes transferir la propiedad a uno de ellos o eliminar el hogar permanentemente.'**
  String get homes_frozen_only_body;

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

  /// Add home button/title
  ///
  /// In es, this message translates to:
  /// **'Añadir hogar'**
  String get homes_add_home;

  /// Create home option
  ///
  /// In es, this message translates to:
  /// **'Crear un hogar'**
  String get homes_add_create;

  /// Join home option
  ///
  /// In es, this message translates to:
  /// **'Unirse a un hogar'**
  String get homes_add_join;

  /// Join by typing code option
  ///
  /// In es, this message translates to:
  /// **'Introducir código'**
  String get homes_add_join_by_code;

  /// Join by scanning QR option
  ///
  /// In es, this message translates to:
  /// **'Escanear QR'**
  String get homes_add_join_by_qr;

  /// Create home name field hint
  ///
  /// In es, this message translates to:
  /// **'Nombre del hogar'**
  String get homes_create_name_hint;

  /// Create home confirm button
  ///
  /// In es, this message translates to:
  /// **'Crear'**
  String get homes_create_button;

  /// Join with code sheet title
  ///
  /// In es, this message translates to:
  /// **'Unirse con código'**
  String get homes_join_code_title;

  /// Join home button
  ///
  /// In es, this message translates to:
  /// **'Unirse'**
  String get homes_join_button;

  /// Max homes reached banner title
  ///
  /// In es, this message translates to:
  /// **'Límite de hogares alcanzado'**
  String get homes_max_reached_title;

  /// Max homes reached banner body
  ///
  /// In es, this message translates to:
  /// **'Ya estás en el máximo de 5 hogares posibles.'**
  String get homes_max_reached_body;

  /// Upgrade to get more home slots title
  ///
  /// In es, this message translates to:
  /// **'¿Quieres otro hogar?'**
  String get homes_upgrade_title;

  /// Upgrade banner body
  ///
  /// In es, this message translates to:
  /// **'Suscríbete a Premium para desbloquear un cupo adicional.'**
  String get homes_upgrade_body;

  /// Upgrade banner action button
  ///
  /// In es, this message translates to:
  /// **'Ver planes'**
  String get homes_upgrade_button;

  /// No available slots error
  ///
  /// In es, this message translates to:
  /// **'No tienes cupos disponibles'**
  String get homes_error_no_slots;

  /// Invalid invite code error
  ///
  /// In es, this message translates to:
  /// **'Código inválido'**
  String get homes_error_invalid_code;

  /// Expired invite code error
  ///
  /// In es, this message translates to:
  /// **'El código ha expirado'**
  String get homes_error_expired_code;

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

  /// Snackbar shown when tapping disabled Hecho button before due date
  ///
  /// In es, this message translates to:
  /// **'El botón \'\'Hecho\'\' estará activo el {date}'**
  String today_hecho_not_yet(String date);

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

  /// No home empty state title
  ///
  /// In es, this message translates to:
  /// **'Sin hogar'**
  String get today_no_home_title;

  /// No home empty state body
  ///
  /// In es, this message translates to:
  /// **'Crea un hogar o únete a uno para empezar a gestionar las tareas'**
  String get today_no_home_body;

  /// No home empty state title in history screen
  ///
  /// In es, this message translates to:
  /// **'Sin historial'**
  String get history_no_home_title;

  /// No home empty state body in history screen
  ///
  /// In es, this message translates to:
  /// **'Crea un hogar o únete a uno para ver tu historial'**
  String get history_no_home_body;

  /// No home empty state title in all-tasks screen
  ///
  /// In es, this message translates to:
  /// **'Sin tareas'**
  String get tasks_no_home_title;

  /// No home empty state body in all-tasks screen
  ///
  /// In es, this message translates to:
  /// **'Crea un hogar o únete a uno para gestionar tareas'**
  String get tasks_no_home_body;

  /// No home empty state title in members screen
  ///
  /// In es, this message translates to:
  /// **'Sin miembros'**
  String get members_no_home_title;

  /// No home empty state body in members screen
  ///
  /// In es, this message translates to:
  /// **'Crea un hogar o únete a uno para ver los miembros'**
  String get members_no_home_body;

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

  /// Message shown when passing turn has negligible compliance impact (< 1 percentage point)
  ///
  /// In es, this message translates to:
  /// **'El impacto en tu cumplimiento será mínimo.'**
  String get pass_turn_minimal_impact;

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

  /// Scan QR button label
  ///
  /// In es, this message translates to:
  /// **'Escanear QR'**
  String get invite_sheet_scan_qr;

  /// QR scanner hint
  ///
  /// In es, this message translates to:
  /// **'Apunta la cámara al código QR'**
  String get invite_sheet_qr_hint;

  /// Code copied snackbar
  ///
  /// In es, this message translates to:
  /// **'Código copiado'**
  String get invite_sheet_code_copied;

  /// Invite code expiry date label
  ///
  /// In es, this message translates to:
  /// **'Expira el {date}'**
  String invite_code_expires_at(String date);

  /// Regenerate invite code button
  ///
  /// In es, this message translates to:
  /// **'Regenerar código'**
  String get invite_code_regenerate;

  /// Expired invite code error message
  ///
  /// In es, this message translates to:
  /// **'Este código ha caducado. El propietario debe generar uno nuevo.'**
  String get invite_code_expired_error;

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

  /// Button: promote member to admin
  ///
  /// In es, this message translates to:
  /// **'Hacer administrador'**
  String get member_profile_promote_admin;

  /// Button: demote admin to member
  ///
  /// In es, this message translates to:
  /// **'Quitar administrador'**
  String get member_profile_demote_admin;

  /// Confirm promote to admin
  ///
  /// In es, this message translates to:
  /// **'¿Hacer administrador a {name} en este hogar?'**
  String member_profile_promote_admin_confirm(String name);

  /// Confirm demote from admin
  ///
  /// In es, this message translates to:
  /// **'¿Quitar el rol de administrador a {name}?'**
  String member_profile_demote_admin_confirm(String name);

  /// Success: promoted to admin
  ///
  /// In es, this message translates to:
  /// **'Miembro ascendido a administrador'**
  String get member_profile_promoted_ok;

  /// Success: demoted from admin
  ///
  /// In es, this message translates to:
  /// **'Administrador degradado a miembro'**
  String get member_profile_demoted_ok;

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

  /// Payer cannot leave or be removed while Premium is active
  ///
  /// In es, this message translates to:
  /// **'No puedes expulsar ni salir del hogar mientras seas el pagador de la suscripción Premium activa. Cancela la suscripción primero o espera a que expire.'**
  String get members_error_payer_locked;

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

  /// Account settings section
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get settings_section_account;

  /// Edit profile option
  ///
  /// In es, this message translates to:
  /// **'Editar perfil'**
  String get settings_edit_profile;

  /// Change password option
  ///
  /// In es, this message translates to:
  /// **'Cambiar contraseña'**
  String get settings_change_password;

  /// Delete account option
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuenta'**
  String get settings_delete_account;

  /// Language settings
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get settings_section_language;

  /// Settings section title for appearance/theme options
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get appearance;

  /// Light theme option label
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get theme_light;

  /// Dark theme option label
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get theme_dark;

  /// System theme option label
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get theme_system;

  /// Notifications settings
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get settings_section_notifications;

  /// Privacy settings section
  ///
  /// In es, this message translates to:
  /// **'Privacidad'**
  String get settings_section_privacy;

  /// Phone visibility option
  ///
  /// In es, this message translates to:
  /// **'Visibilidad del teléfono'**
  String get settings_phone_visibility;

  /// Subscription section
  ///
  /// In es, this message translates to:
  /// **'Suscripción'**
  String get settings_section_subscription;

  /// View current plan
  ///
  /// In es, this message translates to:
  /// **'Ver plan actual'**
  String get settings_view_plan;

  /// Restore purchases
  ///
  /// In es, this message translates to:
  /// **'Restaurar compras'**
  String get settings_restore_purchases;

  /// Manage subscription
  ///
  /// In es, this message translates to:
  /// **'Gestionar suscripción'**
  String get settings_manage_subscription;

  /// Home settings section
  ///
  /// In es, this message translates to:
  /// **'Hogar'**
  String get settings_section_home;

  /// Home settings
  ///
  /// In es, this message translates to:
  /// **'Ajustes del hogar'**
  String get settings_home_settings;

  /// Invite code
  ///
  /// In es, this message translates to:
  /// **'Código de invitación'**
  String get settings_invite_code;

  /// Leave home option
  ///
  /// In es, this message translates to:
  /// **'Abandonar hogar'**
  String get settings_leave_home;

  /// Close home option
  ///
  /// In es, this message translates to:
  /// **'Cerrar hogar'**
  String get settings_close_home;

  /// About section
  ///
  /// In es, this message translates to:
  /// **'Acerca de'**
  String get settings_section_about;

  /// App version
  ///
  /// In es, this message translates to:
  /// **'Versión de la app'**
  String get settings_app_version;

  /// Terms of use
  ///
  /// In es, this message translates to:
  /// **'Términos de uso'**
  String get settings_terms;

  /// Privacy policy
  ///
  /// In es, this message translates to:
  /// **'Política de privacidad'**
  String get settings_privacy_policy;

  /// Sign out button
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get settings_sign_out;

  /// Sign out confirmation dialog title
  ///
  /// In es, this message translates to:
  /// **'¿Cerrar sesión?'**
  String get settings_sign_out_confirm;

  /// Free plan label
  ///
  /// In es, this message translates to:
  /// **'Plan gratuito'**
  String get settings_plan_free;

  /// Premium plan label
  ///
  /// In es, this message translates to:
  /// **'Plan Premium'**
  String get settings_plan_premium;

  /// No description provided for @tasks_title.
  ///
  /// In es, this message translates to:
  /// **'Tareas'**
  String get tasks_title;

  /// No description provided for @tasks_empty_title.
  ///
  /// In es, this message translates to:
  /// **'Sin tareas'**
  String get tasks_empty_title;

  /// No description provided for @tasks_empty_body.
  ///
  /// In es, this message translates to:
  /// **'Crea tu primera tarea para empezar'**
  String get tasks_empty_body;

  /// No description provided for @tasks_empty_cta.
  ///
  /// In es, this message translates to:
  /// **'Crear primera tarea'**
  String get tasks_empty_cta;

  /// No description provided for @tasks_create_title.
  ///
  /// In es, this message translates to:
  /// **'Crear tarea'**
  String get tasks_create_title;

  /// No description provided for @tasks_edit_title.
  ///
  /// In es, this message translates to:
  /// **'Editar tarea'**
  String get tasks_edit_title;

  /// No description provided for @tasks_field_visual.
  ///
  /// In es, this message translates to:
  /// **'Icono o emoji'**
  String get tasks_field_visual;

  /// No description provided for @tasks_field_title_hint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Fregar los platos'**
  String get tasks_field_title_hint;

  /// No description provided for @tasks_field_description_hint.
  ///
  /// In es, this message translates to:
  /// **'Descripción (opcional)'**
  String get tasks_field_description_hint;

  /// No description provided for @tasks_field_recurrence.
  ///
  /// In es, this message translates to:
  /// **'Recurrencia'**
  String get tasks_field_recurrence;

  /// No description provided for @tasks_field_assignment_mode.
  ///
  /// In es, this message translates to:
  /// **'Modo de asignación'**
  String get tasks_field_assignment_mode;

  /// No description provided for @tasks_field_difficulty.
  ///
  /// In es, this message translates to:
  /// **'Dificultad'**
  String get tasks_field_difficulty;

  /// No description provided for @tasks_assignment_basic_rotation.
  ///
  /// In es, this message translates to:
  /// **'Rotación básica'**
  String get tasks_assignment_basic_rotation;

  /// No description provided for @tasks_assignment_smart.
  ///
  /// In es, this message translates to:
  /// **'Distribución inteligente'**
  String get tasks_assignment_smart;

  /// No description provided for @tasks_assignment_members.
  ///
  /// In es, this message translates to:
  /// **'Miembros asignados'**
  String get tasks_assignment_members;

  /// No description provided for @tasks_recurrence_every.
  ///
  /// In es, this message translates to:
  /// **'Cada'**
  String get tasks_recurrence_every;

  /// No description provided for @tasks_recurrence_hours.
  ///
  /// In es, this message translates to:
  /// **'horas'**
  String get tasks_recurrence_hours;

  /// No description provided for @tasks_recurrence_days.
  ///
  /// In es, this message translates to:
  /// **'días'**
  String get tasks_recurrence_days;

  /// No description provided for @tasks_recurrence_start_time.
  ///
  /// In es, this message translates to:
  /// **'Hora inicio'**
  String get tasks_recurrence_start_time;

  /// No description provided for @tasks_recurrence_end_time.
  ///
  /// In es, this message translates to:
  /// **'Hora fin (opcional)'**
  String get tasks_recurrence_end_time;

  /// No description provided for @tasks_recurrence_time.
  ///
  /// In es, this message translates to:
  /// **'Hora'**
  String get tasks_recurrence_time;

  /// No description provided for @tasks_recurrence_day_of_month.
  ///
  /// In es, this message translates to:
  /// **'Día del mes'**
  String get tasks_recurrence_day_of_month;

  /// No description provided for @tasks_recurrence_week_of_month.
  ///
  /// In es, this message translates to:
  /// **'Semana del mes'**
  String get tasks_recurrence_week_of_month;

  /// No description provided for @tasks_recurrence_weekday.
  ///
  /// In es, this message translates to:
  /// **'Día de la semana'**
  String get tasks_recurrence_weekday;

  /// No description provided for @tasks_recurrence_month.
  ///
  /// In es, this message translates to:
  /// **'Mes'**
  String get tasks_recurrence_month;

  /// No description provided for @tasks_recurrence_timezone.
  ///
  /// In es, this message translates to:
  /// **'Zona horaria'**
  String get tasks_recurrence_timezone;

  /// No description provided for @tasks_recurrence_upcoming.
  ///
  /// In es, this message translates to:
  /// **'Próximas fechas'**
  String get tasks_recurrence_upcoming;

  /// No description provided for @tasks_recurrence_hourly_label.
  ///
  /// In es, this message translates to:
  /// **'Cada hora'**
  String get tasks_recurrence_hourly_label;

  /// No description provided for @tasks_recurrence_daily_label.
  ///
  /// In es, this message translates to:
  /// **'Diario'**
  String get tasks_recurrence_daily_label;

  /// No description provided for @tasks_recurrence_weekly_label.
  ///
  /// In es, this message translates to:
  /// **'Semanal'**
  String get tasks_recurrence_weekly_label;

  /// No description provided for @tasks_recurrence_monthly_fixed_label.
  ///
  /// In es, this message translates to:
  /// **'Mensual (día fijo)'**
  String get tasks_recurrence_monthly_fixed_label;

  /// No description provided for @tasks_recurrence_monthly_nth_label.
  ///
  /// In es, this message translates to:
  /// **'Mensual (Nth semana)'**
  String get tasks_recurrence_monthly_nth_label;

  /// No description provided for @tasks_recurrence_yearly_fixed_label.
  ///
  /// In es, this message translates to:
  /// **'Anual (fecha fija)'**
  String get tasks_recurrence_yearly_fixed_label;

  /// No description provided for @tasks_recurrence_yearly_nth_label.
  ///
  /// In es, this message translates to:
  /// **'Anual (Nth semana)'**
  String get tasks_recurrence_yearly_nth_label;

  /// No description provided for @tasks_section_active.
  ///
  /// In es, this message translates to:
  /// **'Activas'**
  String get tasks_section_active;

  /// No description provided for @tasks_section_frozen.
  ///
  /// In es, this message translates to:
  /// **'Congeladas'**
  String get tasks_section_frozen;

  /// Status chip shown on a frozen task detail
  ///
  /// In es, this message translates to:
  /// **'Congelada'**
  String get tasks_status_frozen;

  /// No description provided for @tasks_action_edit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get tasks_action_edit;

  /// No description provided for @tasks_action_freeze.
  ///
  /// In es, this message translates to:
  /// **'Congelar'**
  String get tasks_action_freeze;

  /// No description provided for @tasks_action_unfreeze.
  ///
  /// In es, this message translates to:
  /// **'Descongelar'**
  String get tasks_action_unfreeze;

  /// No description provided for @tasks_action_delete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get tasks_action_delete;

  /// No description provided for @tasks_delete_confirm_title.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar tarea?'**
  String get tasks_delete_confirm_title;

  /// No description provided for @tasks_delete_confirm_body.
  ///
  /// In es, this message translates to:
  /// **'Esta acción no se puede deshacer.'**
  String get tasks_delete_confirm_body;

  /// No description provided for @tasks_delete_confirm_btn.
  ///
  /// In es, this message translates to:
  /// **'Sí, eliminar'**
  String get tasks_delete_confirm_btn;

  /// No description provided for @tasks_freeze_success.
  ///
  /// In es, this message translates to:
  /// **'Tarea congelada'**
  String get tasks_freeze_success;

  /// No description provided for @tasks_unfreeze_success.
  ///
  /// In es, this message translates to:
  /// **'Tarea activada'**
  String get tasks_unfreeze_success;

  /// No description provided for @tasks_save_error.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar la tarea'**
  String get tasks_save_error;

  /// No description provided for @tasks_detail_next_occurrences.
  ///
  /// In es, this message translates to:
  /// **'Próximas fechas'**
  String get tasks_detail_next_occurrences;

  /// No description provided for @tasks_detail_assignment_order.
  ///
  /// In es, this message translates to:
  /// **'Orden de asignación'**
  String get tasks_detail_assignment_order;

  /// No description provided for @tasks_validation_title_empty.
  ///
  /// In es, this message translates to:
  /// **'El título es obligatorio'**
  String get tasks_validation_title_empty;

  /// No description provided for @tasks_validation_title_too_long.
  ///
  /// In es, this message translates to:
  /// **'Máximo 60 caracteres'**
  String get tasks_validation_title_too_long;

  /// No description provided for @tasks_validation_no_assignees.
  ///
  /// In es, this message translates to:
  /// **'Selecciona al menos un miembro'**
  String get tasks_validation_no_assignees;

  /// No description provided for @tasks_validation_difficulty_range.
  ///
  /// In es, this message translates to:
  /// **'El peso debe estar entre 0.5 y 3.0'**
  String get tasks_validation_difficulty_range;

  /// No description provided for @tasks_validation_recurrence_required.
  ///
  /// In es, this message translates to:
  /// **'Elige un tipo de recurrencia'**
  String get tasks_validation_recurrence_required;

  /// No description provided for @weekday_mon.
  ///
  /// In es, this message translates to:
  /// **'Lunes'**
  String get weekday_mon;

  /// No description provided for @weekday_tue.
  ///
  /// In es, this message translates to:
  /// **'Martes'**
  String get weekday_tue;

  /// No description provided for @weekday_wed.
  ///
  /// In es, this message translates to:
  /// **'Miércoles'**
  String get weekday_wed;

  /// No description provided for @weekday_thu.
  ///
  /// In es, this message translates to:
  /// **'Jueves'**
  String get weekday_thu;

  /// No description provided for @weekday_fri.
  ///
  /// In es, this message translates to:
  /// **'Viernes'**
  String get weekday_fri;

  /// No description provided for @weekday_sat.
  ///
  /// In es, this message translates to:
  /// **'Sábado'**
  String get weekday_sat;

  /// No description provided for @weekday_sun.
  ///
  /// In es, this message translates to:
  /// **'Domingo'**
  String get weekday_sun;

  /// No description provided for @tasks_week_1st.
  ///
  /// In es, this message translates to:
  /// **'Primera'**
  String get tasks_week_1st;

  /// No description provided for @tasks_week_2nd.
  ///
  /// In es, this message translates to:
  /// **'Segunda'**
  String get tasks_week_2nd;

  /// No description provided for @tasks_week_3rd.
  ///
  /// In es, this message translates to:
  /// **'Tercera'**
  String get tasks_week_3rd;

  /// No description provided for @tasks_week_4th.
  ///
  /// In es, this message translates to:
  /// **'Cuarta'**
  String get tasks_week_4th;

  /// No description provided for @month_jan.
  ///
  /// In es, this message translates to:
  /// **'Enero'**
  String get month_jan;

  /// No description provided for @month_feb.
  ///
  /// In es, this message translates to:
  /// **'Febrero'**
  String get month_feb;

  /// No description provided for @month_mar.
  ///
  /// In es, this message translates to:
  /// **'Marzo'**
  String get month_mar;

  /// No description provided for @month_apr.
  ///
  /// In es, this message translates to:
  /// **'Abril'**
  String get month_apr;

  /// No description provided for @month_may.
  ///
  /// In es, this message translates to:
  /// **'Mayo'**
  String get month_may;

  /// No description provided for @month_jun.
  ///
  /// In es, this message translates to:
  /// **'Junio'**
  String get month_jun;

  /// No description provided for @month_jul.
  ///
  /// In es, this message translates to:
  /// **'Julio'**
  String get month_jul;

  /// No description provided for @month_aug.
  ///
  /// In es, this message translates to:
  /// **'Agosto'**
  String get month_aug;

  /// No description provided for @month_sep.
  ///
  /// In es, this message translates to:
  /// **'Septiembre'**
  String get month_sep;

  /// No description provided for @month_oct.
  ///
  /// In es, this message translates to:
  /// **'Octubre'**
  String get month_oct;

  /// No description provided for @month_nov.
  ///
  /// In es, this message translates to:
  /// **'Noviembre'**
  String get month_nov;

  /// No description provided for @month_dec.
  ///
  /// In es, this message translates to:
  /// **'Diciembre'**
  String get month_dec;

  /// No description provided for @tasks_selection_count.
  ///
  /// In es, this message translates to:
  /// **'{count} seleccionadas'**
  String tasks_selection_count(int count);

  /// No description provided for @tasks_bulk_freeze.
  ///
  /// In es, this message translates to:
  /// **'Congelar'**
  String get tasks_bulk_freeze;

  /// No description provided for @tasks_bulk_delete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get tasks_bulk_delete;

  /// No description provided for @tasks_bulk_delete_confirm_title.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar {count} tareas?'**
  String tasks_bulk_delete_confirm_title(int count);

  /// No description provided for @tasks_bulk_delete_confirm_body.
  ///
  /// In es, this message translates to:
  /// **'Esta acción no se puede deshacer.'**
  String get tasks_bulk_delete_confirm_body;

  /// No description provided for @history_rate_button.
  ///
  /// In es, this message translates to:
  /// **'Valorar'**
  String get history_rate_button;

  /// No description provided for @history_rate_sheet_title.
  ///
  /// In es, this message translates to:
  /// **'Valorar tarea'**
  String get history_rate_sheet_title;

  /// No description provided for @history_rate_score_label.
  ///
  /// In es, this message translates to:
  /// **'Puntuación: {score}'**
  String history_rate_score_label(String score);

  /// No description provided for @history_rate_note_hint.
  ///
  /// In es, this message translates to:
  /// **'Nota privada (opcional)'**
  String get history_rate_note_hint;

  /// No description provided for @history_rate_submit.
  ///
  /// In es, this message translates to:
  /// **'Enviar valoración'**
  String get history_rate_submit;

  /// No description provided for @member_profile_overflow_tasks_title.
  ///
  /// In es, this message translates to:
  /// **'Más tareas asignadas'**
  String get member_profile_overflow_tasks_title;

  /// No description provided for @member_profile_manage_role.
  ///
  /// In es, this message translates to:
  /// **'Gestionar rol'**
  String get member_profile_manage_role;

  /// No description provided for @member_profile_role_manage_unavailable.
  ///
  /// In es, this message translates to:
  /// **'Gestión de roles disponible próximamente'**
  String get member_profile_role_manage_unavailable;

  /// No description provided for @today_home_selector_create.
  ///
  /// In es, this message translates to:
  /// **'Crear hogar'**
  String get today_home_selector_create;

  /// No description provided for @today_home_selector_join.
  ///
  /// In es, this message translates to:
  /// **'Unirse con código'**
  String get today_home_selector_join;

  /// No description provided for @today_home_selector_my_homes.
  ///
  /// In es, this message translates to:
  /// **'Mis hogares'**
  String get today_home_selector_my_homes;

  /// No description provided for @tasks_fixed_time_label.
  ///
  /// In es, this message translates to:
  /// **'Hora fija'**
  String get tasks_fixed_time_label;

  /// No description provided for @tasks_fixed_time_pick.
  ///
  /// In es, this message translates to:
  /// **'Elegir hora'**
  String get tasks_fixed_time_pick;

  /// No description provided for @tasks_apply_today_label.
  ///
  /// In es, this message translates to:
  /// **'Crear ocurrencia para hoy'**
  String get tasks_apply_today_label;

  /// No description provided for @tasks_upcoming_preview_title.
  ///
  /// In es, this message translates to:
  /// **'Próximas 3 fechas'**
  String get tasks_upcoming_preview_title;

  /// No description provided for @tasks_upcoming_preview_assignee.
  ///
  /// In es, this message translates to:
  /// **'→ {name}'**
  String tasks_upcoming_preview_assignee(String name);

  /// No description provided for @tasks_assignment_drag_hint.
  ///
  /// In es, this message translates to:
  /// **'Arrastra para reordenar'**
  String get tasks_assignment_drag_hint;

  /// No description provided for @history_event_missed.
  ///
  /// In es, this message translates to:
  /// **'{name} no completó'**
  String history_event_missed(String name);

  /// No description provided for @history_filter_missed.
  ///
  /// In es, this message translates to:
  /// **'Vencidas'**
  String get history_filter_missed;

  /// No description provided for @task_on_miss_label.
  ///
  /// In es, this message translates to:
  /// **'Si vence sin completar'**
  String get task_on_miss_label;

  /// No description provided for @task_on_miss_same_assignee.
  ///
  /// In es, this message translates to:
  /// **'Mantener asignado'**
  String get task_on_miss_same_assignee;

  /// No description provided for @task_on_miss_next_rotation.
  ///
  /// In es, this message translates to:
  /// **'Rotar al siguiente'**
  String get task_on_miss_next_rotation;

  /// Hint shown below the on-miss selector when only 1 member is assigned
  ///
  /// In es, this message translates to:
  /// **'La rotación requiere al menos 2 miembros'**
  String get tasks_rotation_requires_two_members;

  /// No description provided for @task_detail_assignee.
  ///
  /// In es, this message translates to:
  /// **'Responsable'**
  String get task_detail_assignee;

  /// No description provided for @task_detail_next_due.
  ///
  /// In es, this message translates to:
  /// **'Próxima vez'**
  String get task_detail_next_due;

  /// No description provided for @task_detail_difficulty.
  ///
  /// In es, this message translates to:
  /// **'Dificultad'**
  String get task_detail_difficulty;

  /// No description provided for @task_detail_upcoming.
  ///
  /// In es, this message translates to:
  /// **'Próximas fechas'**
  String get task_detail_upcoming;

  /// Tooltip/label for the edit task button
  ///
  /// In es, this message translates to:
  /// **'Editar tarea'**
  String get editTask;

  /// Delete account confirmation dialog title
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar cuenta?'**
  String get settings_delete_account_confirm_title;

  /// Delete account confirmation dialog body
  ///
  /// In es, this message translates to:
  /// **'Esta acción es permanente e irreversible. Perderás acceso a todos tus hogares y datos.'**
  String get settings_delete_account_confirm_body;

  /// Requires recent login to delete account
  ///
  /// In es, this message translates to:
  /// **'Por seguridad, cierra sesión y vuelve a iniciarla antes de eliminar tu cuenta.'**
  String get settings_delete_requires_reauth;

  /// Button: remove member from home
  ///
  /// In es, this message translates to:
  /// **'Expulsar del hogar'**
  String get member_profile_remove_member;

  /// Confirm remove member dialog body
  ///
  /// In es, this message translates to:
  /// **'¿Expulsar a {name} del hogar? Esta acción no se puede deshacer.'**
  String member_profile_remove_member_confirm(String name);

  /// Cannot remove owner error
  ///
  /// In es, this message translates to:
  /// **'No se puede expulsar al propietario del hogar.'**
  String get error_cannot_remove_owner;

  /// Banner when Free home reached 3 active members
  ///
  /// In es, this message translates to:
  /// **'Tu plan Free permite hasta 3 miembros. Hazte Premium para añadir más.'**
  String get free_limit_members_reached;

  /// Banner when Free home reached 4 active tasks
  ///
  /// In es, this message translates to:
  /// **'Tu plan Free permite hasta 4 tareas activas.'**
  String get free_limit_tasks_reached;

  /// Banner when Free home reached 3 automatic recurring tasks
  ///
  /// In es, this message translates to:
  /// **'Tu plan Free permite hasta 3 tareas con recurrencia. Crea una puntual o hazte Premium.'**
  String get free_limit_recurring_reached;

  /// Shown in place of the Make Admin toggle on Free
  ///
  /// In es, this message translates to:
  /// **'Los roles de admin están disponibles en Premium.'**
  String get free_admins_locked_to_owner;

  /// Shown in place of the Rate button on Free
  ///
  /// In es, this message translates to:
  /// **'Las valoraciones están disponibles en Premium.'**
  String get free_reviews_disabled;

  /// Title of the upgrade bottom sheet shown when a Free user taps the gray rate star
  ///
  /// In es, this message translates to:
  /// **'Valoraciones solo en Premium'**
  String get free_reviews_upgrade_title;

  /// Body of the upgrade bottom sheet shown when a Free user taps the gray rate star
  ///
  /// In es, this message translates to:
  /// **'Actualiza a Premium para valorar las tareas completadas por otros miembros del hogar.'**
  String get free_reviews_upgrade_body;

  /// CTA that opens the paywall from Free-limit banners
  ///
  /// In es, this message translates to:
  /// **'Hazte Premium'**
  String get free_go_premium_cta;

  /// Info string shown in Members screen when Free
  ///
  /// In es, this message translates to:
  /// **'{current} / {limit} miembros — límite del plan Free'**
  String free_members_counter(int current, int limit);

  /// Title of the dialog shown when a Free user tries to unfreeze a task but is already at maxActiveTasks
  ///
  /// In es, this message translates to:
  /// **'Límite de tareas alcanzado'**
  String get free_unfreeze_blocked_title;

  /// Body of the unfreeze-blocked dialog
  ///
  /// In es, this message translates to:
  /// **'Ya tienes {current} de {limit} tareas activas en tu plan Free. Congela otra tarea antes de descongelar esta, o hazte Premium para tener más tareas activas.'**
  String free_unfreeze_blocked_body(int current, int limit);

  /// Dismiss CTA of the unfreeze-blocked dialog
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get free_unfreeze_blocked_understood;

  /// Chip label for one-time tasks
  ///
  /// In es, this message translates to:
  /// **'Puntual'**
  String get recurrence_one_time;

  /// Helper text below the Puntual chip
  ///
  /// In es, this message translates to:
  /// **'Se completa una sola vez y desaparece del listado.'**
  String get recurrence_one_time_help;
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
