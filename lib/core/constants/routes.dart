abstract class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String home = '/home';
  static const String taskDetail = '/task/:id';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String subscription = '/subscription';

  static const List<String> all = [
    splash,
    onboarding,
    login,
    home,
    taskDetail,
    profile,
    settings,
    subscription,
  ];
}
