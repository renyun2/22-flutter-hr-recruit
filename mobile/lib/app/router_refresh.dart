import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/application/auth_provider.dart';

class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(this.ref) {
    ref.listen<AuthState?>(authProvider, (_, __) => notifyListeners());
  }
  final Ref ref;
}
