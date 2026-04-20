import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'core/constants/routes.dart';
import 'core/services/locale_service.dart';
import 'core/theme/app_theme_v2.dart';
import 'core/theme/theme_mode_provider.dart';
import 'features/auth/application/auth_provider.dart';
import 'features/auth/application/auth_state.dart';
import 'features/homes/application/current_home_provider.dart';
import 'features/onboarding/application/onboarding_provider.dart';
import 'features/auth/presentation/forgot_password_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/auth/presentation/verify_email_screen.dart';
import 'features/i18n/application/locale_provider.dart';
import 'features/homes/presentation/home_settings_screen.dart';
import 'features/homes/presentation/my_homes_screen.dart';
import 'features/onboarding/presentation/onboarding_flow_screen.dart';
import 'features/members/presentation/members_screen.dart';
import 'features/members/presentation/vacation_screen.dart';
import 'features/profile/presentation/own_profile_screen.dart';
import 'features/profile/presentation/edit_profile_screen.dart';
import 'features/subscription/presentation/paywall_screen.dart';
import 'features/subscription/presentation/subscription_management_screen.dart';
import 'features/subscription/presentation/rescue_screen.dart';
import 'features/subscription/presentation/downgrade_planner_screen.dart';
import 'features/notifications/application/notification_prefs_provider.dart';
import 'features/notifications/presentation/notification_settings_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'l10n/app_localizations.dart';
import 'features/tasks/presentation/skins/today_screen_v2.dart';
import 'features/tasks/presentation/skins/all_tasks_screen_v2.dart';
import 'features/tasks/presentation/skins/task_detail_screen_v2.dart';
import 'features/tasks/presentation/skins/create_edit_task_screen_v2.dart';
import 'features/history/presentation/skins/history_screen_v2.dart';
import 'features/members/presentation/skins/member_profile_screen_v2.dart';
import 'shared/widgets/skins/main_shell_v2.dart';

part 'app.g.dart';

// Navigator key raíz: necesario para que las sub-rutas de tasks (detalle, edición,
// nueva tarea) usen el navigator raíz y no el navigator del ShellRoute. Así el
// botón Back del sistema puede volver a la lista de tareas (Bug #32).
final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

@Riverpod(keepAlive: true)
class RouterNotifier extends _$RouterNotifier implements Listenable {
  final List<VoidCallback> _listeners = [];

