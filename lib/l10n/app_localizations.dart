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
