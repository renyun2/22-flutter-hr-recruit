import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/hr_repository.dart';

@immutable
class AuthState {
  const AuthState({required this.token, required this.user});
  final String token;
  final HrUser user;
}

class AuthNotifier extends Notifier<AuthState?> {
  @override
  AuthState? build() => null;

  Future<void> restore() async {
    final storage = ref.read(tokenStorageProvider);
    final token = await storage.getToken();
    if (token == null) return;
    try {
      final user = await ref.read(hrRepositoryProvider).me();
      state = AuthState(token: token, user: user);
    } catch (_) {
      await storage.clearToken();
    }
  }

  Future<void> login(String username, String password) async {
    final result = await ref.read(hrRepositoryProvider).login(username, password);
    await ref.read(tokenStorageProvider).saveToken(result.token);
    state = AuthState(token: result.token, user: result.user);
  }

  Future<void> logout() async {
    await ref.read(tokenStorageProvider).clearToken();
    state = null;
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState?>(AuthNotifier.new);

String homeRouteForRole(String role) {
  switch (role) {
    case 'hr':
      return '/hr/dashboard';
    case 'hiring_manager':
      return '/manager/approvals';
    case 'interviewer':
      return '/interviewer/schedule';
    case 'candidate':
      return '/jobs';
    default:
      return '/login';
  }
}

final jobsProvider = FutureProvider.autoDispose<List<Job>>((ref) async {
  return ref.read(hrRepositoryProvider).getJobs();
});

final publicJobsProvider = FutureProvider.autoDispose<List<Job>>((ref) async {
  return ref.read(hrRepositoryProvider).getPublicJobs();
});

final applicationsProvider = FutureProvider.autoDispose
    .family<({List<Application> items, Map<String, List<Application>> byStage, List<Map<String, String>> stages}), String?>((ref, jobId) async {
  return ref.read(hrRepositoryProvider).getApplications(jobId: jobId);
});

final candidateApplicationsProvider = FutureProvider.autoDispose<List<Application>>((ref) async {
  return ref.read(hrRepositoryProvider).getCandidateApplications();
});

final funnelReportProvider = FutureProvider.autoDispose<({int total, List<FunnelItem> funnel})>((ref) async {
  return ref.read(hrRepositoryProvider).getFunnelReport();
});

final sourceReportProvider = FutureProvider.autoDispose<({int total, List<SourceItem> items})>((ref) async {
  return ref.read(hrRepositoryProvider).getSourceReport();
});

final notificationsProvider = FutureProvider.autoDispose<List<NotificationItem>>((ref) async {
  return ref.read(hrRepositoryProvider).getNotifications();
});

final interviewsProvider = FutureProvider.autoDispose<List<Interview>>((ref) async {
  return ref.read(hrRepositoryProvider).getInterviews();
});

final offersProvider = FutureProvider.autoDispose<List<Offer>>((ref) async {
  return ref.read(hrRepositoryProvider).getOffers();
});

final talentPoolProvider = FutureProvider.autoDispose<List<TalentPoolItem>>((ref) async {
  return ref.read(hrRepositoryProvider).getTalentPool();
});

final referralStatsProvider = FutureProvider.autoDispose<ReferralStats>((ref) async {
  return ref.read(hrRepositoryProvider).getReferralStats();
});
