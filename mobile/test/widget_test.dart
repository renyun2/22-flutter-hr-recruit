import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hr_recruit/app/hr_app.dart';

void main() {
  testWidgets('app renders splash', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HrRecruitApp()));
    await tester.pump();
    expect(find.text('HR 招聘管理'), findsOneWidget);
  });
}
