import 'package:flutter_test/flutter_test.dart';

import 'package:hr_recruit/data/models/models.dart';

void main() {
  test('HrUser parses role', () {
    final user = HrUser.fromJson({
      'id': '1',
      'username': 'hr1',
      'name': 'HR',
      'role': 'hr',
    });
    expect(user.isHr, isTrue);
    expect(user.isCandidate, isFalse);
  });

  test('Application parses stage label', () {
    final app = Application.fromJson({
      'id': 'a1',
      'job_id': 'j1',
      'candidate_name': 'Test',
      'stage': 'screening',
      'stageLabel': '筛选',
    });
    expect(app.stageLabel, '筛选');
  });

  test('pipeline stages include rejected', () {
    expect(pipelineStages, contains('rejected'));
    expect(stageLabels['offer'], 'Offer');
  });
}
