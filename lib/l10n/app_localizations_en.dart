// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Toka';

  @override
  String get loading => 'Loading...';

  @override
  String get error_generic => 'Something went wrong. Please try again.';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get done => 'Done';

  @override
  String get skip => 'Skip';

  @override
  String get auth_title => 'Welcome to Toka';

  @override
  String get auth_subtitle => 'Manage household tasks together';

  @override
  String get auth_google => 'Continue with Google';

  @override
  String get auth_apple => 'Continue with Apple';

  @override
  String get auth_email => 'Continue with email';

  @override
  String get auth_email_label => 'Email address';

  @override
  String get auth_password_label => 'Password';

  @override
  String get auth_login => 'Sign in';

  @override
  String get auth_register => 'Create account';

  @override
  String get auth_forgot_password => 'Forgot your password?';

  @override
  String get auth_reset_sent =>
      'We have sent you an email to reset your password';

  @override
  String get onboarding_welcome => 'Welcome';

  @override
  String get onboarding_select_language => 'Choose your language';

  @override
  String get onboarding_create_home => 'Create a home';

  @override
  String get onboarding_join_home => 'Join a home';

  @override
  String get onboarding_your_name => 'What is your name?';

  @override
  String get onboarding_photo_optional => 'Add a photo (optional)';

  @override
  String get settings_title => 'Settings';

  @override
  String get settings_language => 'Language';

  @override
  String get settings_account => 'Account';

  @override
  String get settings_privacy => 'Privacy';

  @override
  String get settings_notifications => 'Notifications';

  @override
  String get settings_subscription => 'Subscription';

  @override
  String get settings_logout => 'Sign out';

  @override
  String get language_select_title => 'Select language';

  @override
  String get language_select_subtitle => 'Choose the app language';

  @override
  String get language_saved => 'Language saved';
}
