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
}