  @override
  void build() {
    void notify() {
      for (final l in _listeners) {
        l();
      }
    }

    // Cuando el UID cambia (login/logout/switch account), invalidar
    // currentHomeProvider de forma síncrona ANTES de llamar notify().
    // Sin esto, ref.listen dispara antes de que Riverpod marque los providers
    // dependientes como stale, y redirect() lee el hogar obsoleto del usuario
    // anterior (Bug #15: race condition keepAlive).
    ref.listen<AuthState>(authProvider, (prev, next) {
      final prevUid = prev?.whenOrNull(authenticated: (u) => u.uid);
      final nextUid = next.whenOrNull(authenticated: (u) => u.uid);
      if (prevUid != nextUid) {
        ref.invalidate(currentHomeProvider);
        ref.invalidate(onboardingCompletedProvider);
      }
      notify();
    });

    // También escuchar currentHomeProvider para que el router se re-evalúe
    // cuando el hogar termina de cargar (loading → data). Sin esto, la primera
    // vez que el usuario se autentica, currentHomeProvider todavía está en
    // AsyncLoading y el redirect va a /onboarding aunque ya tenga hogar.
    ref.listen<AsyncValue<dynamic>>(currentHomeProvider, (_, __) => notify());

    // Escuchar onboardingCompletedProvider para re-evaluar el redirect cuando
    // resuelve. Distingue "usuario sin hogares activos" de "usuario nuevo"
    // sin leer Firestore (SharedPreferences local).
    ref.listen<AsyncValue<bool>>(onboardingCompletedProvider, (_, __) => notify());
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
          final homeAsync = ref.read(currentHomeProvider);
          // Todavía cargando → esperar en la splash para no mostrar onboarding
          // a usuarios que ya tienen hogar. RouterNotifier escucha
          // currentHomeProvider y re-evaluará el redirect cuando resuelva.
          if (homeAsync.isLoading) {
            return location == AppRoutes.splash ? null : AppRoutes.splash;
          }
          // Hogar confirmado en Firestore → ir directo a home.
          if (homeAsync.valueOrNull != null) {
            return AppRoutes.home;
          }
          // Hogar confirmado nulo: distinguir "usuario sin hogares activos"
          // de "usuario nuevo" mediante la flag local de onboarding completado.
          final completedAsync = ref.read(onboardingCompletedProvider);
          if (completedAsync.isLoading) {
            return location == AppRoutes.splash ? null : AppRoutes.splash;
          }
          if (completedAsync.valueOrNull == true) {
            // Ya hizo el onboarding pero no tiene hogares activos → home vacía.
            return AppRoutes.home;
          }
          // Genuinamente nuevo → onboarding.
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
    navigatorKey: _rootNavigatorKey,
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

      // ── Shell principal con NavigationBar ──────────────────────────
      ShellRoute(
        builder: (context, state, child) => MainShellV2(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, __) => const TodayScreenV2(),
          ),
          GoRoute(
            path: AppRoutes.history,
            builder: (_, __) => const HistoryScreenV2(),
          ),
          GoRoute(
            path: AppRoutes.members,
            builder: (_, __) => const MembersScreen(),
          ),
          GoRoute(
            path: AppRoutes.tasks,
            builder: (_, __) => const AllTasksScreenV2(),
            routes: [
              // 'new' debe ir ANTES de ':id' para que /tasks/new no sea
              // capturado por el parámetro :id (Bug #32).
              GoRoute(
                parentNavigatorKey: _rootNavigatorKey,
                path: 'new',
                builder: (_, __) => const CreateEditTaskScreenV2(),
              ),
              GoRoute(
                parentNavigatorKey: _rootNavigatorKey,
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return TaskDetailScreenV2(taskId: id);
                },
                routes: [
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: 'edit',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return CreateEditTaskScreenV2(editTaskId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (_, __) => const SettingsScreen(),
          ),
        ],
      ),

      // ── Pantallas fuera del shell (sin NavigationBar) ──────────────
      // NOTA: createTask (/tasks/new), taskDetail (/tasks/:id) y editTask
      // (/tasks/:id/edit) se definen ahora como sub-rutas de /tasks dentro del
      // ShellRoute con parentNavigatorKey: _rootNavigatorKey. Esto resuelve el
      // Bug #32 (BACK desde detalle cerraba la app).
      GoRoute(
        path: AppRoutes.myHomes,
        builder: (_, __) => const MyHomesScreen(),
      ),
      GoRoute(
        path: AppRoutes.homeSettings,
        builder: (_, __) => const HomeSettingsScreen(),
        routes: [
          // Ruta de miembros fuera del ShellRoute para evitar conflicto de
          // GlobalKey cuando se navega desde HomeSettingsScreen (que está
          // fuera del shell) a /members (que está dentro del shell).
          GoRoute(
            path: 'members',
            builder: (_, __) => const MembersScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.memberProfile,
        builder: (context, state) {
          final uid   = state.pathParameters['uid']!;
          final extra = state.extra as Map<String, dynamic>?;
          final homeId = extra?['homeId'] as String? ?? '';
          return MemberProfileScreenV2(homeId: homeId, memberUid: uid);
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
      GoRoute(
        path: AppRoutes.notificationSettings,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return NotificationSettingsScreen(
            homeId: extra?['homeId'] as String? ?? '',
            uid: extra?['uid'] as String? ?? '',
          );
        },
      ),
    ],
  );
}

class TokaApp extends ConsumerWidget {
  const TokaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(fcmTokenInitProvider);
    final locale     = ref.watch(localeNotifierProvider);
    final router     = ref.watch(appRouterProvider);
    final themeMode  = ref.watch(themeModeNotifierProvider);

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
      theme:      AppThemeV2.light,
      darkTheme:  AppThemeV2.dark,
      themeMode:  themeMode,
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
