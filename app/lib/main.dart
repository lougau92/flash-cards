import 'dart:async' show runZonedGuarded, unawaited;

import 'app_bootstrap.dart' show AppBootstrap;
import 'services/diagnostics/app_error_log.dart' show AppErrorLog;

void main() {
  runZonedGuarded(
    AppBootstrap.run,
    (error, stackTrace) => unawaited(
      AppErrorLog.instance.record(
        error,
        source: 'Dart zone',
        stackTrace: stackTrace,
      ),
    ),
  );
}
