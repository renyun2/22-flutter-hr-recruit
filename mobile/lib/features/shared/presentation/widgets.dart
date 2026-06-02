import 'package:flutter/material.dart';

import '../../../data/models/models.dart';

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator());
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ],
      ),
    );
  }
}

class StageChip extends StatelessWidget {
  const StageChip({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label, style: const TextStyle(fontSize: 12)));
  }
}

class TimelineView extends StatelessWidget {
  const TimelineView({super.key, required this.items});
  final List<TimelineItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Text('暂无记录');
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final item = items[i];
        return ListTile(
          dense: true,
          title: Text(
            '${stageLabels[item.toStage] ?? item.toStage ?? ''} ${item.note.isNotEmpty ? '- ${item.note}' : ''}',
          ),
          subtitle: Text('${item.userName ?? ''} · ${item.createdAt}'),
        );
      },
    );
  }
}
