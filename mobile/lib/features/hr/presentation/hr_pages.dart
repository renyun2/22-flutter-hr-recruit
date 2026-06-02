import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/network/dio_client.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/hr_repository.dart';
import '../../auth/application/auth_provider.dart';
import '../../shared/presentation/widgets.dart';

class HrDashboardPage extends ConsumerWidget {
  const HrDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final funnel = ref.watch(funnelReportProvider);
    final offers = ref.watch(offersProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('HR 工作台'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications), onPressed: () => context.push('/messages')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('快捷入口', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(label: const Text('Pipeline'), onPressed: () => context.push('/hr/jobs')),
              ActionChip(label: const Text('安排面试'), onPressed: () => context.push('/hr/interview/schedule')),
              ActionChip(label: const Text('Offer'), onPressed: () => context.push('/hr/offers')),
              ActionChip(label: const Text('人才库'), onPressed: () => context.push('/hr/talent-pool')),
              ActionChip(label: const Text('报表'), onPressed: () => context.push('/hr/reports')),
              ActionChip(label: const Text('内推'), onPressed: () => context.push('/hr/referrals')),
            ],
          ),
          const SizedBox(height: 16),
          const Text('漏斗摘要', style: TextStyle(fontWeight: FontWeight.bold)),
          funnel.when(
            data: (d) => Column(
              children: d.funnel.take(5).map((f) {
                return ListTile(
                  dense: true,
                  title: Text(f.label),
                  trailing: Text('${f.count} (${f.conversionRate}%)'),
                );
              }).toList(),
            ),
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(funnelReportProvider)),
          ),
          const SizedBox(height: 8),
          const Text('待审批 Offer', style: TextStyle(fontWeight: FontWeight.bold)),
          offers.when(
            data: (items) {
              final pending = items.where((o) => o.status == 'pending_approval').toList();
              if (pending.isEmpty) return const Text('暂无待审批');
              return Column(
                children: pending.map((o) => ListTile(
                  title: Text(o.candidateName ?? ''),
                  subtitle: Text('${o.jobTitle} · ¥${o.salary}'),
                )).toList(),
              );
            },
            loading: () => const LoadingView(),
            error: (e, _) => Text(e.toString()),
          ),
        ],
      ),
    );
  }
}

class HrJobsPage extends ConsumerWidget {
  const HrJobsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(jobsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('职位管理'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => context.push('/hr/job/create')),
        ],
      ),
      body: jobs.when(
        data: (items) => ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, i) {
            final job = items[i];
            return ListTile(
              title: Text(job.title),
              subtitle: Text('${job.department} · ${job.location} · ${job.status}'),
              trailing: PopupMenuButton<String>(
                onSelected: (v) async {
                  final repo = ref.read(hrRepositoryProvider);
                  try {
                    if (v == 'copy') await repo.copyJob(job.id);
                    if (v == 'archive') await repo.updateJobStatus(job.id, 'archived');
                    if (v == 'active') await repo.updateJobStatus(job.id, 'active');
                    ref.invalidate(jobsProvider);
                    if (context.mounted) showSnack(context, '操作成功');
                  } catch (e) {
                    if (context.mounted) showSnack(context, e.toString());
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'copy', child: Text('复制')),
                  const PopupMenuItem(value: 'archive', child: Text('下架')),
                  const PopupMenuItem(value: 'active', child: Text('上架')),
                ],
              ),
              onTap: () => context.push('/hr/job/${job.id}'),
            );
          },
        ),
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(jobsProvider)),
      ),
    );
  }
}

class JobCreatePage extends ConsumerStatefulWidget {
  const JobCreatePage({super.key});

  @override
  ConsumerState<JobCreatePage> createState() => _JobCreatePageState();
}

class _JobCreatePageState extends ConsumerState<JobCreatePage> {
  final _title = TextEditingController();
  final _department = TextEditingController(text: '技术部');
  final _location = TextEditingController(text: '上海');
  final _description = TextEditingController(text: '负责核心业务开发');
  final _requirements = TextEditingController(text: '3年以上经验');
  final _salaryMin = TextEditingController(text: '15000');
  final _salaryMax = TextEditingController(text: '30000');
  var _loading = false;

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await ref.read(hrRepositoryProvider).createJob({
        'title': _title.text.trim(),
        'department': _department.text.trim(),
        'location': _location.text.trim(),
        'description': _description.text.trim(),
        'requirements': _requirements.text.trim(),
        'salaryMin': int.tryParse(_salaryMin.text) ?? 0,
        'salaryMax': int.tryParse(_salaryMax.text) ?? 0,
        'status': 'active',
      });
      ref.invalidate(jobsProvider);
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
      appBar: AppBar(title: const Text('发布职位')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _title, decoration: const InputDecoration(labelText: '职位标题')),
          TextField(controller: _department, decoration: const InputDecoration(labelText: '部门')),
          TextField(controller: _location, decoration: const InputDecoration(labelText: '地点')),
          TextField(controller: _salaryMin, decoration: const InputDecoration(labelText: '薪资下限')),
          TextField(controller: _salaryMax, decoration: const InputDecoration(labelText: '薪资上限')),
          TextField(controller: _description, decoration: const InputDecoration(labelText: 'JD 描述'), maxLines: 3),
          TextField(controller: _requirements, decoration: const InputDecoration(labelText: '任职要求'), maxLines: 3),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loading ? null : _submit, child: Text(_loading ? '提交中...' : '发布')),
        ],
      ),
    );
  }
}

