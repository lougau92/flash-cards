import 'package:app/services/diagnostics/app_error_log.dart' show AppErrorLog;
import 'package:flutter_test/flutter_test.dart'
    show contains, expect, hasLength, isNot, test;
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;

void main() {
  test('persists exportable errors and redacts registered secrets', () async {
    SharedPreferences.setMockInitialValues({});
    final log = AppErrorLog.instance;
    await log.clear();
    log.registerSecrets(['sensitive-provider-key']);

    await log.record(
      StateError('Request failed with sensitive-provider-key'),
      source: 'Provider request',
      stackTrace: StackTrace.current,
    );

    final exported = log.exportJson();
    expect(exported, contains('Provider request'));
    expect(exported, contains('[REDACTED]'));
    expect(exported, isNot(contains('sensitive-provider-key')));
    expect(log.entries, hasLength(1));

    await log.clear();
  });
}
