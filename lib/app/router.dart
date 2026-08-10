import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/admin.dart';
import '../features/ai/ai.dart';
import '../features/auth/auth.dart';
import '../features/groceries/groceries.dart';
import '../features/gym/gym.dart';
import '../features/habits/habits.dart';
import '../features/hydration/hydration.dart';
import '../features/journal/journal.dart';
import '../features/kitchen/presentation/screens/kitchen_hub_screen.dart';
import '../features/mindfulness/mindfulness.dart';
import '../features/movement/movement.dart';
import '../features/notifications/notifications.dart';
import '../features/nutrition/nutrition.dart';
import '../features/onboarding/onboarding.dart';
import '../features/pantry/pantry.dart';
import '../features/profile/profile.dart';
import '../features/reports/reports.dart';
import '../features/search/search.dart';
import '../features/sleep/sleep.dart';
import '../features/spending/spending.dart';
import '../features/support/support.dart';
import '../features/today/today.dart';
import '../features/training/presentation/screens/training_hub_screen.dart';
import '../features/wellness/presentation/screens/wellness_hub_screen.dart';
import '../shared/providers/auth_provider.dart';
import 'shell/app_shell.dart';
import 'shell/more_menu_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

bool _isStaffRole(String? role) => role == 'admin' || role == 'super_admin';
bool _isSuperAdminRole(String? role) => role == 'super_admin';

final routerProvider = Provider<GoRouter>((ref) {
  // Do not watch authProvider here — recreating GoRouter on every auth change
  // resets navigation. refreshListenable + ref.read keeps the same router.
  final refresh = _AuthListenable(ref);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;
      final status = auth.status;

      if (status == AuthStatus.unknown) {
        return loc == '/splash' ? null : '/splash';
      }

      final onAuthFlow = loc.startsWith('/login') ||
          loc.startsWith('/signup') ||
          loc.startsWith('/forgot-password');

      if (status == AuthStatus.unauthenticated) {
        if (auth.error == 'needs_onboarding') {
          return loc == '/onboarding' ? null : '/onboarding';
        }
        // Splash / finished onboarding must leave the loading screen.
        if (loc == '/splash' || loc == '/onboarding') {
          return '/login';
        }
        if (!onAuthFlow) return '/login';
        return null;
      }

      if (status == AuthStatus.authenticated &&
          (onAuthFlow || loc == '/splash' || loc == '/onboarding')) {
        return '/today';
      }

      if (status == AuthStatus.authenticated && loc.startsWith('/admin')) {
        final role = auth.profile?.role;
        if (!_isStaffRole(role)) return '/more';
        final needsSuper = loc.startsWith('/admin/activity') ||
            loc.startsWith('/admin/inquiries');
        if (needsSuper && !_isSuperAdminRole(role)) return '/admin';
      }

      // Legacy aliases after Training / Wellness / Kitchen merge.
      if (loc == '/movement') return '/move/activity';
      if (loc == '/training') return '/move';

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/today', builder: (_, __) => const TodayScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/nutrition',
              builder: (_, __) => const NutritionScreen(),
              routes: [
                GoRoute(
                  path: 'log',
                  builder: (_, __) => const LogMealScreen(),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/move',
              builder: (_, __) => const TrainingHubScreen(),
              routes: [
                GoRoute(
                  path: 'activity',
                  builder: (_, __) => const MovementScreen(),
                ),
                GoRoute(
                  path: 'log',
                  builder: (_, __) => const LogWorkoutScreen(),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/ai', builder: (_, __) => const AiChatScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/more',
              builder: (_, __) => const MoreMenuScreen(),
            ),
          ]),
        ],
      ),
      GoRoute(path: '/wellness', builder: (_, __) => const WellnessHubScreen()),
      GoRoute(path: '/kitchen', builder: (_, __) => const KitchenHubScreen()),
      GoRoute(path: '/gym', builder: (_, __) => const GymOverviewScreen()),
      GoRoute(path: '/gym/demos', builder: (_, __) => const GymDemosScreen()),
      GoRoute(path: '/gym/machines', builder: (_, __) => const GymMachinesScreen()),
      GoRoute(path: '/gym/sessions', builder: (_, __) => const GymSessionsScreen()),
      GoRoute(path: '/gym/plans', builder: (_, __) => const GymPlansScreen()),
      GoRoute(path: '/sleep', builder: (_, __) => const SleepScreen()),
      GoRoute(path: '/hydration', builder: (_, __) => const HydrationScreen()),
      GoRoute(path: '/mindfulness', builder: (_, __) => const MindfulnessScreen()),
      GoRoute(path: '/journal', builder: (_, __) => const JournalScreen()),
      GoRoute(path: '/habits', builder: (_, __) => const HabitsScreen()),
      GoRoute(
        path: '/habits/challenges',
        builder: (_, __) => const ChallengesScreen(),
      ),
      GoRoute(path: '/groceries', builder: (_, __) => const GroceriesScreen()),
      GoRoute(path: '/pantry', builder: (_, __) => const PantryScreen()),
      GoRoute(path: '/pantry/add', builder: (_, __) => const AddPantryScreen()),
      GoRoute(path: '/spending', builder: (_, __) => const SpendingScreen()),
      GoRoute(path: '/spending/log', builder: (_, __) => const LogExpenseScreen()),
      GoRoute(path: '/spending/budget', builder: (_, __) => const BudgetScreen()),
      GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
      GoRoute(path: '/ai/insights', builder: (_, __) => const InsightsScreen()),
      GoRoute(path: '/ai/reminders', builder: (_, __) => const RemindersScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/profile/goals', builder: (_, __) => const GoalsScreen()),
      GoRoute(path: '/profile/history', builder: (_, __) => const HealthHistoryScreen()),
      GoRoute(
        path: '/profile/preferences',
        builder: (_, __) => const PreferencesScreen(),
      ),
      GoRoute(
        path: '/profile/password',
        builder: (_, __) => const ChangePasswordScreen(),
      ),
      GoRoute(path: '/support', builder: (_, __) => const SupportScreen()),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminOverviewScreen()),
      GoRoute(path: '/admin/users', builder: (_, __) => const AdminUsersScreen()),
      GoRoute(
        path: '/admin/tickets',
        builder: (_, __) => const AdminTicketsScreen(),
      ),
      GoRoute(path: '/admin/roles', builder: (_, __) => const AdminRolesScreen()),
      GoRoute(path: '/admin/audit', builder: (_, __) => const AdminAuditScreen()),
      GoRoute(
        path: '/admin/settings',
        builder: (_, __) => const AdminSettingsScreen(),
      ),
      GoRoute(
        path: '/admin/activity',
        builder: (_, __) => const AdminActivityScreen(),
      ),
      GoRoute(
        path: '/admin/inquiries',
        builder: (_, __) => const AdminInquiriesScreen(),
      ),
    ],
  );
});

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(this._ref) {
    // Defer GoRouter refresh so it never runs inside StateNotifier's
    // synchronous listener loop. A throw there becomes
    // StateNotifierListenerError and wrongly fails an otherwise-OK login.
    _ref.listen(authProvider, (_, __) {
      Future.microtask(() {
        if (hasListeners) notifyListeners();
      });
    });
  }

  final Ref _ref;
}