class HrJobDetailPage extends ConsumerWidget {
  const HrJobDetailPage({super.key, required this.jobId});
  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(hrRepositoryProvider).getJob(jobId),
      builder: (context, snap) {
        if (!snap.hasData) return const Scaffold(body: LoadingView());
        final job = snap.data!;
        return Scaffold(
          appBar: AppBar(title: Text(job.title)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('${job.department} · ${job.location}'),
              Text('薪资 band: ¥${job.salaryMin} - ¥${job.salaryMax}'),
              Text('状态: ${job.status}'),
              const SizedBox(height: 8),
              Text(job.description),
              const SizedBox(height: 8),
              Text('要求: ${job.requirements}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.push('/hr/pipeline/$jobId'),
                child: Text('查看 Pipeline (${job.applicationCount ?? 0})'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PipelinePage extends ConsumerStatefulWidget {
  const PipelinePage({super.key, required this.jobId});
  final String jobId;

  @override
  ConsumerState<PipelinePage> createState() => _PipelinePageState();
}

class _PipelinePageState extends ConsumerState<PipelinePage> {
  final _keyword = TextEditingController();
  final _education = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final apps = ref.watch(applicationsProvider(widget.jobId));
    return Scaffold(
      appBar: AppBar(title: const Text('候选人 Pipeline')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _keyword, decoration: const InputDecoration(labelText: '关键词', isDense: true))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _education, decoration: const InputDecoration(labelText: '学历', isDense: true))),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => ref.invalidate(applicationsProvider(widget.jobId)),
                ),
              ],
            ),
          ),
          Expanded(
            child: apps.when(
              data: (data) => ListView(
                scrollDirection: Axis.horizontal,
                children: pipelineStages.map((stage) {
                  final list = data.byStage[stage] ?? [];
                  return Container(
                    width: 220,
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text('${stageLabels[stage]} (${list.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: list.length,
                            itemBuilder: (_, i) {
                              final app = list[i];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: ListTile(
                                  dense: true,
                                  title: Text(app.candidateName, style: const TextStyle(fontSize: 13)),
                                  subtitle: Text('${app.education} · ${app.yearsExperience}年'),
                                  onTap: () => context.push('/hr/application/${app.id}'),
                                  trailing: _nextStage(stage) == null
                                      ? null
                                      : IconButton(
                                          icon: const Icon(Icons.arrow_forward, size: 18),
                                          onPressed: () async {
                                            try {
                                              await ref.read(hrRepositoryProvider).updateApplicationStage(
                                                    app.id,
                                                    _nextStage(stage)!,
                                                    note: 'Kanban 推进',
                                                  );
                                              ref.invalidate(applicationsProvider(widget.jobId));
                                            } catch (e) {
                                              if (context.mounted) showSnack(context, e.toString());
                                            }
                                          },
                                        ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(message: e.toString()),
            ),
          ),
        ],
      ),
    );
  }

  String? _nextStage(String current) {
    const order = ['applied', 'screening', 'written', 'round1', 'round2', 'offer', 'onboarded'];
    final idx = order.indexOf(current);
    if (idx == -1 || idx >= order.length - 1) return null;
    return order[idx + 1];
  }
}

class HrApplicationDetailPage extends ConsumerWidget {
  const HrApplicationDetailPage({super.key, required this.applicationId});
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
          appBar: AppBar(title: Text(app.candidateName)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              StageChip(label: app.stageLabel),
              Text('${app.jobTitle} · ${app.education} · ${app.yearsExperience}年'),
              Text('技能: ${app.skills}'),
              if (app.resumeUrl.isNotEmpty) Text('简历附件: ${app.resumeUrl}'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: pipelineStages
                    .where((s) => s != app.stage)
                    .map((s) => ActionChip(
                          label: Text(stageLabels[s] ?? s),
                          onPressed: () async {
                            try {
                              await ref.read(hrRepositoryProvider).updateApplicationStage(
                                    applicationId,
                                    s,
                                    note: '手动推进',
                                  );
                              if (context.mounted) {
                                showSnack(context, '已更新');
                                context.pop();
                              }
                            } catch (e) {
                              if (context.mounted) showSnack(context, e.toString());
                            }
                          },
                        ))
                    .toList(),
              ),
              const Divider(),
              const Text('时间轴', style: TextStyle(fontWeight: FontWeight.bold)),
              TimelineView(items: timeline),
              ElevatedButton(
                onPressed: () => context.push('/hr/interview/schedule?applicationId=$applicationId'),
                child: const Text('安排面试'),
              ),
              ElevatedButton(
                onPressed: () => context.push('/hr/offer/create?applicationId=$applicationId'),
                child: const Text('创建 Offer'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ScheduleInterviewPage extends ConsumerStatefulWidget {
  const ScheduleInterviewPage({super.key, this.applicationId});
  final String? applicationId;

  @override
  ConsumerState<ScheduleInterviewPage> createState() => _ScheduleInterviewPageState();
}

class _ScheduleInterviewPageState extends ConsumerState<ScheduleInterviewPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);
  final _applicationId = TextEditingController();
  final _interviewerUsername = TextEditingController(text: 'interviewer1');
  final _location = TextEditingController(text: '线上面试');
  List<dynamic> _suggestedSlots = [];
  var _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.applicationId != null) _applicationId.text = widget.applicationId!;
  }

  DateTime? get _scheduledAt {
    if (_selectedDay == null) return null;
    return DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day, _time.hour, _time.minute);
  }

  Future<void> _submit() async {
    final at = _scheduledAt;
    if (at == null || _applicationId.text.isEmpty) {
      showSnack(context, '请选择日期并填写投递 ID');
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(hrRepositoryProvider).scheduleInterview({
        'applicationId': _applicationId.text.trim(),
        'interviewerUsername': _interviewerUsername.text.trim(),
        'scheduledAt': at.toIso8601String(),
        'location': _location.text.trim(),
        'roundType': 'round1',
      });
      ref.invalidate(interviewsProvider);
      if (mounted) {
        showSnack(context, '面试已安排');
        context.pop();
      }
    } catch (e) {
      if (e is DioException && e.error is ApiException) {
        final extra = (e.error as ApiException).extra;
        if (extra?['suggestedSlots'] != null) {
          setState(() => _suggestedSlots = extra!['suggestedSlots'] as List);
        }
      }
      if (mounted) showSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('安排面试')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _applicationId, decoration: const InputDecoration(labelText: '投递 ID')),
          TextField(controller: _interviewerUsername, decoration: const InputDecoration(labelText: '面试官账号')),
          TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 60)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
            onDaySelected: (s, f) => setState(() {
              _selectedDay = s;
              _focusedDay = f;
            }),
          ),
          ListTile(
            title: Text('时间: ${_time.format(context)}'),
            trailing: const Icon(Icons.access_time),
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: _time);
              if (t != null) setState(() => _time = t);
            },
          ),
          TextField(controller: _location, decoration: const InputDecoration(labelText: '地点')),
          if (_suggestedSlots.isNotEmpty) ...[
            const Text('可选时段（冲突后推荐）', style: TextStyle(fontWeight: FontWeight.bold)),
            ..._suggestedSlots.map((s) => ListTile(
                  title: Text(s.toString()),
                  onTap: () {
                    final dt = DateTime.tryParse(s.toString());
                    if (dt != null) setState(() {
                      _selectedDay = DateTime(dt.year, dt.month, dt.day);
                      _time = TimeOfDay(hour: dt.hour, minute: dt.minute);
                    });
                  },
                )),
          ],
          ElevatedButton(onPressed: _loading ? null : _submit, child: Text(_loading ? '提交中...' : '确认排期')),
        ],
      ),
    );
  }
}

