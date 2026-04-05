abstract class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String taskDetail = '/task/:id';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String subscription = '/subscription';
  static const String myHomes = '/my-homes';
  static const String homeSettings = '/home-settings';

  static const List<String> all = [
    splash,
    login,
    register,
    forgotPassword,
    verifyEmail,
    onboarding,
    home,
    taskDetail,
    profile,
    settings,
    subscription,
    myHomes,
    homeSettings,
  ];
}
