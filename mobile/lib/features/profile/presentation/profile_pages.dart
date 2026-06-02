import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/hr_repository.dart';
import '../../auth/application/auth_provider.dart';
import '../../shared/presentation/widgets.dart';

class MessagesPage extends ConsumerWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('消息')),
      body: data.when(
        data: (items) => ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, i) {
            final n = items[i];
            return ListTile(
              title: Text(n.title, style: TextStyle(fontWeight: n.readFlag ? FontWeight.normal : FontWeight.bold)),
              subtitle: Text('${n.body}\n${n.createdAt}'),
              isThreeLine: true,
              onTap: () async {
                await ref.read(hrRepositoryProvider).markNotificationRead(n.id);
                ref.invalidate(notificationsProvider);
              },
            );
          },
        ),
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString()),
      ),
    );
  }
}

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth?.user;
    return Scaffold(
      appBar: AppBar(title: const Text('个人中心')),
      body: ListView(
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(user?.name ?? ''),
            subtitle: Text('${user?.username ?? ''} · ${user?.role ?? ''}'),
          ),
          ListTile(
            leading: const Icon(Icons.work),
            title: const Text('面试列表'),
            onTap: () => context.push('/hr/interviews'),
          ),
          ListTile(
            leading: const Icon(Icons.mail),
            title: const Text('消息'),
            onTap: () => context.push('/messages'),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('设置'),
            onTap: () => context.push('/settings'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('退出登录'),
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: const [
          SwitchListTile(title: Text('消息通知'), value: true, onChanged: null),
          SwitchListTile(title: Text('深色模式'), value: false, onChanged: null),
          ListTile(title: Text('关于'), subtitle: Text('HR 招聘管理 Mock v1.0')),
        ],
      ),
    );
  }
}

class CandidateProfileTabPage extends ConsumerWidget {
  const CandidateProfileTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('我的投递'),
            onTap: () => context.push('/candidate/applications'),
          ),
          ListTile(
            leading: const Icon(Icons.card_giftcard),
            title: const Text('内推码'),
            onTap: () => context.push('/referral'),
          ),
          ListTile(
            leading: const Icon(Icons.mail),
            title: const Text('消息'),
            onTap: () => context.push('/messages'),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('设置'),
            onTap: () => context.push('/settings'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('退出登录'),
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}
