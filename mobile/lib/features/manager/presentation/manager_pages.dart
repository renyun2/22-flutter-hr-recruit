import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/hr_repository.dart';
import '../../auth/application/auth_provider.dart';
import '../../shared/presentation/widgets.dart';

class ManagerApprovalsPage extends ConsumerWidget {
  const ManagerApprovalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers = ref.watch(offersProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offer 审批'),
        actions: [
          IconButton(icon: const Icon(Icons.person), onPressed: () => context.push('/profile')),
        ],
      ),
      body: offers.when(
        data: (items) {
          final pending = items.where((o) => o.status == 'pending_approval').toList();
          if (pending.isEmpty) return const Center(child: Text('暂无待审批 Offer'));
          return ListView.builder(
            itemCount: pending.length,
            itemBuilder: (_, i) {
              final o = pending[i];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text('${o.candidateName} · ¥${o.salary}'),
                  subtitle: Text('${o.jobTitle} · 超出薪资 band'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => _resolve(ref, context, o.id, true),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _resolve(ref, context, o.id, false),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(offersProvider)),
      ),
    );
  }

  Future<void> _resolve(WidgetRef ref, BuildContext context, String id, bool approved) async {
    try {
      await ref.read(hrRepositoryProvider).approveOffer(id, approved: approved, comment: approved ? '批准' : '拒绝');
      ref.invalidate(offersProvider);
      if (context.mounted) showSnack(context, approved ? '已批准' : '已拒绝');
    } catch (e) {
      if (context.mounted) showSnack(context, e.toString());
    }
  }
}

class InterviewerSchedulePage extends ConsumerWidget {
  const InterviewerSchedulePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(interviewsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('面试官日程'),
        actions: [
          IconButton(icon: const Icon(Icons.person), onPressed: () => context.push('/profile')),
        ],
      ),
      body: data.when(
        data: (items) => ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, i) {
            final iv = items[i];
            return ListTile(
              title: Text('${iv.candidateName} · ${iv.jobTitle}'),
              subtitle: Text('${iv.scheduledAt} · ${iv.roundType} · ${iv.status}'),
              trailing: iv.status == 'completed'
                  ? null
                  : TextButton(
                      onPressed: () => context.push('/interviewer/interview/${iv.id}'),
                      child: const Text('填反馈'),
                    ),
            );
          },
        ),
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString()),
      ),
    );
  }
}

class InterviewerFeedbackPage extends ConsumerStatefulWidget {
  const InterviewerFeedbackPage({super.key, required this.interviewId});
  final String interviewId;

  @override
  ConsumerState<InterviewerFeedbackPage> createState() => _InterviewerFeedbackPageState();
}

class _InterviewerFeedbackPageState extends ConsumerState<InterviewerFeedbackPage> {
  double _tech = 3, _comm = 3, _culture = 3, _overall = 3;
  final _comment = TextEditingController();
  var _loading = false;

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await ref.read(hrRepositoryProvider).submitInterviewFeedback(widget.interviewId, {
        'technicalScore': _tech.round(),
        'communicationScore': _comm.round(),
        'cultureScore': _culture.round(),
        'overallScore': _overall.round(),
        'recommendation': _overall >= 3 ? 'hire' : 'reject',
        'comment': _comment.text,
      });
      ref.invalidate(interviewsProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('填写反馈')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('技术: ${_tech.round()}'),
          Slider(value: _tech, min: 1, max: 5, divisions: 4, onChanged: (v) => setState(() => _tech = v)),
          Text('沟通: ${_comm.round()}'),
          Slider(value: _comm, min: 1, max: 5, divisions: 4, onChanged: (v) => setState(() => _comm = v)),
          Text('文化: ${_culture.round()}'),
          Slider(value: _culture, min: 1, max: 5, divisions: 4, onChanged: (v) => setState(() => _culture = v)),
          Text('综合: ${_overall.round()}'),
          Slider(value: _overall, min: 1, max: 5, divisions: 4, onChanged: (v) => setState(() => _overall = v)),
          TextField(controller: _comment, decoration: const InputDecoration(labelText: '评语'), maxLines: 3),
          ElevatedButton(onPressed: _loading ? null : _submit, child: Text(_loading ? '提交中...' : '提交')),
        ],
      ),
    );
  }
}
