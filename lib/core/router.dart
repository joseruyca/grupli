import 'package:go_router/go_router.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/recover_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/reset_password_screen.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/calendar/screens/calendar_screen.dart';
import '../features/finances/screens/finances_screen.dart';
import '../features/groups/screens/create_group_screen.dart';
import '../features/groups/screens/group_detail_screen.dart';
import '../features/groups/screens/edit_group_screen.dart';
import '../features/groups/screens/groups_screen.dart';
import '../features/groups/screens/members_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/settings/screens/settings_info_screen.dart';
import '../features/settings/screens/test_checklist_screen.dart';
import '../features/tournaments/screens/tournaments_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/recover', builder: (_, __) => const RecoverScreen()),
      GoRoute(path: '/reset-password', builder: (_, __) => const ResetPasswordScreen()),
      GoRoute(path: '/app', builder: (_, __) => const GroupsScreen()),
      GoRoute(path: '/app/groups/new', builder: (_, __) => const CreateGroupScreen()),
      GoRoute(
        path: '/app/groups/:groupId',
        builder: (_, state) => GroupDetailScreen(groupId: state.pathParameters['groupId']!),
      ),
      GoRoute(
        path: '/app/groups/:groupId/events',
        builder: (_, state) => CalendarScreen(groupId: state.pathParameters['groupId']!, initialTab: 0),
      ),
      GoRoute(
        path: '/app/groups/:groupId/edit',
        builder: (_, state) => EditGroupScreen(groupId: state.pathParameters['groupId']!),
      ),
      GoRoute(
        path: '/app/groups/:groupId/members',
        builder: (_, state) => MembersScreen(groupId: state.pathParameters['groupId']!),
      ),
      GoRoute(
        path: '/app/groups/:groupId/calendar',
        builder: (_, state) => CalendarScreen(groupId: state.pathParameters['groupId']!, initialTab: 1),
      ),
      GoRoute(
        path: '/app/groups/:groupId/finances',
        builder: (_, state) => FinancesScreen(groupId: state.pathParameters['groupId']!),
      ),
      GoRoute(
        path: '/app/groups/:groupId/tournaments',
        builder: (_, state) => TournamentsScreen(groupId: state.pathParameters['groupId']!),
      ),
      GoRoute(path: '/app/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/app/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/app/settings/terms', builder: (_, __) => const SettingsInfoScreen(type: 'terms')),
      GoRoute(path: '/app/settings/privacy', builder: (_, __) => const SettingsInfoScreen(type: 'privacy')),
      GoRoute(path: '/app/settings/help', builder: (_, __) => const SettingsInfoScreen(type: 'help')),
      GoRoute(path: '/app/test-checklist', builder: (_, __) => const TestChecklistScreen()),
    ],
  );
}
