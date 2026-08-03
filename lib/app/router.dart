import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/backup/backup_screen.dart';
import '../features/candidates/candidates_screen.dart';
import '../features/details/resume_details_screen.dart';
import '../features/help/help_screen.dart';
import '../features/import/import_screen.dart';
import '../features/jobs/jobs_screen.dart';
import '../features/models/models_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/search/search_screen.dart';
import '../features/shell/app_shell.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// App routing. A [StatefulShellRoute] preserves each tab's navigation stack;
/// Import, Details, Help, Backup, and Onboarding are pushed above the shell.
final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/candidates',
  routes: [
    GoRoute(
      path: '/onboarding',
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const OnboardingScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/candidates',
              pageBuilder: (_, _) => const NoTransitionPage(
                child: CandidatesScreen(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              pageBuilder: (_, _) =>
                  const NoTransitionPage(child: SearchScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/jobs',
              pageBuilder: (_, _) =>
                  const NoTransitionPage(child: JobsScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/models',
              pageBuilder: (_, _) =>
                  const NoTransitionPage(child: ModelsScreen()),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/import',
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const ImportScreen(),
    ),
    GoRoute(
      path: '/help',
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const HelpScreen(),
    ),
    GoRoute(
      path: '/backup',
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const BackupScreen(),
    ),
    GoRoute(
      path: '/candidate/:id',
      parentNavigatorKey: _rootKey,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return ResumeDetailsScreen(
          resumeId: id,
          highlight: state.uri.queryParameters['q'],
        );
      },
    ),
  ],
);
