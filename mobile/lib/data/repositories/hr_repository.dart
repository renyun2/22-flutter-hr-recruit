import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../models/models.dart';

class HrRepository {
  HrRepository(this._dio);
  final Dio _dio;

  Future<({String token, HrUser user})> login(String username, String password) async {
    final res = await _dio.post('/api/auth/login', data: {
      'username': username,
      'password': password,
    });
    return (
      token: res.data['token'] as String,
      user: HrUser.fromJson(Map<String, dynamic>.from(res.data['user'] as Map)),
    );
  }

  Future<HrUser> me() async {
    final res = await _dio.get('/api/auth/me');
    return HrUser.fromJson(Map<String, dynamic>.from(res.data['user'] as Map));
  }

  Future<List<Job>> getJobs({String? status}) async {
    final res = await _dio.get('/api/jobs', queryParameters: {if (status != null) 'status': status});
    return (res.data['items'] as List)
        .map((e) => Job.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<Job>> getPublicJobs() async {
    final res = await _dio.get('/api/jobs/public');
    return (res.data['items'] as List)
        .map((e) => Job.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Job> getJob(String id, {bool publicView = false}) async {
    final path = publicView ? '/api/jobs/public/$id' : '/api/jobs/$id';
    final res = await _dio.get(path);
    return Job.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<Job> createJob(Map<String, dynamic> data) async {
    final res = await _dio.post('/api/jobs', data: data);
    return Job.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<Job> updateJobStatus(String id, String status) async {
    final res = await _dio.patch('/api/jobs/$id/status', data: {'status': status});
    return Job.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<Job> copyJob(String id) async {
    final res = await _dio.post('/api/jobs/$id/copy');
    return Job.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<({
    List<Application> items,
    Map<String, List<Application>> byStage,
    List<Map<String, String>> stages,
  })> getApplications({
    String? jobId,
    String? stage,
    String? keyword,
    String? education,
    int? minYears,
    int? maxYears,
  }) async {
    final res = await _dio.get('/api/applications', queryParameters: {
      if (jobId != null) 'jobId': jobId,
      if (stage != null) 'stage': stage,
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      if (education != null && education.isNotEmpty) 'education': education,
      if (minYears != null) 'minYears': minYears,
      if (maxYears != null) 'maxYears': maxYears,
    });
    final items = (res.data['items'] as List)
        .map((e) => Application.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final byStageRaw = Map<String, dynamic>.from(res.data['byStage'] as Map);
    final byStage = byStageRaw.map(
      (k, v) => MapEntry(
        k,
        (v as List).map((e) => Application.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      ),
    );
    final stages = (res.data['stages'] as List)
        .map((e) => Map<String, String>.from({
              'key': (e as Map)['key'] as String,
              'label': e['label'] as String,
            }))
        .toList();
    return (items: items, byStage: byStage, stages: stages);
  }

  Future<List<Application>> getCandidateApplications() async {
    final res = await _dio.get('/api/candidate/applications');
    return (res.data['items'] as List)
        .map((e) => Application.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Application> getApplication(String id) async {
    final res = await _dio.get('/api/applications/$id');
    return Application.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<Application> apply(Map<String, dynamic> data) async {
    final res = await _dio.post('/api/applications', data: data);
    return Application.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<Application> updateApplicationStage(String id, String stage, {String? note}) async {
    final res = await _dio.patch('/api/applications/$id/stage', data: {
      'stage': stage,
      if (note != null) 'note': note,
    });
    return Application.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<List<TimelineItem>> getTimeline(String id) async {
    final res = await _dio.get('/api/applications/$id/timeline');
    return (res.data['items'] as List)
        .map((e) => TimelineItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<Interview>> getInterviews({String? applicationId}) async {
    final res = await _dio.get('/api/interviews', queryParameters: {
      if (applicationId != null) 'applicationId': applicationId,
    });
    return (res.data['items'] as List)
        .map((e) => Interview.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Interview> scheduleInterview(Map<String, dynamic> data) async {
    final res = await _dio.post('/api/interviews', data: data);
    return Interview.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<void> submitInterviewFeedback(String id, Map<String, dynamic> data) async {
    await _dio.post('/api/interviews/$id/feedback', data: data);
  }

  Future<List<Offer>> getOffers({String? status}) async {
    final res = await _dio.get('/api/offers', queryParameters: {
      if (status != null) 'status': status,
    });
    return (res.data['items'] as List)
        .map((e) => Offer.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Offer> createOffer({required String applicationId, required num salary, num bonus = 0}) async {
    final res = await _dio.post('/api/offers', data: {
      'applicationId': applicationId,
      'salary': salary,
      'bonus': bonus,
    });
    return Offer.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<Offer> approveOffer(String id, {required bool approved, String? comment}) async {
    final res = await _dio.post('/api/offers/$id/approve', data: {
      'approved': approved,
      if (comment != null) 'comment': comment,
    });
    return Offer.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<List<TalentPoolItem>> getTalentPool({String? q, bool? starred}) async {
    final res = await _dio.get('/api/talent-pool', queryParameters: {
      if (q != null && q.isNotEmpty) 'q': q,
      if (starred == true) 'starred': '1',
    });
    return (res.data['items'] as List)
        .map((e) => TalentPoolItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Map<String, dynamic>> createReferral() async {
    final res = await _dio.post('/api/referrals');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<ReferralStats> getReferralStats() async {
    final res = await _dio.get('/api/referrals/stats');
    return ReferralStats.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<({int total, List<FunnelItem> funnel})> getFunnelReport({String? jobId}) async {
    final res = await _dio.get('/api/reports/funnel', queryParameters: {
      if (jobId != null) 'jobId': jobId,
    });
    return (
      total: res.data['total'] as int,
      funnel: (res.data['funnel'] as List)
          .map((e) => FunnelItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  Future<({int total, List<SourceItem> items})> getSourceReport() async {
    final res = await _dio.get('/api/reports/source');
    return (
      total: res.data['total'] as int,
      items: (res.data['items'] as List)
          .map((e) => SourceItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  Future<List<NotificationItem>> getNotifications() async {
    final res = await _dio.get('/api/notifications');
    return (res.data['items'] as List)
        .map((e) => NotificationItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> markNotificationRead(String id) async {
    await _dio.patch('/api/notifications/$id/read');
  }
}

final hrRepositoryProvider = Provider((ref) => HrRepository(ref.watch(dioProvider)));
