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
  String get onboarding_error_network =>
      'Nu există conexiune la internet. Verifică rețeaua și încearcă din nou.';

  @override
  String get onboarding_error_unexpected =>
      'A apărut o eroare neașteptată. Încearcă din nou.';

  @override
  String get onboarding_error_permission_denied =>
      'Nu ai permisiunea de a te alătura acestei case.';

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
  String get homes_transfer_ownership_title => 'Transferă proprietatea locuinței';

  @override
  String get homes_transfer_ownership_body =>
      'Pentru a părăsi locuința, selectează cine va deveni noul proprietar.';

  @override
  String get homes_transfer_btn => 'Transferă';

  @override
  String get homes_delete_home_title => 'Șterge locuința';

  @override
  String get homes_delete_home_body_sole =>
      'Ești singurul membru. Dacă pleci, locuința va fi ștearsă permanent și nu poate fi recuperată.';

  @override
  String get homes_delete_btn => 'Șterge';

  @override
  String get homes_frozen_only_title => 'Părăsește locuința';

  @override
  String get homes_frozen_only_body =>
      'Există doar membri înghețați. Poți transfera proprietatea unuia dintre ei sau poți șterge locuința permanent.';

  @override
  String get homes_role_owner => 'Proprietar';

  @override
  String get homes_role_admin => 'Administrator';

  @override
  String get homes_role_member => 'Membru';

  @override
  String get homes_pending_tasks_badge => 'Ai sarcini în așteptare';

  @override
  String get homes_add_home => 'Adaugă cămin';

  @override
  String get homes_add_create => 'Creează un cămin';

  @override
  String get homes_add_join => 'Alătură-te unui cămin';

  @override
  String get homes_add_join_by_code => 'Introdu codul';

  @override
  String get homes_add_join_by_qr => 'Scanează QR';

  @override
  String get homes_create_name_hint => 'Numele căminului';

  @override
  String get homes_create_button => 'Creează';

  @override
  String get homes_join_code_title => 'Alătură-te cu cod';

  @override
  String get homes_join_button => 'Alătură-te';

  @override
  String get homes_max_reached_title => 'Limită de cămine atinsă';

  @override
  String get homes_max_reached_body =>
      'Ești deja în numărul maxim de 5 cămine posibile.';

  @override
  String get homes_upgrade_title => 'Vrei un alt cămin?';

  @override
  String get homes_upgrade_body =>
      'Abonează-te la Premium pentru a debloca un slot suplimentar.';

  @override
  String get homes_upgrade_button => 'Vezi planuri';

  @override
  String get homes_error_no_slots => 'Nu există locuri disponibile';

  @override
  String get homes_error_invalid_code => 'Cod invalid';

  @override
  String get homes_error_expired_code => 'Codul a expirat';

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
  String today_tasks_due(int count) {
    return '$count sarcini pentru azi';
  }

  @override
  String today_tasks_done_today(int count) {
    return '$count finalizate azi';
  }

  @override
  String get today_section_todo => 'De făcut';

  @override
  String get today_section_done => 'Finalizate';

  @override
  String get today_overdue => 'Întârziată';

  @override
  String today_due_today(String time) {
    return 'Azi $time';
  }

  @override
  String today_due_weekday(String weekday, String time) {
    return '$weekday $time';
  }

  @override
  String today_done_by(String name, String time) {
    return 'Finalizată de $name la $time';
  }

  @override
  String get today_btn_done => 'Gata';

  @override
  String get today_btn_pass => 'Pasă';

  @override
  String today_hecho_not_yet(String date) {
    return 'Butonul \'\'Gata\'\' va fi activ pe $date';
  }

  @override
  String get today_empty_title => 'Nicio sarcină pentru azi';

  @override
  String get today_empty_body => 'Toate sarcinile sunt la zi';

  @override
  String get today_no_home_title => 'Fără locuință';

  @override
  String get today_no_home_body =>
      'Creează o locuință sau alătură-te uneia pentru a gestiona sarcinile';

  @override
  String get complete_task_dialog_body =>
      'Confirmi că ai finalizat această sarcină?';

  @override
  String get complete_task_confirm_btn => 'Da, gata ✓';

  @override
  String get pass_turn_dialog_title => 'Pasezi rândul?';

  @override
  String pass_turn_compliance_warning(String before, String after) {
    return 'Respectarea ta va scădea de la $before% la ~$after%';
  }

  @override
  String pass_turn_next_assignee(String name) {
    return 'Următorul responsabil: $name';
  }

  @override
  String get pass_turn_no_candidate =>
      'Nu există alt membru disponibil, vei rămâne responsabil';

  @override
  String get pass_turn_reason_hint => 'Motiv (opțional)';

  @override
  String get pass_turn_confirm_btn => 'Pasează rândul';

  @override
  String get members_title => 'Membri';

  @override
  String get members_invite_fab => 'Invită';

  @override
  String get members_section_active => 'Activi';

  @override
  String get members_section_frozen => 'Înghețați';

  @override
  String members_pending_tasks(int count) {
    return '$count sarcini în așteptare';
  }

  @override
  String members_compliance(String rate) {
    return 'Conformitate: $rate%';
  }

  @override
  String get members_role_badge_owner => 'Proprietar';

  @override
  String get members_role_badge_admin => 'Admin';

  @override
  String get members_role_badge_member => 'Membru';

  @override
  String get members_role_badge_frozen => 'Înghețat';

  @override
  String get invite_sheet_title => 'Invită membru';

  @override
  String get invite_sheet_share_code => 'Partajează cod';

  @override
  String get invite_sheet_by_email => 'Invită prin email';

  @override
  String get invite_sheet_code_label => 'Cod de invitație';

  @override
  String get invite_sheet_email_hint => 'email@exemplu.com';

  @override
  String get invite_sheet_send => 'Trimite invitație';

  @override
  String get invite_sheet_copy_code => 'Copiază cod';

  @override
  String get invite_sheet_scan_qr => 'Scanează QR';

  @override
  String get invite_sheet_qr_hint => 'Îndreaptă camera spre codul QR';

  @override
  String get invite_sheet_code_copied => 'Cod copiat';

  @override
  String get member_profile_home_stats => 'Statistici în acest cămin';

  @override
  String get member_profile_tasks_completed => 'Sarcini finalizate';

  @override
  String get member_profile_compliance => 'Conformitate';

  @override
  String get member_profile_streak => 'Seria curentă';

  @override
  String get member_profile_avg_score => 'Scor mediu';

  @override
  String get member_profile_history_30d => 'Ultimele 30 zile';

  @override
  String get member_profile_history_90d => 'Ultimele 90 zile';

  @override
  String get member_profile_promote_admin => 'Fă administrator';

  @override
  String get member_profile_demote_admin => 'Elimină administrator';

  @override
  String member_profile_promote_admin_confirm(String name) {
    return 'Faci din $name un administrator al acestei case?';
  }

  @override
  String member_profile_demote_admin_confirm(String name) {
    return 'Elimini rolul de administrator al lui $name?';
  }

  @override
  String get member_profile_promoted_ok => 'Membru promovat la administrator';

  @override
  String get member_profile_demoted_ok => 'Administrator retrogradat la membru';

  @override
  String get profile_title => 'Profilul meu';

  @override
  String get profile_edit => 'Editează profil';

  @override
  String get profile_global_stats => 'Statisticile mele globale';

  @override
  String get profile_per_home_stats => 'Statistici pe locuință';

  @override
  String get profile_access_management => 'Gestionare acces';

  @override
  String get profile_linked_providers => 'Furnizori conectați';

  @override
  String get profile_change_password => 'Schimbă parola';

  @override
  String get profile_logout => 'Deconectare';

  @override
  String get profile_nickname_label => 'Poreclă';

  @override
  String get profile_bio_label => 'Bio';

  @override
  String get profile_phone_label => 'Telefon';

  @override
  String get profile_phone_visibility_label =>
      'Arată telefonul membrilor locuinței';

  @override
  String get profile_saved => 'Profil salvat';

  @override
  String get members_error_max_members => 'Locuința a atins limita de membri';

  @override
  String get members_error_max_admins => 'Planul gratuit permite doar 1 admin';

  @override
  String get members_error_cannot_remove_owner =>
      'Nu se poate elimina proprietarul locuinței';

  @override
  String get history_title => 'Istoric';

  @override
  String get history_filter_all => 'Toate';

  @override
  String get history_filter_completed => 'Finalizate';

  @override
  String get history_filter_passed => 'Pasări';

  @override
  String get history_empty_title => 'Nicio activitate';

  @override
  String get history_empty_body => 'Nu există încă evenimente în istoric';

  @override
  String history_event_completed(String name) {
    return '$name a finalizat';
  }

  @override
  String get history_event_pass_turn => 'pasare de tură';

  @override
  String history_event_reason(String reason) {
    return 'Motiv: $reason';
  }

  @override
  String get history_time_now => 'acum';

  @override
  String history_time_minutes_ago(int minutes) {
    return 'acum $minutes min';
  }

  @override
  String history_time_hours_ago(int hours) {
    return 'acum $hours h';
  }

  @override
  String history_time_days_ago(int days) {
    return 'acum $days zile';
  }

  @override
  String get history_load_more => 'Încarcă mai mult';

  @override
  String get history_premium_banner_title => 'Mai mult istoric cu Premium';

  @override
  String get history_premium_banner_body => 'Accesează 90 de zile de istoric';

  @override
  String get history_premium_banner_cta => 'Actualizează la Premium';

  @override
  String get subscription_premium => 'Premium';

  @override
  String get subscription_free => 'Gratuit';

  @override
  String get subscription_monthly => 'Lunar';

  @override
  String get subscription_annual => 'Anual';

  @override
  String get subscription_price_monthly => '3,99 €/lună';

  @override
  String get subscription_price_annual => '29,99 €/an';

  @override
  String get subscription_annual_saving => 'Economisești 17,89 €';

  @override
  String get paywall_title => 'Fă-ți locuința Premium';

  @override
  String get paywall_subtitle =>
      'Tot ce ai nevoie pentru a-ți gestiona locuința fără limite';

  @override
  String get paywall_cta_annual => 'Începe Premium Anual';

  @override
  String get paywall_cta_monthly => 'Plan lunar';

  @override
  String get paywall_restore => 'Restaurează achizițiile';

  @override
  String get paywall_terms => 'Termeni și politică de confidențialitate';

  @override
  String get paywall_feature_members => 'Până la 10 membri pe locuință';

  @override
  String get paywall_feature_smart => 'Distribuție inteligentă a sarcinilor';

  @override
  String get paywall_feature_vacations => 'Modul vacanță';

  @override
  String get paywall_feature_reviews => 'Evaluări private';

  @override
  String get paywall_feature_history => 'Istoric 90 de zile';

  @override
  String get paywall_feature_no_ads => 'Fără reclame';

  @override
  String rescue_banner_text(int days) {
    return 'Premium expiră în $days zile';
  }

  @override
  String get rescue_banner_renew => 'Reînnoiește';

  @override
  String get subscription_management_title => 'Abonamentul tău';

  @override
  String get subscription_status_active => 'Premium activ';

  @override
  String subscription_status_cancelled(String date) {
    return 'Anulat — activ până la $date';
  }

  @override
  String subscription_status_rescue(int days) {
    return 'Expiră în $days zile';
  }

  @override
  String get subscription_status_free => 'Plan gratuit';

  @override
  String subscription_status_restorable(String date) {
    return 'Poate fi restaurat până la $date';
  }

  @override
  String get subscription_restore_btn => 'Restaurează Premium';

  @override
  String get subscription_restore_success => 'Premium restaurat cu succes';

  @override
  String get subscription_restore_expired_error =>
      'Fereastra de restaurare a expirat';

  @override
  String get subscription_plan_downgrade => 'Planifică downgrade';

  @override
  String get downgrade_planner_title => 'Planifică downgrade';

  @override
  String get downgrade_planner_members_section => 'Ce membri vor continua?';

  @override
  String get downgrade_planner_tasks_section => 'Ce sarcini vor continua?';

  @override
  String get downgrade_planner_max_members_hint =>
      'Maximum 3 membri (proprietarul este mereu inclus)';

  @override
  String get downgrade_planner_max_tasks_hint => 'Maximum 4 sarcini';

  @override
  String get downgrade_planner_auto_note =>
      'Dacă nu decizi, se va aplica selecția automată';

  @override
  String get downgrade_planner_save => 'Salvează planul';

  @override
  String get downgrade_planner_saved => 'Plan de downgrade salvat';

  @override
  String get premium_gate_title => 'Funcție Premium';

  @override
  String premium_gate_body(String featureName) {
    return '$featureName necesită Premium';
  }

  @override
  String get premium_gate_upgrade => 'Actualizează la Premium';

  @override
  String get rescue_screen_title => 'Reînnoiește-ți Premium';

  @override
  String get rescue_screen_body =>
      'Abonamentul tău Premium expiră în curând. Reînnoiește acum pentru a păstra accesul la funcții.';

  @override
  String get vacation_title => 'Concediu / Absență';

  @override
  String get vacation_toggle_label => 'Sunt în concediu / absent';

  @override
  String get vacation_start_date => 'Data de început (opțional)';

  @override
  String get vacation_end_date => 'Data de sfârșit (opțional)';

  @override
  String get vacation_reason => 'Motiv (opțional)';

  @override
  String get vacation_save => 'Salvează modificările';

  @override
  String vacation_chip_until(String date) {
    return 'În concediu până pe $date';
  }

  @override
  String get vacation_chip_indefinite => 'În concediu';

  @override
  String get notification_settings_title => 'Notificări';

  @override
  String get notification_on_due_label => 'Notifică la scadență';

  @override
  String get notification_before_label => 'Notifică înainte de scadență';

  @override
  String get notification_minutes_before_label => 'Timp de avans';

  @override
  String get notification_daily_summary_label => 'Rezumat zilnic';

  @override
  String get notification_summary_time_label => 'Ora rezumatului';

  @override
  String get notification_silenced_types_label =>
      'Silențiează tipuri de sarcini';

  @override
  String get notification_premium_only => 'Doar Premium';

  @override
  String get notification_15min => '15 minute';

  @override
  String get notification_30min => '30 de minute';

  @override
  String get notification_1h => '1 oră';

  @override
  String get notification_2h => '2 ore';

  @override
  String get review_dialog_title => 'Evaluează sarcina';

  @override
  String get review_score_label => 'Punctaj (1-10)';

  @override
  String get review_note_label => 'Notă privată (opțional, max 300 caractere)';

  @override
  String get review_submit => 'Trimite evaluarea';

  @override
  String get review_premium_required => 'Evaluările sunt o funcție Premium';

  @override
  String get review_own_task => 'Nu îți poți evalua propriile sarcini';

  @override
  String get radar_chart_title => 'Puncte forte';

  @override
  String get radar_no_data => 'Fără evaluări încă';

  @override
  String get radar_other_tasks => 'Alte sarcini evaluate';

  @override
  String get review_submit_error => 'Eroare la trimiterea evaluării';

  @override
  String get settings_section_account => 'Cont';

  @override
  String get settings_edit_profile => 'Editează profilul';

  @override
  String get settings_change_password => 'Schimbă parola';

  @override
  String get settings_delete_account => 'Șterge contul';

  @override
  String get settings_section_language => 'Limbă';

  @override
  String get settings_section_notifications => 'Notificări';

  @override
  String get settings_section_privacy => 'Confidențialitate';

  @override
  String get settings_phone_visibility => 'Vizibilitatea telefonului';

  @override
  String get settings_section_subscription => 'Abonament';

  @override
  String get settings_view_plan => 'Vezi planul curent';

  @override
  String get settings_restore_purchases => 'Restaurează achizițiile';

  @override
  String get settings_manage_subscription => 'Gestionează abonamentul';

  @override
  String get settings_section_home => 'Acasă';

  @override
  String get settings_home_settings => 'Setări casă';

  @override
  String get settings_invite_code => 'Cod de invitație';

  @override
  String get settings_leave_home => 'Părăsește casa';

  @override
  String get settings_close_home => 'Închide casa';

  @override
  String get settings_section_about => 'Despre';

  @override
  String get settings_app_version => 'Versiunea aplicației';

  @override
  String get settings_terms => 'Termeni de utilizare';

  @override
  String get settings_privacy_policy => 'Politica de confidențialitate';

  @override
  String get settings_sign_out => 'Deconectare';

  @override
  String get settings_sign_out_confirm => 'Te deconectezi?';

  @override
  String get settings_plan_free => 'Plan gratuit';

  @override
  String get settings_plan_premium => 'Plan Premium';

  @override
  String get tasks_title => 'Sarcini';

  @override
  String get tasks_empty_title => 'Nicio sarcină';

  @override
  String get tasks_empty_body => 'Creează prima ta sarcină pentru a începe';

  @override
  String get tasks_empty_cta => 'Creează prima sarcină';

  @override
  String get tasks_create_title => 'Creează sarcină';

  @override
  String get tasks_edit_title => 'Editează sarcina';

  @override
  String get tasks_field_visual => 'Icoană sau emoji';

  @override
  String get tasks_field_title_hint => 'Ex: Spălat vasele';

  @override
  String get tasks_field_description_hint => 'Descriere (opțional)';

  @override
  String get tasks_field_recurrence => 'Recurență';

  @override
  String get tasks_field_assignment_mode => 'Mod de atribuire';

  @override
  String get tasks_field_difficulty => 'Dificultate';

  @override
  String get tasks_assignment_basic_rotation => 'Rotație de bază';

  @override
  String get tasks_assignment_smart => 'Distribuție inteligentă';

  @override
  String get tasks_assignment_members => 'Membri atribuiți';

  @override
  String get tasks_recurrence_every => 'La fiecare';

  @override
  String get tasks_recurrence_hours => 'ore';

  @override
  String get tasks_recurrence_days => 'zile';

  @override
  String get tasks_recurrence_start_time => 'Ora de început';

  @override
  String get tasks_recurrence_end_time => 'Ora de sfârșit (opțional)';

  @override
  String get tasks_recurrence_time => 'Oră';

  @override
  String get tasks_recurrence_day_of_month => 'Ziua lunii';

  @override
  String get tasks_recurrence_week_of_month => 'Săptămâna lunii';

  @override
  String get tasks_recurrence_weekday => 'Ziua săptămânii';

  @override
  String get tasks_recurrence_month => 'Lună';

  @override
  String get tasks_recurrence_timezone => 'Fus orar';

  @override
  String get tasks_recurrence_upcoming => 'Date viitoare';

  @override
  String get tasks_recurrence_hourly_label => 'La fiecare oră';

  @override
  String get tasks_recurrence_daily_label => 'Zilnic';

  @override
  String get tasks_recurrence_weekly_label => 'Săptămânal';

  @override
  String get tasks_recurrence_monthly_fixed_label => 'Lunar (zi fixă)';

  @override
  String get tasks_recurrence_monthly_nth_label => 'Lunar (a N-a săptămână)';

  @override
  String get tasks_recurrence_yearly_fixed_label => 'Anual (dată fixă)';

  @override
  String get tasks_recurrence_yearly_nth_label => 'Anual (a N-a săptămână)';

  @override
  String get tasks_section_active => 'Active';

  @override
  String get tasks_section_frozen => 'Înghețate';

  @override
  String get tasks_status_frozen => 'Înghețată';

  @override
  String get tasks_action_edit => 'Editează';

  @override
  String get tasks_action_freeze => 'Îngheață';

  @override
  String get tasks_action_unfreeze => 'Dezgheață';

  @override
  String get tasks_action_delete => 'Șterge';

  @override
  String get tasks_delete_confirm_title => 'Ștergi sarcina?';

  @override
  String get tasks_delete_confirm_body =>
      'Această acțiune nu poate fi anulată.';

  @override
  String get tasks_delete_confirm_btn => 'Da, șterge';

  @override
  String get tasks_freeze_success => 'Sarcină înghețată';

  @override
  String get tasks_unfreeze_success => 'Sarcină activată';

  @override
  String get tasks_save_error => 'Eroare la salvarea sarcinii';

  @override
  String get tasks_detail_next_occurrences => 'Date viitoare';

  @override
  String get tasks_detail_assignment_order => 'Ordinea atribuirii';

  @override
  String get tasks_validation_title_empty => 'Titlul este obligatoriu';

  @override
  String get tasks_validation_title_too_long => 'Maximum 60 de caractere';

  @override
  String get tasks_validation_no_assignees => 'Selectează cel puțin un membru';

  @override
  String get tasks_validation_difficulty_range =>
      'Greutatea trebuie să fie între 0.5 și 3.0';

  @override
  String get tasks_validation_recurrence_required =>
      'Alege un tip de recurență';

  @override
  String get weekday_mon => 'Luni';

  @override
  String get weekday_tue => 'Marți';

  @override
  String get weekday_wed => 'Miercuri';

  @override
  String get weekday_thu => 'Joi';

  @override
  String get weekday_fri => 'Vineri';

  @override
  String get weekday_sat => 'Sâmbătă';

  @override
  String get weekday_sun => 'Duminică';

  @override
  String get tasks_week_1st => 'Prima';

  @override
  String get tasks_week_2nd => 'A doua';

  @override
  String get tasks_week_3rd => 'A treia';

  @override
  String get tasks_week_4th => 'A patra';

  @override
  String get month_jan => 'Ianuarie';

  @override
  String get month_feb => 'Februarie';

  @override
  String get month_mar => 'Martie';

  @override
  String get month_apr => 'Aprilie';

  @override
  String get month_may => 'Mai';

  @override
  String get month_jun => 'Iunie';

  @override
  String get month_jul => 'Iulie';

  @override
  String get month_aug => 'August';

  @override
  String get month_sep => 'Septembrie';

  @override
  String get month_oct => 'Octombrie';

  @override
  String get month_nov => 'Noiembrie';

  @override
  String get month_dec => 'Decembrie';

  @override
  String tasks_selection_count(int count) {
    return '$count selectate';
  }

  @override
  String get tasks_bulk_freeze => 'Îngheță';

  @override
  String get tasks_bulk_delete => 'Șterge';

  @override
  String tasks_bulk_delete_confirm_title(int count) {
    return 'Șterge $count sarcini?';
  }

  @override
  String get tasks_bulk_delete_confirm_body =>
      'Această acțiune nu poate fi anulată.';

  @override
  String get history_rate_button => 'Evaluează';

  @override
  String get history_rate_sheet_title => 'Evaluează sarcina';

  @override
  String history_rate_score_label(String score) {
    return 'Scor: $score';
  }

  @override
  String get history_rate_note_hint => 'Notă privată (opțional)';

  @override
  String get history_rate_submit => 'Trimite evaluarea';

  @override
  String get member_profile_overflow_tasks_title =>
      'Mai multe sarcini atribuite';

  @override
  String get member_profile_manage_role => 'Gestionează rol';

  @override
  String get member_profile_role_manage_unavailable =>
      'Gestionarea rolurilor disponibilă în curând';

  @override
  String get today_home_selector_create => 'Creează cămin';

  @override
  String get today_home_selector_join => 'Alătură-te cu cod';

  @override
  String get today_home_selector_my_homes => 'Căminele mele';

  @override
  String get tasks_fixed_time_label => 'Oră fixă';

  @override
  String get tasks_fixed_time_pick => 'Alege ora';

  @override
  String get tasks_apply_today_label => 'Creează ocurență pentru azi';

  @override
  String get tasks_upcoming_preview_title => 'Următoarele 3 date';

  @override
  String tasks_upcoming_preview_assignee(String name) {
    return '→ $name';
  }

  @override
  String get tasks_assignment_drag_hint => 'Trage pentru a reordona';

  @override
  String history_event_missed(String name) {
    return '$name nu a finalizat';
  }

  @override
  String get history_filter_missed => 'Expirate';

  @override
  String get task_on_miss_label => 'Dacă expiră neefectuată';

  @override
  String get task_on_miss_same_assignee => 'Păstrează responsabilul';

  @override
  String get task_on_miss_next_rotation => 'Rotație la următor';

  @override
  String get task_detail_assignee => 'Responsabil';

  @override
  String get task_detail_next_due => 'Următoarea dată';

  @override
  String get task_detail_difficulty => 'Dificultate';

  @override
  String get task_detail_upcoming => 'Date viitoare';

  @override
  String get editTask => 'Editează sarcina';

  @override
  String get settings_delete_account_confirm_title => 'Ștergi contul?';

  @override
  String get settings_delete_account_confirm_body =>
      'Această acțiune este permanentă și ireversibilă. Vei pierde accesul la toate locuințele și datele tale.';

  @override
  String get settings_delete_requires_reauth =>
      'Pentru securitate, deconectează-te și reconectează-te înainte de a șterge contul.';
}
