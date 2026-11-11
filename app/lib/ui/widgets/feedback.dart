import 'package:app_feedback/app_feedback.dart'
    show FeedbackButton, FeedbackSender, showFeedbackSheet;
import 'package:flutter/material.dart' show BuildContext, Widget;

import '../../services/diagnostics/app_error_log.dart' show AppErrorLog;

Widget appFeedbackButton({required FeedbackSender sender}) =>
    FeedbackButton(sender: sender, onError: _recordFeedbackError);

Future<bool> showAppFeedbackSheet(
  BuildContext context, {
  required FeedbackSender sender,
}) =>
    showFeedbackSheet(context, sender: sender, onError: _recordFeedbackError);

Future<void> _recordFeedbackError(Object error, StackTrace stackTrace) =>
    AppErrorLog.instance
        .record(error, source: 'Feedback submission', stackTrace: stackTrace);