class HrInterviewsPage extends ConsumerWidget {
  const HrInterviewsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(interviewsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('面试列表')),
      body: data.when(
        data: (items) => ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, i) {
            final iv = items[i];
            return ListTile(
              title: Text('${iv.candidateName} · ${iv.jobTitle}'),
              subtitle: Text('${iv.scheduledAt} · ${iv.status}'),
              onTap: () => context.push('/hr/interview/${iv.id}/feedback'),
            );
          },
        ),
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString()),
      ),
    );
  }
}

class HrInterviewFeedbackPage extends ConsumerStatefulWidget {
  const HrInterviewFeedbackPage({super.key, required this.interviewId});
  final String interviewId;

  @override
  ConsumerState<HrInterviewFeedbackPage> createState() => _HrInterviewFeedbackPageState();
}

class _HrInterviewFeedbackPageState extends ConsumerState<HrInterviewFeedbackPage> {
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
      appBar: AppBar(title: const Text('面试反馈')),
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

class OfferCreatePage extends ConsumerStatefulWidget {
  const OfferCreatePage({super.key, this.applicationId});
  final String? applicationId;

  @override
  ConsumerState<OfferCreatePage> createState() => _OfferCreatePageState();
}

class _OfferCreatePageState extends ConsumerState<OfferCreatePage> {
  final _applicationId = TextEditingController();
  final _salary = TextEditingController(text: '35000');
  final _bonus = TextEditingController(text: '5000');
  var _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.applicationId != null) _applicationId.text = widget.applicationId!;
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final offer = await ref.read(hrRepositoryProvider).createOffer(
            applicationId: _applicationId.text.trim(),
            salary: num.tryParse(_salary.text) ?? 0,
            bonus: num.tryParse(_bonus.text) ?? 0,
          );
      ref.invalidate(offersProvider);
      if (mounted) {
        showSnack(context, offer.needsApproval ? '已提交，等待经理审批' : 'Offer 已创建');
        context.pop();
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
      appBar: AppBar(title: const Text('创建 Offer')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _applicationId, decoration: const InputDecoration(labelText: '投递 ID')),
            TextField(controller: _salary, decoration: const InputDecoration(labelText: '月薪（超 band 需审批）')),
            TextField(controller: _bonus, decoration: const InputDecoration(labelText: '奖金')),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loading ? null : _submit, child: Text(_loading ? '提交中...' : '创建')),
          ],
        ),
      ),
    );
  }
}

