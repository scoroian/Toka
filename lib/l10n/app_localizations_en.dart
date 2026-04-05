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

  @override
  String get auth_or_divider => 'or';

  @override
  String get auth_confirm_password_label => 'Confirm password';

  @override
  String get auth_password_show => 'Show password';

  @override
  String get auth_password_hide => 'Hide password';

  @override
  String get auth_have_account => 'Already have an account? Sign in';

  @override
  String get auth_no_account => 'Don\'t have an account? Create one';

  @override
  String get auth_validation_email_invalid => 'Enter a valid email address';

  @override
  String get auth_validation_password_min_length =>
      'Password must be at least 8 characters';

  @override
  String get auth_validation_passwords_no_match => 'Passwords do not match';

  @override
  String get auth_validation_required => 'This field is required';

  @override
  String get auth_verify_email_title => 'Verify your email';

  @override
  String auth_verify_email_body(String email) {
    return 'We sent a verification link to $email. Check your inbox.';
  }

  @override
  String get auth_resend_email => 'Resend email';

  @override
  String auth_resend_cooldown(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get auth_error_network => 'Network error. Check your connection.';

  @override
  String get auth_error_invalid_credentials => 'Incorrect email or password.';

  @override
  String get auth_error_email_in_use =>
      'An account with this email already exists.';

  @override
  String get auth_error_user_not_found => 'No account with this email.';

  @override
  String get auth_error_weak_password =>
      'Password is too weak. Use at least 8 characters.';

  @override
  String get auth_error_too_many_requests =>
      'Too many attempts. Please try again later.';

  @override
  String get auth_forgot_password_title => 'Reset password';

  @override
  String get auth_forgot_password_body =>
      'Enter your email and we\'ll send you a link to reset your password.';

  @override
  String get auth_send_reset_link => 'Send reset link';

  @override
  String get onboarding_welcome_title => 'Welcome to Toka';

  @override
  String get onboarding_welcome_subtitle =>
      'Your cooperative household task app';

  @override
  String get onboarding_start => 'Get started';

  @override
  String get onboarding_language_title => 'Which language do you prefer?';

  @override
  String get onboarding_profile_title => 'Tell us about you';

  @override
  String get onboarding_nickname_label => 'What do people call you?';

  @override
  String get onboarding_nickname_hint => 'Your nickname';

  @override
  String get onboarding_nickname_required => 'Nickname is required';

  @override
  String get onboarding_nickname_max_length => 'Maximum 30 characters';

  @override
  String get onboarding_phone_label => 'Phone (optional)';

  @override
  String get onboarding_phone_visible_label =>
      'Show my phone to household members';

  @override
  String get onboarding_home_choice_title => 'What would you like to do?';

  @override
  String get onboarding_create_home_description =>
      'Create your home and add your housemates';

  @override
  String get onboarding_join_home_description =>
      'Join a home with an invitation code';

  @override
  String get onboarding_home_name_label => 'Home name';

  @override
  String get onboarding_home_name_hint => 'The García Home';

  @override
  String get onboarding_home_name_required => 'Home name is required';

  @override
  String get onboarding_home_name_max_length => 'Maximum 40 characters';

  @override
  String get onboarding_create_home_button => 'Create home';

  @override
  String get onboarding_invite_code_label => 'Invitation code';

  @override
  String get onboarding_invite_code_hint => '6 characters';

  @override
  String get onboarding_invite_code_length_error => 'Code must be 6 characters';

  @override
  String get onboarding_join_home_button => 'Join';

  @override
  String get onboarding_error_invalid_invite => 'Invalid invitation code';

  @override
  String get onboarding_error_expired_invite => 'Invitation code has expired';

  @override
  String get onboarding_error_no_slots => 'No home slots available';

  @override
  String get onboarding_add_photo => 'Add photo';

  @override
  String get onboarding_change_photo => 'Change photo';
}
