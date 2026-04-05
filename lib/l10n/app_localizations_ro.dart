// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Romanian Moldavian Moldovan (`ro`).
class AppLocalizationsRo extends AppLocalizations {
  AppLocalizationsRo([String locale = 'ro']) : super(locale);

  @override
  String get appName => 'Toka';

  @override
  String get loading => 'Se încarcă...';

  @override
  String get error_generic => 'Ceva a mers greșit. Încearcă din nou.';

  @override
  String get retry => 'Reîncearcă';

  @override
  String get cancel => 'Anulează';

  @override
  String get confirm => 'Confirmă';

  @override
  String get save => 'Salvează';

  @override
  String get delete => 'Șterge';

  @override
  String get back => 'Înapoi';

  @override
  String get next => 'Următor';

  @override
  String get done => 'Gata';

  @override
  String get skip => 'Sari';

  @override
  String get auth_title => 'Bun venit la Toka';

  @override
  String get auth_subtitle => 'Gestionați sarcinile gospodăriei împreună';

  @override
  String get auth_google => 'Continuați cu Google';

  @override
  String get auth_apple => 'Continuați cu Apple';

  @override
  String get auth_email => 'Continuați cu email';

  @override
  String get auth_email_label => 'Adresă de email';

  @override
  String get auth_password_label => 'Parolă';

  @override
  String get auth_login => 'Autentificare';

  @override
  String get auth_register => 'Creați cont';

  @override
  String get auth_forgot_password => 'Ați uitat parola?';

  @override
  String get auth_reset_sent =>
      'V-am trimis un email pentru a vă reseta parola';

  @override
  String get onboarding_welcome => 'Bun venit';

  @override
  String get onboarding_select_language => 'Alegeți limba';

  @override
  String get onboarding_create_home => 'Creați o locuință';

  @override
  String get onboarding_join_home => 'Alăturați-vă unei locuințe';

  @override
  String get onboarding_your_name => 'Cum vă numiți?';

  @override
  String get onboarding_photo_optional => 'Adăugați o fotografie (opțional)';

  @override
  String get settings_title => 'Setări';

  @override
  String get settings_language => 'Limbă';

  @override
  String get settings_account => 'Cont';

  @override
  String get settings_privacy => 'Confidențialitate';

  @override
  String get settings_notifications => 'Notificări';

  @override
  String get settings_subscription => 'Abonament';

  @override
  String get settings_logout => 'Deconectare';

  @override
  String get language_select_title => 'Selectați limba';

  @override
  String get language_select_subtitle => 'Alegeți limba aplicației';

  @override
  String get language_saved => 'Limbă salvată';

  @override
  String get auth_or_divider => 'sau';

  @override
  String get auth_confirm_password_label => 'Confirmați parola';

  @override
  String get auth_password_show => 'Afișați parola';

  @override
  String get auth_password_hide => 'Ascundeți parola';

  @override
  String get auth_have_account => 'Aveți deja un cont? Autentificați-vă';

  @override
  String get auth_no_account => 'Nu aveți cont? Creați unul';

  @override
  String get auth_validation_email_invalid =>
      'Introduceți o adresă de email validă';

  @override
  String get auth_validation_password_min_length =>
      'Parola trebuie să aibă cel puțin 8 caractere';

  @override
  String get auth_validation_passwords_no_match => 'Parolele nu se potrivesc';

  @override
  String get auth_validation_required => 'Acest câmp este obligatoriu';

  @override
  String get auth_verify_email_title => 'Verificați emailul';

  @override
  String auth_verify_email_body(String email) {
    return 'Am trimis un link de verificare la $email. Verificați căsuța de intrare.';
  }

  @override
  String get auth_resend_email => 'Retrimiteți emailul';

  @override
  String auth_resend_cooldown(int seconds) {
    return 'Retrimiteți în ${seconds}s';
  }

  @override
  String get auth_error_network => 'Eroare de rețea. Verificați conexiunea.';

  @override
  String get auth_error_invalid_credentials => 'Email sau parolă incorecte.';

  @override
  String get auth_error_email_in_use => 'Există deja un cont cu acest email.';

  @override
  String get auth_error_user_not_found =>
      'Nu există niciun cont cu acest email.';

  @override
  String get auth_error_weak_password =>
      'Parola este prea slabă. Folosiți cel puțin 8 caractere.';

  @override
  String get auth_error_too_many_requests =>
      'Prea multe încercări. Încercați mai târziu.';

  @override
  String get auth_forgot_password_title => 'Recuperare parolă';

  @override
  String get auth_forgot_password_body =>
      'Introduceți emailul și vă vom trimite un link pentru a vă reseta parola.';

  @override
  String get auth_send_reset_link => 'Trimiteți link-ul';
}