class HrOffersPage extends ConsumerWidget {
  const HrOffersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(offersProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offer 列表'),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => context.push('/hr/offer/create'))],
      ),
      body: data.when(
        data: (items) => ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, i) {
            final o = items[i];
            return ListTile(
              title: Text('${o.candidateName} · ¥${o.salary}'),
              subtitle: Text('${o.jobTitle} · ${o.status}${o.needsApproval ? ' (待审批)' : ''}'),
            );
          },
        ),
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString()),
      ),
    );
  }
}

class TalentPoolPage extends ConsumerWidget {
  const TalentPoolPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(talentPoolProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('人才库')),
      body: data.when(
        data: (items) => ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, i) {
            final t = items[i];
            return ListTile(
              leading: Icon(t.starred ? Icons.star : Icons.star_border),
              title: Text(t.candidateName),
              subtitle: Text('${t.education} · ${t.skills}'),
              trailing: Wrap(children: t.tags.map((tag) => Chip(label: Text(tag, style: const TextStyle(fontSize: 10)))).toList()),
            );
          },
        ),
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString()),
      ),
    );
  }
}

class HrReferralsPage extends ConsumerWidget {
  const HrReferralsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(referralStatsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('内推管理')),
      body: stats.when(
        data: (s) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('成功入职: ${s.totalSuccess}'),
            Text('累计积分: ${s.totalPoints}'),
            Text('单次奖励: ${s.rewardPerOnboard}'),
            const Divider(),
            ...s.items.map((r) => ListTile(
                  title: Text(r['code']?.toString() ?? ''),
                  subtitle: Text('积分 ${r['points_earned']} · 成功 ${r['successful_count']}'),
                )),
          ],
        ),
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString()),
      ),
    );
  }
}

class HrReportsPage extends ConsumerWidget {
  const HrReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final funnel = ref.watch(funnelReportProvider);
    final source = ref.watch(sourceReportProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('数据报表')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('招聘漏斗', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(
            height: 280,
            child: funnel.when(
              data: (d) => BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: d.funnel.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [BarChartRodData(toY: e.value.count.toDouble(), width: 16, color: Colors.blue)],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final idx = v.toInt();
                          if (idx < 0 || idx >= d.funnel.length) return const SizedBox.shrink();
                          return Text(d.funnel[idx].label, style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                ),
              ),
              loading: () => const LoadingView(),
              error: (e, _) => Text(e.toString()),
            ),
          ),
          const SizedBox(height: 16),
          const Text('渠道来源', style: TextStyle(fontWeight: FontWeight.bold)),
          source.when(
            data: (d) => Column(
              children: d.items.map((s) => ListTile(
                    title: Text(s.source),
                    trailing: Text('${s.count} (${s.percentage}%)'),
                  )).toList(),
            ),
            loading: () => const LoadingView(),
            error: (e, _) => Text(e.toString()),
          ),
        ],
      ),
    );
  }
}
