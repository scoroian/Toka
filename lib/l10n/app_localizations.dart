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
