abstract class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';
  static const String onboarding = '/onboarding';
  static const String notificationRationale = '/onboarding/notifications';
  static const String home = '/home';
  static const String tasks = '/tasks';
  static const String createTask = '/tasks/new';
  static const String taskDetail = '/tasks/:id';
  static const String editTask = '/tasks/:id/edit';
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
  static const String memberProfile = '/members/:uid';
  static const String vacation = '/vacation';
  static const String history = '/history';
  static const String historyEventDetail = '/history/:homeId/:eventId';
  static const String notificationSettings = '/notification-settings';

  static const List<String> all = [
    splash,
    login,
    register,
    forgotPassword,
    verifyEmail,
    onboarding,
    notificationRationale,
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
    historyEventDetail,
    notificationSettings,
  ];
}
