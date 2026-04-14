// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Toka';

  @override
  String get loading => 'Cargando...';

  @override
  String get error_generic => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get retry => 'Reintentar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Eliminar';

  @override
  String get back => 'Atrás';

  @override
  String get next => 'Siguiente';

  @override
  String get done => 'Hecho';

  @override
  String get skip => 'Omitir';

  @override
  String get auth_title => 'Bienvenido a Toka';

  @override
  String get auth_subtitle => 'Gestiona las tareas del hogar juntos';

  @override
  String get auth_google => 'Continuar con Google';

  @override
  String get auth_apple => 'Continuar con Apple';

  @override
  String get auth_email => 'Continuar con email';

  @override
  String get auth_email_label => 'Correo electrónico';

  @override
  String get auth_password_label => 'Contraseña';

  @override
  String get auth_login => 'Iniciar sesión';

  @override
  String get auth_register => 'Crear cuenta';

  @override
  String get auth_forgot_password => '¿Olvidaste tu contraseña?';

  @override
  String get auth_reset_sent =>
      'Te hemos enviado un correo para restablecer tu contraseña';

  @override
  String get onboarding_welcome => 'Bienvenido';

  @override
  String get onboarding_select_language => 'Elige tu idioma';

  @override
  String get onboarding_create_home => 'Crear un hogar';

  @override
  String get onboarding_join_home => 'Unirme a un hogar';

  @override
  String get onboarding_your_name => '¿Cómo te llamas?';

  @override
  String get onboarding_photo_optional => 'Añadir foto (opcional)';

  @override
  String get settings_title => 'Ajustes';

  @override
  String get settings_language => 'Idioma';

  @override
  String get settings_account => 'Cuenta';

  @override
  String get settings_privacy => 'Privacidad';

  @override
  String get settings_notifications => 'Notificaciones';

  @override
  String get settings_subscription => 'Suscripción';

  @override
  String get settings_logout => 'Cerrar sesión';

  @override
  String get language_select_title => 'Seleccionar idioma';

  @override
  String get language_select_subtitle => 'Elige el idioma de la aplicación';

  @override
  String get language_saved => 'Idioma guardado';

  @override
  String get auth_or_divider => 'o';

  @override
  String get auth_confirm_password_label => 'Confirmar contraseña';

  @override
  String get auth_password_show => 'Mostrar contraseña';

  @override
  String get auth_password_hide => 'Ocultar contraseña';

  @override
  String get auth_have_account => '¿Ya tienes cuenta? Inicia sesión';

  @override
  String get auth_no_account => '¿No tienes cuenta? Crear cuenta';

  @override
  String get auth_validation_email_invalid => 'Introduce un email válido';

  @override
  String get auth_validation_password_min_length =>
      'La contraseña debe tener al menos 8 caracteres';

  @override
  String get auth_validation_passwords_no_match =>
      'Las contraseñas no coinciden';

  @override
  String get auth_validation_required => 'Este campo es obligatorio';

  @override
  String get auth_verify_email_title => 'Verifica tu email';

  @override
  String auth_verify_email_body(String email) {
    return 'Hemos enviado un enlace de verificación a $email. Revisa tu bandeja de entrada.';
  }

  @override
  String get auth_resend_email => 'Reenviar email';

  @override
  String auth_resend_cooldown(int seconds) {
    return 'Reenviar en ${seconds}s';
  }

  @override
  String get auth_error_network => 'Error de red. Comprueba tu conexión.';

  @override
  String get auth_error_invalid_credentials =>
      'Email o contraseña incorrectos.';

  @override
  String get auth_error_email_in_use => 'Ya existe una cuenta con este email.';

  @override
  String get auth_error_user_not_found =>
      'No existe una cuenta con este email.';

  @override
  String get auth_error_weak_password =>
      'La contraseña es demasiado débil. Usa al menos 8 caracteres.';

  @override
  String get auth_error_too_many_requests =>
      'Demasiados intentos. Inténtalo más tarde.';

  @override
  String get auth_forgot_password_title => 'Recuperar contraseña';

  @override
  String get auth_forgot_password_body =>
      'Introduce tu email y te enviaremos un enlace para restablecer tu contraseña.';

  @override
  String get auth_send_reset_link => 'Enviar enlace';

  @override
  String get onboarding_welcome_title => 'Bienvenido a Toka';

  @override
  String get onboarding_welcome_subtitle =>
      'Tu app cooperativa de tareas del hogar';

  @override
  String get onboarding_start => 'Empezar';

  @override
  String get onboarding_language_title => '¿En qué idioma prefieres usar Toka?';

  @override
  String get onboarding_profile_title => 'Cuéntanos sobre ti';

  @override
  String get onboarding_nickname_label => '¿Cómo te llaman?';

  @override
  String get onboarding_nickname_hint => 'Tu apodo';

  @override
  String get onboarding_nickname_required => 'El apodo es obligatorio';

  @override
  String get onboarding_nickname_max_length => 'Máximo 30 caracteres';

  @override
  String get onboarding_phone_label => 'Teléfono (opcional)';

  @override
  String get onboarding_phone_visible_label =>
      'Mostrar mi teléfono a miembros del hogar';

  @override
  String get onboarding_home_choice_title => '¿Qué quieres hacer?';

  @override
  String get onboarding_create_home_description =>
      'Crea tu hogar y añade a tus compañeros';

  @override
  String get onboarding_join_home_description =>
      'Únete a un hogar con un código de invitación';

  @override
  String get onboarding_home_name_label => 'Nombre del hogar';

  @override
  String get onboarding_home_name_hint => 'Casa de los García';

  @override
  String get onboarding_home_name_required =>
      'El nombre del hogar es obligatorio';

  @override
  String get onboarding_home_name_max_length => 'Máximo 40 caracteres';

  @override
  String get onboarding_create_home_button => 'Crear hogar';

  @override
  String get onboarding_invite_code_label => 'Código de invitación';

  @override
  String get onboarding_invite_code_hint => '6 caracteres';

  @override
  String get onboarding_invite_code_length_error =>
      'El código debe tener 6 caracteres';

  @override
  String get onboarding_join_home_button => 'Unirme';

  @override
  String get onboarding_error_invalid_invite => 'Código de invitación inválido';

  @override
  String get onboarding_error_expired_invite =>
      'El código de invitación ha expirado';

  @override
  String get onboarding_error_no_slots =>
      'No tienes plazas disponibles para crear más hogares';

  @override
  String get onboarding_add_photo => 'Añadir foto';

  @override
  String get onboarding_change_photo => 'Cambiar foto';

  @override
  String get homes_my_homes => 'Mis hogares';

  @override
  String get homes_selector_title => 'Cambiar hogar';

  @override
  String get homes_settings_title => 'Ajustes del hogar';

  @override
  String get homes_name_label => 'Nombre del hogar';

  @override
  String get homes_plan_free => 'Plan gratuito';

  @override
  String get homes_plan_premium => 'Premium';

  @override
  String homes_plan_ends(String date) {
    return 'Vence el $date';
  }

  @override
  String get homes_manage_subscription => 'Gestionar suscripción';

  @override
  String get homes_members => 'Miembros';

  @override
  String get homes_invite_code => 'Código de invitación';

  @override
  String get homes_generate_code => 'Generar código';

  @override
  String get homes_leave_home => 'Abandonar hogar';

  @override
  String get homes_close_home => 'Cerrar hogar';

  @override
  String get homes_leave_confirm_title => '¿Abandonar hogar?';

  @override
  String get homes_leave_confirm_body =>
      'Dejarás de tener acceso a las tareas de este hogar.';

  @override
  String get homes_close_confirm_title => '¿Cerrar hogar?';

  @override
  String get homes_close_confirm_body =>
      'Se eliminarán todas las tareas y miembros del hogar. Esta acción es irreversible.';

  @override
  String get homes_error_cannot_leave_as_owner =>
      'Transfiere la propiedad antes de abandonar el hogar';

  @override
  String get homes_role_owner => 'Propietario';

  @override
  String get homes_role_admin => 'Administrador';

  @override
  String get homes_role_member => 'Miembro';

  @override
  String get homes_pending_tasks_badge => 'Tienes tareas pendientes';

  @override
  String get homes_add_home => 'Añadir hogar';

  @override
  String get homes_add_create => 'Crear un hogar';

  @override
  String get homes_add_join => 'Unirse a un hogar';

  @override
  String get homes_add_join_by_code => 'Introducir código';

  @override
  String get homes_add_join_by_qr => 'Escanear QR';

  @override
  String get homes_create_name_hint => 'Nombre del hogar';

  @override
  String get homes_create_button => 'Crear';

  @override
  String get homes_join_code_title => 'Unirse con código';

  @override
  String get homes_join_button => 'Unirse';

  @override
  String get homes_max_reached_title => 'Límite de hogares alcanzado';

  @override
  String get homes_max_reached_body =>
      'Ya estás en el máximo de 5 hogares posibles.';

  @override
  String get homes_upgrade_title => '¿Quieres otro hogar?';

  @override
  String get homes_upgrade_body =>
      'Suscríbete a Premium para desbloquear un cupo adicional.';

  @override
  String get homes_upgrade_button => 'Ver planes';

  @override
  String get homes_error_no_slots => 'No tienes cupos disponibles';

  @override
  String get homes_error_invalid_code => 'Código inválido';

  @override
  String get homes_error_expired_code => 'El código ha expirado';

  @override
  String get recurrenceHourly => 'Hora';

  @override
  String get recurrenceDaily => 'Día';

  @override
  String get recurrenceWeekly => 'Semana';

  @override
  String get recurrenceMonthly => 'Mes';

  @override
  String get recurrenceYearly => 'Año';

  @override
  String get today_screen_title => 'Hoy';

  @override
  String today_tasks_due(int count) {
    return '$count tareas para hoy';
  }

  @override
  String today_tasks_done_today(int count) {
    return '$count completadas hoy';
  }

  @override
  String get today_section_todo => 'Por hacer';

  @override
  String get today_section_done => 'Hechas';

  @override
  String get today_overdue => 'Vencida';

  @override
  String today_due_today(String time) {
    return 'Hoy $time';
  }

  @override
  String today_due_weekday(String weekday, String time) {
    return '$weekday $time';
  }

  @override
  String today_done_by(String name, String time) {
    return 'Completada por $name a las $time';
  }

  @override
  String get today_btn_done => 'Hecho';

  @override
  String get today_btn_pass => 'Pasar';

  @override
  String get today_empty_title => 'Sin tareas para hoy';

  @override
  String get today_empty_body => 'Todas las tareas están al día';

  @override
  String get complete_task_dialog_body =>
      '¿Confirmas que has completado esta tarea?';

  @override
  String get complete_task_confirm_btn => 'Sí, hecha ✓';

  @override
  String get pass_turn_dialog_title => '¿Pasar turno?';

  @override
  String pass_turn_compliance_warning(String before, String after) {
    return 'Tu cumplimiento bajará de $before% a ~$after%';
  }

  @override
  String pass_turn_next_assignee(String name) {
    return 'El siguiente responsable será: $name';
  }

  @override
  String get pass_turn_no_candidate =>
      'No hay otro miembro disponible, seguirás siendo el responsable';

  @override
  String get pass_turn_reason_hint => 'Motivo (opcional)';

  @override
  String get pass_turn_confirm_btn => 'Pasar turno';

  @override
  String get members_title => 'Miembros';

  @override
  String get members_invite_fab => 'Invitar';

  @override
  String get members_section_active => 'Activos';

  @override
  String get members_section_frozen => 'Congelados';

  @override
  String members_pending_tasks(int count) {
    return '$count tareas pendientes';
  }

  @override
  String members_compliance(String rate) {
    return 'Cumplimiento: $rate%';
  }

  @override
  String get members_role_badge_owner => 'Propietario';

  @override
  String get members_role_badge_admin => 'Admin';

  @override
  String get members_role_badge_member => 'Miembro';

  @override
  String get members_role_badge_frozen => 'Congelado';

  @override
  String get invite_sheet_title => 'Invitar miembro';

  @override
  String get invite_sheet_share_code => 'Compartir código';

  @override
  String get invite_sheet_by_email => 'Invitar por email';

  @override
  String get invite_sheet_code_label => 'Código de invitación';

  @override
  String get invite_sheet_email_hint => 'correo@ejemplo.com';

  @override
  String get invite_sheet_send => 'Enviar invitación';

  @override
  String get invite_sheet_copy_code => 'Copiar código';

  @override
  String get invite_sheet_scan_qr => 'Escanear QR';

  @override
  String get invite_sheet_qr_hint => 'Apunta la cámara al código QR';

  @override
  String get invite_sheet_code_copied => 'Código copiado';

  @override
  String get member_profile_home_stats => 'Estadísticas en este hogar';

  @override
  String get member_profile_tasks_completed => 'Tareas completadas';

  @override
  String get member_profile_compliance => 'Cumplimiento';

  @override
  String get member_profile_streak => 'Racha actual';

  @override
  String get member_profile_avg_score => 'Puntuación media';

  @override
  String get member_profile_history_30d => 'Últimos 30 días';

  @override
  String get member_profile_history_90d => 'Últimos 90 días';

  @override
  String get member_profile_promote_admin => 'Hacer administrador';

  @override
  String get member_profile_demote_admin => 'Quitar administrador';

  @override
  String member_profile_promote_admin_confirm(String name) {
    return '¿Hacer administrador a $name en este hogar?';
  }

  @override
  String member_profile_demote_admin_confirm(String name) {
    return '¿Quitar el rol de administrador a $name?';
  }

  @override
  String get member_profile_promoted_ok => 'Miembro ascendido a administrador';

  @override
  String get member_profile_demoted_ok => 'Administrador degradado a miembro';

  @override
  String get profile_title => 'Mi perfil';

  @override
  String get profile_edit => 'Editar perfil';

  @override
  String get profile_global_stats => 'Mis estadísticas globales';

  @override
  String get profile_per_home_stats => 'Estadísticas por hogar';

  @override
  String get profile_access_management => 'Gestionar acceso';

  @override
  String get profile_linked_providers => 'Proveedores vinculados';

  @override
  String get profile_change_password => 'Cambiar contraseña';

  @override
  String get profile_logout => 'Cerrar sesión';

  @override
  String get profile_nickname_label => 'Apodo';

  @override
  String get profile_bio_label => 'Bio';

  @override
  String get profile_phone_label => 'Teléfono';

  @override
  String get profile_phone_visibility_label =>
      'Mostrar teléfono a miembros del hogar';

  @override
  String get profile_saved => 'Perfil guardado';

  @override
  String get members_error_max_members =>
      'El hogar ha alcanzado el límite de miembros';

  @override
  String get members_error_max_admins =>
      'El plan gratuito solo permite 1 admin';

  @override
  String get members_error_cannot_remove_owner =>
      'No se puede eliminar al propietario del hogar';

  @override
  String get history_title => 'Historial';

  @override
  String get history_filter_all => 'Todos';

  @override
  String get history_filter_completed => 'Completadas';

  @override
  String get history_filter_passed => 'Pases';

  @override
  String get history_empty_title => 'Sin actividad';

  @override
  String get history_empty_body => 'Aún no hay eventos en el historial';

  @override
  String history_event_completed(String name) {
    return '$name completó';
  }

  @override
  String get history_event_pass_turn => 'pase de turno';

  @override
  String history_event_reason(String reason) {
    return 'Motivo: $reason';
  }

  @override
  String get history_time_now => 'ahora';

  @override
  String history_time_minutes_ago(int minutes) {
    return 'hace $minutes min';
  }

  @override
  String history_time_hours_ago(int hours) {
    return 'hace $hours h';
  }

  @override
  String history_time_days_ago(int days) {
    return 'hace $days días';
  }

  @override
  String get history_load_more => 'Cargar más';

  @override
  String get history_premium_banner_title => 'Más historial con Premium';

  @override
  String get history_premium_banner_body => 'Accede a 90 días de historial';

  @override
  String get history_premium_banner_cta => 'Actualizar a Premium';

  @override
  String get subscription_premium => 'Premium';

  @override
  String get subscription_free => 'Gratuito';

  @override
  String get subscription_monthly => 'Mensual';

  @override
  String get subscription_annual => 'Anual';

  @override
  String get subscription_price_monthly => '3,99 €/mes';

  @override
  String get subscription_price_annual => '29,99 €/año';

  @override
  String get subscription_annual_saving => 'Ahorra 17,89 €';

  @override
  String get paywall_title => 'Haz tu hogar Premium';

  @override
  String get paywall_subtitle =>
      'Todo lo que necesitas para gestionar tu hogar sin límites';

  @override
  String get paywall_cta_annual => 'Empezar Premium Anual';

  @override
  String get paywall_cta_monthly => 'Plan mensual';

  @override
  String get paywall_restore => 'Restaurar compras';

  @override
  String get paywall_terms => 'Ver términos y política de privacidad';

  @override
  String get paywall_feature_members => 'Hasta 10 miembros por hogar';

  @override
  String get paywall_feature_smart => 'Distribución inteligente de tareas';

  @override
  String get paywall_feature_vacations => 'Modo vacaciones';

  @override
  String get paywall_feature_reviews => 'Valoraciones privadas';

  @override
  String get paywall_feature_history => 'Historial 90 días';

  @override
  String get paywall_feature_no_ads => 'Sin publicidad';

  @override
  String rescue_banner_text(int days) {
    return 'Premium expira en $days días';
  }

  @override
  String get rescue_banner_renew => 'Renovar';

  @override
  String get subscription_management_title => 'Tu suscripción';

  @override
  String get subscription_status_active => 'Premium activo';

  @override
  String subscription_status_cancelled(String date) {
    return 'Cancelado — activo hasta $date';
  }

  @override
  String subscription_status_rescue(int days) {
    return 'Expira en $days días';
  }

  @override
  String get subscription_status_free => 'Plan gratuito';

  @override
  String subscription_status_restorable(String date) {
    return 'Puede restaurarse hasta $date';
  }

  @override
  String get subscription_restore_btn => 'Restaurar Premium';

  @override
  String get subscription_restore_success => 'Premium restaurado correctamente';

  @override
  String get subscription_restore_expired_error =>
      'La ventana de restauración ya expiró';

  @override
  String get subscription_plan_downgrade => 'Planear downgrade';

  @override
  String get downgrade_planner_title => 'Planear downgrade';

  @override
  String get downgrade_planner_members_section => '¿Qué miembros continuarán?';

  @override
  String get downgrade_planner_tasks_section => '¿Qué tareas continuarán?';

  @override
  String get downgrade_planner_max_members_hint =>
      'Máximo 3 miembros (owner siempre incluido)';

  @override
  String get downgrade_planner_max_tasks_hint => 'Máximo 4 tareas';

  @override
  String get downgrade_planner_auto_note =>
      'Si no decides, se aplicará selección automática';

  @override
  String get downgrade_planner_save => 'Guardar plan';

  @override
  String get downgrade_planner_saved => 'Plan de downgrade guardado';

  @override
  String get premium_gate_title => 'Función Premium';

  @override
  String premium_gate_body(String featureName) {
    return '$featureName requiere Premium';
  }

  @override
  String get premium_gate_upgrade => 'Actualizar a Premium';

  @override
  String get rescue_screen_title => 'Renueva tu Premium';

  @override
  String get rescue_screen_body =>
      'Tu suscripción Premium expira pronto. Renueva ahora para no perder acceso a tus funciones.';

  @override
  String get vacation_title => 'Vacaciones / Ausencia';

  @override
  String get vacation_toggle_label => 'Estoy de vacaciones / ausente';

  @override
  String get vacation_start_date => 'Fecha de inicio (opcional)';

  @override
  String get vacation_end_date => 'Fecha de fin (opcional)';

  @override
  String get vacation_reason => 'Motivo (opcional)';

  @override
  String get vacation_save => 'Guardar cambios';

  @override
  String vacation_chip_until(String date) {
    return 'De vacaciones hasta $date';
  }

  @override
  String get vacation_chip_indefinite => 'De vacaciones';

  @override
  String get notification_settings_title => 'Notificaciones';

  @override
  String get notification_on_due_label => 'Avisar al vencer';

  @override
  String get notification_before_label => 'Avisar antes de vencer';

  @override
  String get notification_minutes_before_label => 'Tiempo de antelación';

  @override
  String get notification_daily_summary_label => 'Resumen diario';

  @override
  String get notification_summary_time_label => 'Hora del resumen';

  @override
  String get notification_silenced_types_label => 'Silenciar tipos de tarea';

  @override
  String get notification_premium_only => 'Solo Premium';

  @override
  String get notification_15min => '15 minutos';

  @override
  String get notification_30min => '30 minutos';

  @override
  String get notification_1h => '1 hora';

  @override
  String get notification_2h => '2 horas';

  @override
  String get review_dialog_title => 'Valorar tarea';

  @override
  String get review_score_label => 'Puntuación (1-10)';

  @override
  String get review_note_label =>
      'Nota privada (opcional, máx. 300 caracteres)';

  @override
  String get review_submit => 'Enviar valoración';

  @override
  String get review_premium_required =>
      'Las valoraciones son exclusivas de Premium';

  @override
  String get review_own_task => 'No puedes valorar tus propias tareas';

  @override
  String get radar_chart_title => 'Puntos fuertes';

  @override
  String get radar_no_data => 'Sin valoraciones todavía';

  @override
  String get radar_other_tasks => 'Otras tareas evaluadas';

  @override
  String get review_submit_error => 'Error al enviar valoración';

  @override
  String get settings_section_account => 'Cuenta';

  @override
  String get settings_edit_profile => 'Editar perfil';

  @override
  String get settings_change_password => 'Cambiar contraseña';

  @override
  String get settings_delete_account => 'Eliminar cuenta';

  @override
  String get settings_section_language => 'Idioma';

  @override
  String get settings_section_notifications => 'Notificaciones';

  @override
  String get settings_section_privacy => 'Privacidad';

  @override
  String get settings_phone_visibility => 'Visibilidad del teléfono';

  @override
  String get settings_section_subscription => 'Suscripción';

  @override
  String get settings_view_plan => 'Ver plan actual';

  @override
  String get settings_restore_purchases => 'Restaurar compras';

  @override
  String get settings_manage_subscription => 'Gestionar suscripción';

  @override
  String get settings_section_home => 'Hogar';

  @override
  String get settings_home_settings => 'Ajustes del hogar';

  @override
  String get settings_invite_code => 'Código de invitación';

  @override
  String get settings_leave_home => 'Abandonar hogar';

  @override
  String get settings_close_home => 'Cerrar hogar';

  @override
  String get settings_section_about => 'Acerca de';

  @override
  String get settings_app_version => 'Versión de la app';

  @override
  String get settings_terms => 'Términos de uso';

  @override
  String get settings_privacy_policy => 'Política de privacidad';

  @override
  String get settings_sign_out => 'Cerrar sesión';

  @override
  String get settings_sign_out_confirm => '¿Cerrar sesión?';

  @override
  String get settings_plan_free => 'Plan gratuito';

  @override
  String get settings_plan_premium => 'Plan Premium';

  @override
  String get tasks_title => 'Tareas';

  @override
  String get tasks_empty_title => 'Sin tareas';

  @override
  String get tasks_empty_body => 'Crea tu primera tarea para empezar';

  @override
  String get tasks_empty_cta => 'Crear primera tarea';

  @override
  String get tasks_create_title => 'Crear tarea';

  @override
  String get tasks_edit_title => 'Editar tarea';

  @override
  String get tasks_field_visual => 'Icono o emoji';

  @override
  String get tasks_field_title_hint => 'Ej: Fregar los platos';

  @override
  String get tasks_field_description_hint => 'Descripción (opcional)';

  @override
  String get tasks_field_recurrence => 'Recurrencia';

  @override
  String get tasks_field_assignment_mode => 'Modo de asignación';

  @override
  String get tasks_field_difficulty => 'Dificultad';

  @override
  String get tasks_assignment_basic_rotation => 'Rotación básica';

  @override
  String get tasks_assignment_smart => 'Distribución inteligente';

  @override
  String get tasks_assignment_members => 'Miembros asignados';

  @override
  String get tasks_recurrence_every => 'Cada';

  @override
  String get tasks_recurrence_hours => 'horas';

  @override
  String get tasks_recurrence_days => 'días';

  @override
  String get tasks_recurrence_start_time => 'Hora inicio';

  @override
  String get tasks_recurrence_end_time => 'Hora fin (opcional)';

  @override
  String get tasks_recurrence_time => 'Hora';

  @override
  String get tasks_recurrence_day_of_month => 'Día del mes';

  @override
  String get tasks_recurrence_week_of_month => 'Semana del mes';

  @override
  String get tasks_recurrence_weekday => 'Día de la semana';

  @override
  String get tasks_recurrence_month => 'Mes';

  @override
  String get tasks_recurrence_timezone => 'Zona horaria';

  @override
  String get tasks_recurrence_upcoming => 'Próximas fechas';

  @override
  String get tasks_recurrence_hourly_label => 'Cada hora';

  @override
  String get tasks_recurrence_daily_label => 'Diario';

  @override
  String get tasks_recurrence_weekly_label => 'Semanal';

  @override
  String get tasks_recurrence_monthly_fixed_label => 'Mensual (día fijo)';

  @override
  String get tasks_recurrence_monthly_nth_label => 'Mensual (Nth semana)';

  @override
  String get tasks_recurrence_yearly_fixed_label => 'Anual (fecha fija)';

  @override
  String get tasks_recurrence_yearly_nth_label => 'Anual (Nth semana)';

  @override
  String get tasks_section_active => 'Activas';

  @override
  String get tasks_section_frozen => 'Congeladas';

  @override
  String get tasks_status_frozen => 'Congelada';

  @override
  String get tasks_action_edit => 'Editar';

  @override
  String get tasks_action_freeze => 'Congelar';

  @override
  String get tasks_action_unfreeze => 'Descongelar';

  @override
  String get tasks_action_delete => 'Eliminar';

  @override
  String get tasks_delete_confirm_title => '¿Eliminar tarea?';

  @override
  String get tasks_delete_confirm_body => 'Esta acción no se puede deshacer.';

  @override
  String get tasks_delete_confirm_btn => 'Sí, eliminar';

  @override
  String get tasks_freeze_success => 'Tarea congelada';

  @override
  String get tasks_unfreeze_success => 'Tarea activada';

  @override
  String get tasks_save_error => 'Error al guardar la tarea';

  @override
  String get tasks_detail_next_occurrences => 'Próximas fechas';

  @override
  String get tasks_detail_assignment_order => 'Orden de asignación';

  @override
  String get tasks_validation_title_empty => 'El título es obligatorio';

  @override
  String get tasks_validation_title_too_long => 'Máximo 60 caracteres';

  @override
  String get tasks_validation_no_assignees => 'Selecciona al menos un miembro';

  @override
  String get tasks_validation_difficulty_range =>
      'El peso debe estar entre 0.5 y 3.0';

  @override
  String get tasks_validation_recurrence_required =>
      'Elige un tipo de recurrencia';

  @override
  String get weekday_mon => 'Lunes';

  @override
  String get weekday_tue => 'Martes';

  @override
  String get weekday_wed => 'Miércoles';

  @override
  String get weekday_thu => 'Jueves';

  @override
  String get weekday_fri => 'Viernes';

  @override
  String get weekday_sat => 'Sábado';

  @override
  String get weekday_sun => 'Domingo';

  @override
  String get tasks_week_1st => 'Primera';

  @override
  String get tasks_week_2nd => 'Segunda';

  @override
  String get tasks_week_3rd => 'Tercera';

  @override
  String get tasks_week_4th => 'Cuarta';

  @override
  String get month_jan => 'Enero';

  @override
  String get month_feb => 'Febrero';

  @override
  String get month_mar => 'Marzo';

  @override
  String get month_apr => 'Abril';

  @override
  String get month_may => 'Mayo';

  @override
  String get month_jun => 'Junio';

  @override
  String get month_jul => 'Julio';

  @override
  String get month_aug => 'Agosto';

  @override
  String get month_sep => 'Septiembre';

  @override
  String get month_oct => 'Octubre';

  @override
  String get month_nov => 'Noviembre';

  @override
  String get month_dec => 'Diciembre';

  @override
  String tasks_selection_count(int count) {
    return '$count seleccionadas';
  }

  @override
  String get tasks_bulk_freeze => 'Congelar';

  @override
  String get tasks_bulk_delete => 'Eliminar';

  @override
  String tasks_bulk_delete_confirm_title(int count) {
    return '¿Eliminar $count tareas?';
  }

  @override
  String get tasks_bulk_delete_confirm_body =>
      'Esta acción no se puede deshacer.';

  @override
  String get history_rate_button => 'Valorar';

  @override
  String get history_rate_sheet_title => 'Valorar tarea';

  @override
  String history_rate_score_label(String score) {
    return 'Puntuación: $score';
  }

  @override
  String get history_rate_note_hint => 'Nota privada (opcional)';

  @override
  String get history_rate_submit => 'Enviar valoración';

  @override
  String get member_profile_overflow_tasks_title => 'Más tareas asignadas';

  @override
  String get member_profile_manage_role => 'Gestionar rol';

  @override
  String get member_profile_role_manage_unavailable =>
      'Gestión de roles disponible próximamente';

  @override
  String get today_home_selector_create => 'Crear hogar';

  @override
  String get today_home_selector_join => 'Unirse con código';

  @override
  String get today_home_selector_my_homes => 'Mis hogares';

  @override
  String get tasks_fixed_time_label => 'Hora fija';

  @override
  String get tasks_fixed_time_pick => 'Elegir hora';

  @override
  String get tasks_apply_today_label => 'Crear ocurrencia para hoy';

  @override
  String get tasks_upcoming_preview_title => 'Próximas 3 fechas';

  @override
  String tasks_upcoming_preview_assignee(String name) {
    return '→ $name';
  }

  @override
  String get tasks_assignment_drag_hint => 'Arrastra para reordenar';
}
