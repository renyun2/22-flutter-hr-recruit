import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/dio_client.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/hr_repository.dart';
import '../../auth/application/auth_provider.dart';
import '../../shared/presentation/widgets.dart';

class JobPlazaPage extends ConsumerWidget {
  const JobPlazaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(publicJobsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('职位广场'),
        actions: [
          IconButton(icon: const Icon(Icons.mail), onPressed: () => context.push('/messages')),
        ],
      ),
      body: jobs.when(
        data: (items) => ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, i) {
            final job = items[i];
            return ListTile(
              title: Text(job.title),
              subtitle: Text('${job.department} · ${job.location} · ¥${job.salaryMin}-${job.salaryMax}'),
              onTap: () => context.push('/job/${job.id}'),
            );
          },
        ),
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(publicJobsProvider)),
      ),
    );
  }
}

class PublicJobDetailPage extends ConsumerWidget {
  const PublicJobDetailPage({super.key, required this.jobId});
  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(hrRepositoryProvider).getJob(jobId, publicView: true),
      builder: (context, snap) {
        if (!snap.hasData) return const Scaffold(body: LoadingView());
        final job = snap.data!;
        return Scaffold(
          appBar: AppBar(title: Text(job.title)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('${job.department} · ${job.location}'),
              Text('薪资: ¥${job.salaryMin} - ¥${job.salaryMax}'),
              const SizedBox(height: 8),
              Text(job.description),
              const SizedBox(height: 8),
              Text('要求: ${job.requirements}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.push('/job/$jobId/apply'),
                child: const Text('立即投递'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ApplyPage extends ConsumerStatefulWidget {
  const ApplyPage({super.key, required this.jobId});
  final String jobId;

  @override
  ConsumerState<ApplyPage> createState() => _ApplyPageState();
}

class _ApplyPageState extends ConsumerState<ApplyPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _education = TextEditingController(text: '本科');
  final _years = TextEditingController(text: '3');
  final _skills = TextEditingController(text: 'Flutter, Dart');
  final _resumeUrl = TextEditingController(text: 'https://example.com/resume.json');
  final _referralCode = TextEditingController();
  var _loading = false;
  var _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final auth = ref.read(authProvider);
    if (auth != null) {
      _name.text = auth.user.name;
      if (auth.user.email != null) _email.text = auth.user.email!;
    }
    _initialized = true;
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await ref.read(hrRepositoryProvider).apply({
        'jobId': widget.jobId,
        'candidateName': _name.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'education': _education.text.trim(),
        'yearsExperience': int.tryParse(_years.text) ?? 0,
        'skills': _skills.text.trim(),
        'resumeUrl': _resumeUrl.text.trim(),
        if (_referralCode.text.isNotEmpty) 'referralCode': _referralCode.text.trim(),
      });
      ref.invalidate(candidateApplicationsProvider);
      if (mounted) {
        showSnack(context, '投递成功');
        context.go('/candidate/applications');
      }
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('投递简历')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: '姓名')),
          TextField(controller: _email, decoration: const InputDecoration(labelText: '邮箱')),
          TextField(controller: _phone, decoration: const InputDecoration(labelText: '手机')),
          TextField(controller: _education, decoration: const InputDecoration(labelText: '学历')),
          TextField(controller: _years, decoration: const InputDecoration(labelText: '工作年限')),
          TextField(controller: _skills, decoration: const InputDecoration(labelText: '技能')),
          TextField(controller: _resumeUrl, decoration: const InputDecoration(labelText: '简历链接(JSON)')),
          TextField(controller: _referralCode, decoration: const InputDecoration(labelText: '内推码(可选)')),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loading ? null : _submit, child: Text(_loading ? '提交中...' : '提交投递')),
        ],
      ),
    );
  }
}

class CandidateApplicationsPage extends ConsumerWidget {
  const CandidateApplicationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apps = ref.watch(candidateApplicationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('我的投递')),
      body: apps.when(
        data: (items) => items.isEmpty
            ? const Center(child: Text('暂无投递，去职位广场看看吧'))
            : ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final app = items[i];
                  return ListTile(
                    title: Text(app.jobTitle ?? ''),
                    subtitle: Text(app.stageLabel),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/candidate/application/${app.id}'),
                  );
                },
              ),
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString()),
      ),
    );
  }
}

class CandidateApplicationDetailPage extends ConsumerWidget {
  const CandidateApplicationDetailPage({super.key, required this.applicationId});
  final String applicationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: Future.wait([
        ref.read(hrRepositoryProvider).getApplication(applicationId),
        ref.read(hrRepositoryProvider).getTimeline(applicationId),
      ]),
      builder: (context, snap) {
        if (!snap.hasData) return const Scaffold(body: LoadingView());
        final app = snap.data![0] as Application;
        final timeline = snap.data![1] as List<TimelineItem>;
        return Scaffold(
          appBar: AppBar(title: Text(app.jobTitle ?? '投递详情')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              StageChip(label: app.stageLabel),
              Text('当前阶段: ${app.stageLabel}'),
              const Divider(),
              const Text('进度时间轴', style: TextStyle(fontWeight: FontWeight.bold)),
              TimelineView(items: timeline),
            ],
          ),
        );
      },
    );
  }
}

class ReferralCodePage extends ConsumerStatefulWidget {
  const ReferralCodePage({super.key});

  @override
  ConsumerState<ReferralCodePage> createState() => _ReferralCodePageState();
}

class _ReferralCodePageState extends ConsumerState<ReferralCodePage> {
  String? _code;
  var _loading = false;

  Future<void> _generate() async {
    setState(() => _loading = true);
    try {
      final res = await ref.read(hrRepositoryProvider).createReferral();
      setState(() => _code = res['code'] as String?);
      ref.invalidate(referralStatsProvider);
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(referralStatsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('内推码')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_code != null) SelectableText('分享码: $_code', style: const TextStyle(fontSize: 20)),
            ElevatedButton(onPressed: _loading ? null : _generate, child: Text(_loading ? '生成中...' : '生成内推码')),
            const SizedBox(height: 16),
            stats.when(
              data: (s) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('成功入职: ${s.totalSuccess}'),
                  Text('累计积分: ${s.totalPoints}'),
                ],
              ),
              loading: () => const LoadingView(),
              error: (e, _) => Text(e.toString()),
            ),
          ],
        ),
      ),
    );
  }
}
