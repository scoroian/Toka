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

  @override
  String get onboarding_welcome_title => 'Bun venit la Toka';

  @override
  String get onboarding_welcome_subtitle =>
      'Aplicația ta cooperativă de gestionare a sarcinilor';

  @override
  String get onboarding_start => 'Începe';

  @override
  String get onboarding_language_title => 'Ce limbă preferi?';

  @override
  String get onboarding_profile_title => 'Spune-ne despre tine';

  @override
  String get onboarding_nickname_label => 'Cum te strigă lumea?';

  @override
  String get onboarding_nickname_hint => 'Porecla ta';

  @override
  String get onboarding_nickname_required => 'Porecla este obligatorie';

  @override
  String get onboarding_nickname_max_length => 'Maximum 30 de caractere';

  @override
  String get onboarding_phone_label => 'Telefon (opțional)';

  @override
  String get onboarding_phone_visible_label =>
      'Arată numărul meu membrilor locuinței';

  @override
  String get onboarding_home_choice_title => 'Ce vrei să faci?';

  @override
  String get onboarding_create_home_description =>
      'Creează-ți locuința și adaugă-ți colegii';

  @override
  String get onboarding_join_home_description =>
      'Alătură-te unei locuințe cu un cod de invitație';

  @override
  String get onboarding_home_name_label => 'Numele locuinței';

  @override
  String get onboarding_home_name_hint => 'Locuința García';

  @override
  String get onboarding_home_name_required =>
      'Numele locuinței este obligatoriu';

  @override
  String get onboarding_home_name_max_length => 'Maximum 40 de caractere';

  @override
  String get onboarding_create_home_button => 'Creează locuința';

  @override
  String get onboarding_invite_code_label => 'Cod de invitație';

  @override
  String get onboarding_invite_code_hint => '6 caractere';

  @override
  String get onboarding_invite_code_length_error =>
      'Codul trebuie să aibă 6 caractere';

  @override
  String get onboarding_join_home_button => 'Alătură-te';

  @override
  String get onboarding_error_invalid_invite => 'Cod de invitație invalid';

  @override
  String get onboarding_error_expired_invite => 'Codul de invitație a expirat';

  @override
  String get onboarding_error_no_slots =>
      'Nu mai ai locuri disponibile pentru locuințe';

  @override
  String get onboarding_add_photo => 'Adaugă fotografie';

  @override
  String get onboarding_change_photo => 'Schimbă fotografia';

  @override
  String get homes_my_homes => 'Casele mele';

  @override
  String get homes_selector_title => 'Schimbă casa';

  @override
  String get homes_settings_title => 'Setările casei';

  @override
  String get homes_name_label => 'Numele casei';

  @override
  String get homes_plan_free => 'Plan gratuit';

  @override
  String get homes_plan_premium => 'Premium';

  @override
  String homes_plan_ends(String date) {
    return 'Expiră pe $date';
  }

  @override
  String get homes_manage_subscription => 'Gestionează abonamentul';

  @override
  String get homes_members => 'Membri';

  @override
  String get homes_invite_code => 'Cod de invitație';

  @override
  String get homes_generate_code => 'Generează cod';

  @override
  String get homes_leave_home => 'Părăsește casa';

  @override
  String get homes_close_home => 'Închide casa';

  @override
  String get homes_leave_confirm_title => 'Părăsești casa?';

  @override
  String get homes_leave_confirm_body =>
      'Vei pierde accesul la sarcinile acestei case.';

  @override
  String get homes_close_confirm_title => 'Închizi casa?';

  @override
  String get homes_close_confirm_body =>
      'Toate sarcinile și membrii vor fi șterși definitiv. Această acțiune este ireversibilă.';

  @override
  String get homes_error_cannot_leave_as_owner =>
      'Transferă proprietatea înainte de a părăsi casa';

  @override
  String get homes_role_owner => 'Proprietar';

  @override
  String get homes_role_admin => 'Administrator';

  @override
  String get homes_role_member => 'Membru';

  @override
  String get homes_pending_tasks_badge => 'Ai sarcini în așteptare';

  @override
  String get recurrenceHourly => 'Orar';

  @override
  String get recurrenceDaily => 'Zilnic';

  @override
  String get recurrenceWeekly => 'Săptămânal';

  @override
  String get recurrenceMonthly => 'Lunar';

  @override
  String get recurrenceYearly => 'Anual';

  @override
  String get today_screen_title => 'Azi';

  @override
  String today_tasks_due(int count) => '$count sarcini pentru azi';

  @override
  String today_tasks_done_today(int count) => '$count finalizate azi';

  @override
  String get today_section_todo => 'De făcut';

  @override
  String get today_section_done => 'Finalizate';

  @override
  String get today_overdue => 'Întârziată';

  @override
  String today_due_today(String time) => 'Azi $time';

  @override
  String today_due_weekday(String weekday, String time) => '$weekday $time';

  @override
  String today_done_by(String name, String time) =>
      'Finalizată de $name la $time';

  @override
  String get today_btn_done => 'Gata';

  @override
  String get today_btn_pass => 'Pasă';

  @override
  String get today_empty_title => 'Nicio sarcină pentru azi';

  @override
  String get today_empty_body => 'Toate sarcinile sunt la zi';
}
