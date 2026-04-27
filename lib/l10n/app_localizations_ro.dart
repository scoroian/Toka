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
  String get homes_manage_members => 'Gestionează membri';

  @override
  String get homes_transfer_ownership => 'Transferă proprietatea';

  @override
  String get homes_cancel_renewal => 'Anulează reînnoirea';

  @override
  String get homes_freeze_member => 'Îngheață membru';

  @override
  String get homes_coming_soon => 'În curând';

  @override
  String get homes_payer_info_body =>
      'Contul tău plătește Premium pentru această casă.';

  @override
  String get homes_payer_info_action => 'Gestionează în Setări';

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
  String get homes_transfer_ownership_title =>
      'Transferă proprietatea locuinței';

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
  String get history_no_home_title => 'Fără istoric';

  @override
  String get history_no_home_body =>
      'Creează sau alătură-te unui cămin pentru a-ți vedea istoricul';

  @override
  String get tasks_no_home_title => 'Fără sarcini';

  @override
  String get tasks_no_home_body =>
      'Creează sau alătură-te unui cămin pentru a gestiona sarcinile';

  @override
  String get members_no_home_title => 'Fără membri';

  @override
  String get members_no_home_body =>
      'Creează sau alătură-te unui cămin pentru a vedea membrii';

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
  String get pass_turn_minimal_impact =>
      'Impactul asupra respectării tale va fi minim.';

  @override
  String get members_title => 'Membri';

  @override
  String get members_invite_fab => 'Invită';

  @override
  String get members_section_active => 'Activi';

  @override
  String get members_balance_title => 'Echilibrul casei';

  @override
  String get members_balance_well_distributed => 'Bine repartizat';

  @override
  String members_balance_unbalanced(String topName) {
    return 'Dezechilibrat · $topName';
  }

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
  String invite_code_expires_at(String date) {
    return 'Expiră pe $date';
  }

  @override
  String get invite_code_regenerate => 'Regenerează codul';

  @override
  String get invite_code_expired_error =>
      'Acest cod a expirat. Proprietarul trebuie să genereze unul nou.';

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
  String get members_error_payer_locked =>
      'Nu poți fi eliminat sau părăsi casa cât timp ești plătitorul abonamentului Premium activ. Anulează abonamentul sau așteaptă expirarea.';

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
  String rescue_banner_title(int days) {
    return 'Premium expiră în $days zile — reînnoiește pentru a nu pierde funcțiile';
  }

  @override
  String get rescue_banner_last_day =>
      'Premium expiră astăzi. Reînnoiește înainte de miezul nopții.';

  @override
  String rescue_banner_hours_left(int hours) {
    return 'Mai sunt $hours ore';
  }

  @override
  String get rescue_last_billing_error_title => 'Ultima încercare de plată';

  @override
  String cancelled_ends_banner_title(String date) {
    return 'Nu se va reînnoi după $date. Poți reactiva oricând.';
  }

  @override
  String get cancelled_ends_banner_cta => 'Reactivează reînnoirea';

  @override
  String expired_free_banner_title(String date) {
    return 'Premium a expirat pe $date. Reactivează oricând.';
  }

  @override
  String get expired_free_banner_cta => 'Reactivează Premium';

  @override
  String restorable_banner_title(String date) {
    return 'Poți restabili Premium până pe $date';
  }

  @override
  String get restorable_banner_cta => 'Restabilește';

  @override
  String get paywall_title_from_expired => 'Reactivează Premium';

  @override
  String paywall_subtitle_from_expired(String date) {
    return 'Premium a expirat pe $date. Reactivează oricând.';
  }

  @override
  String get paywall_title_from_rescue =>
      'Reînnoiește înainte de a pierde funcțiile';

  @override
  String paywall_subtitle_from_rescue(int days) {
    return 'Mai sunt $days zile pentru reînnoire.';
  }

  @override
  String get paywall_title_from_restorable => 'Restabilește Premium';

  @override
  String paywall_subtitle_from_restorable(int days) {
    return 'Mai sunt $days zile din fereastra de restabilire.';
  }

  @override
  String get paywall_cta_reactivate => 'Reactivează Premium';

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
  String get subscription_free_benefits_title => 'Cu Premium deblochezi';

  @override
  String subscription_counter_members(int used, int max) {
    return '$used/$max membri';
  }

  @override
  String subscription_counter_tasks(int used, int max) {
    return '$used/$max sarcini automate';
  }

  @override
  String subscription_next_renewal(String date) {
    return 'Următoarea reînnoire: $date';
  }

  @override
  String get subscription_no_auto_renew => 'Nu se va reînnoi automat';

  @override
  String subscription_premium_until(String date) {
    return 'Premium până la $date';
  }

  @override
  String subscription_expired_on(String date) {
    return 'Premium a expirat la $date';
  }

  @override
  String subscription_restorable_until(String date, int days) {
    return 'Poți restaura Premium până la $date ($days zile)';
  }

  @override
  String subscription_rescue_warning(int days) {
    return 'Premium-ul tău expiră în $days zile — reînnoiește pentru a-l păstra';
  }

  @override
  String get subscription_manage_billing => 'Gestionează facturarea';

  @override
  String get subscription_cancel_renewal => 'Anulează reînnoirea';

  @override
  String get subscription_reactivate_renewal => 'Reactivează reînnoirea';

  @override
  String get subscription_change_plan => 'Schimbă planul';

  @override
  String get subscription_reactivate_premium => 'Reactivează Premium';

  @override
  String get subscription_payer_label => 'Plătitor';

  @override
  String get subscription_payer_you => 'tu';

  @override
  String get subscription_payer_other => 'alt membru';

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
  String get appearance => 'Aspect';

  @override
  String get theme_light => 'Luminos';

  @override
  String get theme_dark => 'Întunecat';

  @override
  String get theme_system => 'Sistem';

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
  String get tasks_rotation_requires_two_members =>
      'Rotația necesită cel puțin 2 membri';

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

  @override
  String get member_profile_remove_member => 'Eliminare din locuință';

  @override
  String member_profile_remove_member_confirm(String name) {
    return 'Elimini pe $name din locuință? Această acțiune nu poate fi anulată.';
  }

  @override
  String get error_cannot_remove_owner =>
      'Proprietarul locuinței nu poate fi eliminat.';

  @override
  String get free_limit_members_reached =>
      'Planul Free permite până la 3 membri. Treci la Premium pentru a adăuga mai mulți.';

  @override
  String get free_limit_tasks_reached =>
      'Planul Free permite până la 4 sarcini active.';

  @override
  String get free_limit_recurring_reached =>
      'Planul Free permite până la 3 sarcini recurente. Creează una punctuală sau treci la Premium.';

  @override
  String get free_admins_locked_to_owner =>
      'Rolurile de admin sunt disponibile în Premium.';

  @override
  String get free_reviews_disabled => 'Evaluările sunt disponibile în Premium.';

  @override
  String get free_reviews_upgrade_title => 'Evaluări doar în Premium';

  @override
  String get free_reviews_upgrade_body =>
      'Treci la Premium pentru a evalua sarcinile finalizate de ceilalți membri ai casei.';

  @override
  String get free_go_premium_cta => 'Treci la Premium';

  @override
  String free_members_counter(int current, int limit) {
    return '$current / $limit membri — limita planului Free';
  }

  @override
  String get free_unfreeze_blocked_title => 'Limita de sarcini atinsă';

  @override
  String free_unfreeze_blocked_body(int current, int limit) {
    return 'Ai deja $current din $limit sarcini active pe planul Free. Îngheață altă sarcină înainte de a o dezgheța pe aceasta, sau treci la Premium pentru mai multe sarcini active.';
  }

  @override
  String get free_unfreeze_blocked_understood => 'Am înțeles';

  @override
  String get recurrence_one_time => 'Punctuală';

  @override
  String get recurrence_one_time_help =>
      'Se finalizează o singură dată și dispare din listă.';

  @override
  String get notifRationaleTitle => 'Toka te anunță doar ce este important';

  @override
  String get notifRationaleBullet1 => 'Sarcini noi atribuite ție';

  @override
  String get notifRationaleBullet2 => 'Schimbări de tură';

  @override
  String get notifRationaleBullet3 => 'Evaluări primite';

  @override
  String get notifRationaleCtaEnable => 'Activează notificările';

  @override
  String get notifRationaleCtaLater => 'Nu acum';

  @override
  String get notifSystemBlockedBanner =>
      'Notificările sunt blocate de sistem. Activează permisiunile în Setările Android pentru a primi alerte Toka.';

  @override
  String get notifSystemBlockedAction => 'Deschide setările';

  @override
  String get notifTestSectionTitle => 'Testează notificările';

  @override
  String get notifTestSectionHint =>
      'Trimite o mostră din fiecare tip pentru a vedea cum apar.';

  @override
  String get notifTestDeadline => 'Testează «Sarcină pe cale să expire»';

  @override
  String get notifTestAssignment => 'Testează «Sarcină atribuită»';

  @override
  String get notifTestReminder => 'Testează «Memento»';

  @override
  String get notifTestDailySummary => 'Testează «Rezumat zilnic»';

  @override
  String get notifTestFeedback => 'Testează «Evaluare primită»';

  @override
  String get notifTestRotation => 'Testează «Schimb de rotație»';

  @override
  String get notifTestSent => 'Notificare de test trimisă';

  @override
  String get historyEventDetailTitle => 'Detaliu eveniment';

  @override
  String get historyEventUnknownMember => 'membru necunoscut';

  @override
  String get noReviewsOnEvent =>
      'Încă nu există evaluări pentru acest eveniment';

  @override
  String reviewByLabel(String name) {
    return 'Evaluare de la $name';
  }

  @override
  String get reviewPrivateNoteLabel => 'Notă privată';

  @override
  String reviewPrivateNoteHint(String name) {
    return 'Doar tu și $name vedeți această notă';
  }

  @override
  String get memberProfileLastReviews => 'Ultimele evaluări';

  @override
  String daysUntil(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'în $count de zile',
      few: 'în $count zile',
      one: 'în 1 zi',
      zero: 'azi',
    );
    return '$_temp0';
  }

  @override
  String tasksActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de sarcini active',
      few: '$count sarcini active',
      one: '1 sarcină activă',
      zero: 'nicio sarcină activă',
    );
    return '$_temp0';
  }

  @override
  String membersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de membri',
      few: '$count membri',
      one: '1 membru',
      zero: 'niciun membru',
    );
    return '$_temp0';
  }

  @override
  String daysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de zile rămase',
      few: '$count zile rămase',
      one: '1 zi rămasă',
      zero: 'ultima zi',
    );
    return '$_temp0';
  }

  @override
  String reviewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de evaluări',
      few: '$count evaluări',
      one: '1 evaluare',
      zero: 'nicio evaluare',
    );
    return '$_temp0';
  }

  @override
  String get settingsAppearanceTitle => 'Aspect';

  @override
  String get settingsAppearanceSubtitle => 'Alege cum arată Toka';

  @override
  String get skinClassicLabel => 'Clasic';

  @override
  String get skinClassicDescription => 'Cald, luminos, familiar';

  @override
  String get skinFuturistaLabel => 'Futurist';

  @override
  String get skinFuturistaDescription => 'Întunecat, cosmic, minimalist';

  @override
  String get homes_role_frozen => 'Înghețat';

  @override
  String get today_hero_label => 'E RÂNDUL TĂU';

  @override
  String get task_detail_next_turn => 'URMĂTORUL TUR';

  @override
  String get task_detail_rotation => 'ROTAȚIE';

  @override
  String get task_due_at_label => 'Scadent la';

  @override
  String get task_due_at_min_short => 'MIN';

  @override
  String get common_more_options => 'Mai multe opțiuni';

  @override
  String get rotation_now => 'ACUM';

  @override
  String get rotation_next => 'URM.';

  @override
  String get tasks_filter_all => 'Toate';

  @override
  String get tasks_filter_mine => 'Ale mele';

  @override
  String get tasks_filter_due_soon => 'În curând';

  @override
  String get tasks_filter_weekly_chip => 'Săptămânale';

  @override
  String get tasks_filter_monthly_chip => 'Lunare';

  @override
  String get recurrence_label_hourly => 'Oră';

  @override
  String get recurrence_label_daily => 'Zi';

  @override
  String get recurrence_label_weekly => 'Săptămână';

  @override
  String get recurrence_label_monthly => 'Lună';

  @override
  String get recurrence_label_yearly => 'An';

  @override
  String recurrence_pill_hourly(int n) {
    return 'La fiecare ${n}h';
  }

  @override
  String get recurrence_pill_daily => 'Zilnic';

  @override
  String recurrence_pill_daily_n(int n) {
    return 'La fiecare $n zile';
  }

  @override
  String get recurrence_pill_weekly => 'Săptămânal';

  @override
  String get recurrence_pill_monthly => 'Lunar';

  @override
  String get recurrence_pill_yearly => 'Anual';

  @override
  String get recurrence_pill_one_time => 'O singură dată';

  @override
  String get weekday_mon_short => 'L';

  @override
  String get weekday_tue_short => 'M';

  @override
  String get weekday_wed_short => 'M';

  @override
  String get weekday_thu_short => 'J';

  @override
  String get weekday_fri_short => 'V';

  @override
  String get weekday_sat_short => 'S';

  @override
  String get weekday_sun_short => 'D';

  @override
  String get tasks_section_label_title => 'TITLU';

  @override
  String get tasks_section_label_visual => 'VIZUAL';

  @override
  String get tasks_section_label_recurrence => 'RECURENȚĂ';

  @override
  String get tasks_section_label_description => 'DESCRIERE';

  @override
  String get tasks_section_label_assigned => 'ALOCATE';

  @override
  String get tasks_section_label_assignment => 'DISTRIBUȚIE';

  @override
  String get assignment_rotation => 'Rotație';

  @override
  String get assignment_smart => 'Inteligent';

  @override
  String get member_stat_completed_short => 'făcute';

  @override
  String get member_stat_passed_short => 'transferate';

  @override
  String get task_card_done_by => 'Făcută de';

  @override
  String get task_card_assigned_to => 'Alocată lui';

  @override
  String get profile_stat_tasks_label => 'SARCINI';

  @override
  String get profile_stat_streak_label => 'SERIE';

  @override
  String get profile_stat_average_label => 'MEDIE';

  @override
  String get home_settings_section_general => 'GENERAL';

  @override
  String get home_settings_section_members => 'MEMBRI ȘI ROLURI';

  @override
  String get home_settings_section_subscription => 'ABONAMENT';

  @override
  String get home_settings_section_danger => 'ZONĂ DE PERICOL';

  @override
  String get home_settings_section_debug => 'DEBUG';

  @override
  String get home_settings_avatar => 'Avatarul casei';

  @override
  String get home_settings_timezone => 'Fus orar';

  @override
  String get home_settings_pending_invites => 'Invitații în așteptare';

  @override
  String get home_settings_admins => 'Administratori';

  @override
  String get home_settings_plan_current => 'Plan actual';

  @override
  String get home_settings_renewal => 'Reînnoire';

  @override
  String get home_settings_code_short => 'COD';

  @override
  String get vacation_subtitle_futurista =>
      'Cât timp ești în vacanță, sarcinile nu îți vor fi alocate.';

  @override
  String get vacation_reason_label_short => 'MOTIV';

  @override
  String get rescue_hero_title_futurista => 'Decide ce rămâne\nactiv în Free.';

  @override
  String get rescue_subtitle_prefix =>
      'Dacă nu reactivezi, casa ta va trece la Free pe ';

  @override
  String get rescue_subtitle_suffix =>
      '. Restul va fi înghețat 30 zile · restaurabil.';

  @override
  String get common_back_to_home => 'Înapoi la casă';

  @override
  String get plan_per_month_home => 'pe lună · casă';

  @override
  String get plan_per_year_breakdown => 'pe an · 2,50€/lună';

  @override
  String get plan_label_monthly_short => 'LUNAR';

  @override
  String get plan_label_annual_short => 'ANUAL';

  @override
  String get plan_annual_discount_badge => '-37%';

  @override
  String get subscription_status_pill_active => 'Activ';

  @override
  String get subscription_status_pill_cancelled => 'Anulat';

  @override
  String get subscription_status_pill_rescue => 'În salvare';

  @override
  String get subscription_status_pill_expired => 'Expirat';

  @override
  String get subscription_status_pill_restorable => 'Restaurabil';

  @override
  String subscription_renewal_detail(String date) {
    return 'Reînnoire: $date';
  }

  @override
  String subscription_expired_detail(String date) {
    return 'Expirat: $date';
  }

  @override
  String subscription_restore_detail(String date) {
    return 'Restaurează înainte de: $date';
  }

  @override
  String subscription_expires_in_days(int days) {
    return 'Expiră în $days zile';
  }

  @override
  String subscription_expires_on_detail(String date) {
    return 'Expiră: $date';
  }

  @override
  String get phone_visibility_none => 'Nimeni';

  @override
  String get phone_visibility_home => 'Casă';

  @override
  String get phone_visibility_all => 'Toți';

  @override
  String get profile_global_compliance_label => 'Conformitate globală';

  @override
  String get notif_deadline_title => 'Sarcină pe punctul de a expira';

  @override
  String notif_deadline_body(String taskTitle, int minutes) {
    return '$taskTitle · expiră în $minutes min';
  }

  @override
  String notif_assignment_title(String assigner) {
    return '$assigner ți-a alocat o sarcină';
  }

  @override
  String notif_assignment_body(String taskTitle, String dueAt) {
    return '$taskTitle · $dueAt';
  }

  @override
  String notif_reminder_title(int minutes, String taskTitle) {
    return 'În $minutes min: $taskTitle';
  }

  @override
  String notif_reminder_body(String dueAt) {
    return 'Scadent la $dueAt';
  }

  @override
  String notif_daily_summary_title(int total, int mine) {
    return 'Astăzi: $total sarcini · tu ai $mine';
  }

  @override
  String get notif_daily_summary_body => 'Apasă pentru a vedea lista';

  @override
  String notif_feedback_title(String taskTitle) {
    return 'Evaluare: $taskTitle';
  }

  @override
  String notif_feedback_msg_body(String stars) {
    return '$stars · Ți-a lăsat o notă privată';
  }

  @override
  String get notif_rotation_title => 'Rotațiile săptămânii';

  @override
  String notif_rotation_summary(String homeName, int count) {
    return '$homeName · $count sarcini';
  }

  @override
  String get homes_transfer_no_candidates =>
      'Nu există membri activi cărora să le transferi.';

  @override
  String get homes_transfer_confirm_title => 'Transferi proprietatea?';

  @override
  String homes_transfer_confirm_body(String name) {
    return '$name va deveni noul proprietar și tu vei rămâne administrator.';
  }

  @override
  String homes_transfer_success(String name) {
    return '$name este acum proprietarul casei.';
  }

  @override
  String get homes_transfer_error_payer_locked =>
      'Nu poți transfera proprietatea cât plătești Premium-ul casei. Anulează reînnoirea sau transferă la sfârșitul perioadei.';

  @override
  String homes_admins_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count administratori',
      one: '1 administrator',
      zero: 'Fără administratori',
    );
    return '$_temp0';
  }

  @override
  String get homes_admins_sheet_title => 'Administratori';

  @override
  String get homes_admins_sheet_body =>
      'Promovează sau retrogradează membri. Adminii pot gestiona sarcini și membri dar nu pot transfera proprietatea.';

  @override
  String get homes_admins_promote => 'Promovează';

  @override
  String get homes_admins_demote => 'Retrogradează';

  @override
  String get homes_admins_promote_blocked_free =>
      'Doar Premium poate avea mai mulți administratori.';

  @override
  String homes_invitations_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count în așteptare',
      one: '1 în așteptare',
      zero: 'Niciuna',
    );
    return '$_temp0';
  }

  @override
  String get homes_invitations_sheet_title => 'Invitații în așteptare';

  @override
  String get homes_invitations_empty => 'Nu există invitații active.';

  @override
  String homes_invitations_expires_in(String label) {
    return 'Expiră în $label';
  }

  @override
  String get homes_invitations_revoke => 'Revocă';

  @override
  String get homes_invitations_revoked => 'Invitație revocată.';

  @override
  String get homes_avatar_sheet_title => 'Avatarul casei';

  @override
  String get homes_avatar_pick_gallery => 'Alege din galerie';

  @override
  String get homes_avatar_pick_camera => 'Fă o poză';

  @override
  String get homes_avatar_remove => 'Elimină foto';

  @override
  String get homes_avatar_uploading => 'Se încarcă poza…';

  @override
  String get homes_avatar_updated => 'Poza casei actualizată.';
}
