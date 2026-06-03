import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Web 经反代入口（:5173 / 宿主机 :8811–:8817）时走 [Uri.base.origin]；
  /// `flutter run` 直连 dev server 时默认打本机后端 :3009；
  /// 本机对 Docker 调试请传 `--dart-define=API_BASE=http://localhost:8800`。
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE');
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }

    if (kIsWeb) {
      final port = Uri.base.port;
      if (port == 5173 || (port >= 8811 && port <= 8817)) {
        return Uri.base.origin;
      }
      return 'http://127.0.0.1:3009';
    }

    return 'http://localhost:3009';
  }
}
