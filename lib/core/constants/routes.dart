abstract class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String tasks = '/tasks';
  static const String createTask = '/tasks/new';
  static const String taskDetail = '/task/:id';
  static const String editTask = '/task/:id/edit';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String subscription = '/subscription';
  static const String paywall = '/subscription/paywall';
  static const String rescueScreen = '/subscription/rescue';
  static const String downgradePlanner = '/subscription/downgrade-planner';
  static const String myHomes = '/my-homes';
  static const String homeSettings = '/home-settings';
  static const String editProfile = '/profile/edit';
  static const String members = '/members';
  static const String memberProfile = '/member/:uid';
  static const String vacation = '/vacation';
  static const String history = '/history';
  static const String notificationSettings = '/notification-settings';

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
    paywall,
    rescueScreen,
    downgradePlanner,
    myHomes,
    homeSettings,
    editProfile,
    members,
    memberProfile,
    vacation,
    history,
    notificationSettings,
  ];
}
