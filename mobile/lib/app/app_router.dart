import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_provider.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/candidate/presentation/candidate_pages.dart';
import '../features/home/presentation/home_shell.dart';
import '../features/hr/presentation/hr_pages.dart';
import '../features/manager/presentation/manager_pages.dart';
import '../features/profile/presentation/profile_pages.dart';
import '../features/splash/presentation/splash_page.dart';
import 'router_refresh.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

bool _isPublic(String loc) {
  return ['/', '/login', '/jobs'].contains(loc) || loc.startsWith('/job/') && !loc.contains('/apply');
}

String? _roleHome(String role) => homeRouteForRole(role);

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = RouterRefreshNotifier(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final authed = ref.read(authProvider) != null;
      final loc = state.matchedLocation;
      final role = ref.read(authProvider)?.user.role;

      if (loc == '/' || loc == '/login') {
        if (authed && loc == '/login') return _roleHome(role!);
        return null;
      }

      if (!_isPublic(loc) && !authed) return '/login';

      if (authed) {
        if (loc.startsWith('/hr/') && role != 'hr' && role != 'hiring_manager') {
          return _roleHome(role!);
        }
        if (loc.startsWith('/manager/') && role != 'hiring_manager') return _roleHome(role!);
        if (loc.startsWith('/interviewer/') && role != 'interviewer') return _roleHome(role!);
        if (loc.startsWith('/candidate/') && role != 'candidate') return _roleHome(role!);
        if ((loc == '/jobs' || loc.startsWith('/job/')) && role != 'candidate' && role != null) {
          if (role == 'hr') return '/hr/dashboard';
          if (role == 'hiring_manager') return '/manager/approvals';
          if (role == 'interviewer') return '/interviewer/schedule';
        }
      }

      if (state.uri.path.endsWith('/apply') && !authed) return '/login';

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => HrShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/hr/dashboard', builder: (_, __) => const HrDashboardPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/hr/jobs', builder: (_, __) => const HrJobsPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/hr/profile', builder: (_, __) => const ProfilePage()),
          ]),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => CandidateShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/jobs', builder: (_, __) => const JobPlazaPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/candidate/profile', builder: (_, __) => const CandidateProfileTabPage()),
          ]),
        ],
      ),
      GoRoute(parentNavigatorKey: _rootKey, path: '/hr/job/create', builder: (_, __) => const JobCreatePage()),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/hr/job/:id',
        builder: (_, s) => HrJobDetailPage(jobId: s.pathParameters['id']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/hr/pipeline/:jobId',
        builder: (_, s) => PipelinePage(jobId: s.pathParameters['jobId']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/hr/application/:id',
        builder: (_, s) => HrApplicationDetailPage(applicationId: s.pathParameters['id']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/hr/interview/schedule',
        builder: (_, s) => ScheduleInterviewPage(applicationId: s.uri.queryParameters['applicationId']),
      ),
      GoRoute(parentNavigatorKey: _rootKey, path: '/hr/interviews', builder: (_, __) => const HrInterviewsPage()),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/hr/interview/:id/feedback',
        builder: (_, s) => HrInterviewFeedbackPage(interviewId: s.pathParameters['id']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/hr/offer/create',
        builder: (_, s) => OfferCreatePage(applicationId: s.uri.queryParameters['applicationId']),
      ),
      GoRoute(parentNavigatorKey: _rootKey, path: '/hr/offers', builder: (_, __) => const HrOffersPage()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/manager/approvals', builder: (_, __) => const ManagerApprovalsPage()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/hr/talent-pool', builder: (_, __) => const TalentPoolPage()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/hr/referrals', builder: (_, __) => const HrReferralsPage()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/hr/reports', builder: (_, __) => const HrReportsPage()),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/job/:id',
        builder: (_, s) => PublicJobDetailPage(jobId: s.pathParameters['id']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/job/:id/apply',
        builder: (_, s) => ApplyPage(jobId: s.pathParameters['id']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/candidate/applications',
        builder: (_, __) => const CandidateApplicationsPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/candidate/application/:id',
        builder: (_, s) => CandidateApplicationDetailPage(applicationId: s.pathParameters['id']!),
      ),
      GoRoute(parentNavigatorKey: _rootKey, path: '/referral', builder: (_, __) => const ReferralCodePage()),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/interviewer/schedule',
        builder: (_, __) => const InterviewerSchedulePage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/interviewer/interview/:id',
        builder: (_, s) => InterviewerFeedbackPage(interviewId: s.pathParameters['id']!),
      ),
      GoRoute(parentNavigatorKey: _rootKey, path: '/messages', builder: (_, __) => const MessagesPage()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/profile', builder: (_, __) => const ProfilePage()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/settings', builder: (_, __) => const SettingsPage()),
    ],
  );
});
