import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'core/constants/routes.dart';
import 'core/services/locale_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/application/auth_provider.dart';
import 'features/auth/application/auth_state.dart';
import 'features/auth/presentation/forgot_password_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/auth/presentation/verify_email_screen.dart';
import 'features/i18n/application/locale_provider.dart';
import 'features/homes/presentation/home_settings_screen.dart';
import 'features/homes/presentation/my_homes_screen.dart';
import 'features/onboarding/presentation/onboarding_flow_screen.dart';
import 'features/tasks/presentation/today_screen.dart';
import 'features/members/presentation/members_screen.dart';
import 'features/members/presentation/member_profile_screen.dart';
import 'features/members/presentation/vacation_screen.dart';
import 'features/history/presentation/history_screen.dart';
import 'features/profile/presentation/own_profile_screen.dart';
import 'features/profile/presentation/edit_profile_screen.dart';
import 'features/subscription/presentation/paywall_screen.dart';
import 'features/subscription/presentation/subscription_management_screen.dart';
import 'features/subscription/presentation/rescue_screen.dart';
import 'features/subscription/presentation/downgrade_planner_screen.dart';
import 'l10n/app_localizations.dart';

part 'app.g.dart';

@Riverpod(keepAlive: true)
class RouterNotifier extends _$RouterNotifier implements Listenable {
  final List<VoidCallback> _listeners = [];

  @override
  void build() {
    ref.listen<AuthState>(authProvider, (_, __) {
      for (final l in _listeners) {
        l();
      }
    });
  }

  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = ref.read(authProvider);
    final location = state.matchedLocation;

    const authScreens = [
      AppRoutes.login,
      AppRoutes.register,
      AppRoutes.forgotPassword,
      AppRoutes.verifyEmail,
    ];

    return authState.when(
      initial: () => location == AppRoutes.splash ? null : AppRoutes.splash,
      loading: () => location == AppRoutes.splash ? null : AppRoutes.splash,
      authenticated: (_) {
        if (authScreens.contains(location) || location == AppRoutes.splash) {
          return AppRoutes.onboarding;
        }
        return null;
      },
      unauthenticated: () {
        if (authScreens.contains(location)) return null;
        return AppRoutes.login;
      },
      error: (_) {
        if (location == AppRoutes.login) return null;
        return AppRoutes.login;
      },
    );
  }
}

@Riverpod(keepAlive: true)
GoRouter appRouter(AppRouterRef ref) {
  final notifier = ref.watch(routerNotifierProvider.notifier);
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const _SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (_, __) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingFlowScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const TodayScreen(),
      ),
      GoRoute(
        path: AppRoutes.myHomes,
        builder: (_, __) => const MyHomesScreen(),
      ),
      GoRoute(
        path: AppRoutes.homeSettings,
        builder: (_, __) => const HomeSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.members,
        builder: (_, __) => const MembersScreen(),
      ),
      GoRoute(
        path: AppRoutes.memberProfile,
        builder: (context, state) {
          final uid = state.pathParameters['uid']!;
          final extra = state.extra as Map<String, dynamic>?;
          final homeId = extra?['homeId'] as String? ?? '';
          return MemberProfileScreen(homeId: homeId, memberUid: uid);
        },
      ),
      GoRoute(
        path: AppRoutes.vacation,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final homeId = extra?['homeId'] as String? ?? '';
          final uid = extra?['uid'] as String? ?? '';
          return VacationScreen(homeId: homeId, uid: uid);
        },
      ),
      GoRoute(
        path: AppRoutes.history,
        builder: (_, __) => const HistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, __) => const OwnProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (_, __) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.subscription,
        builder: (_, __) => const SubscriptionManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.paywall,
        builder: (_, __) => const PaywallScreen(),
      ),
      GoRoute(
        path: AppRoutes.rescueScreen,
        builder: (_, __) => const RescueScreen(),
      ),
      GoRoute(
        path: AppRoutes.downgradePlanner,
        builder: (_, __) => const DowngradePlannerScreen(),
      ),
    ],
  );
}

class TokaApp extends ConsumerWidget {
  const TokaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeNotifierProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      locale: locale,
      supportedLocales: LocaleService.supported,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
