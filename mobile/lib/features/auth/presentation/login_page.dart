import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/auth_provider.dart';
import '../../shared/presentation/widgets.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _username = TextEditingController(text: 'hr1');
  final _password = TextEditingController(text: '123456');
  var _loading = false;

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).login(_username.text.trim(), _password.text);
      if (!mounted) return;
      final role = ref.read(authProvider)!.user.role;
      context.go(homeRouteForRole(role));
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('登录')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _username,
              decoration: const InputDecoration(
                labelText: '账号',
                hintText: 'hr1 / manager1 / candidate1 / interviewer1',
              ),
            ),
            TextField(
              controller: _password,
              decoration: const InputDecoration(labelText: '密码'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: Text(_loading ? '登录中...' : '登录'),
              ),
            ),
            const SizedBox(height: 12),
            const Text('测试账号密码均为 123456', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
