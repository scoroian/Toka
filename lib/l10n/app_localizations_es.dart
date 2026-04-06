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
  String today_tasks_due(int count) => '$count tareas para hoy';

  @override
  String today_tasks_done_today(int count) => '$count completadas hoy';

  @override
  String get today_section_todo => 'Por hacer';

  @override
  String get today_section_done => 'Hechas';

  @override
  String get today_overdue => 'Vencida';

  @override
  String today_due_today(String time) => 'Hoy $time';

  @override
  String today_due_weekday(String weekday, String time) => '$weekday $time';

  @override
  String today_done_by(String name, String time) =>
      'Completada por $name a las $time';

  @override
  String get today_btn_done => 'Hecho';

  @override
  String get today_btn_pass => 'Pasar';

  @override
  String get today_empty_title => 'Sin tareas para hoy';

  @override
  String get today_empty_body => 'Todas las tareas están al día';
}
