import 'package:app_feedback/app_feedback.dart' show FeedbackSender;
import 'package:flutter/material.dart'
    show
        BuildContext,
        MaterialPageRoute,
        Navigator,
        PopupMenuButton,
        PopupMenuItem,
        Text,
        Widget;

import '../screens/error_log/screen.dart' show ErrorLogScreen;
import 'feedback.dart' show showAppFeedbackSheet;

Widget authSupportMenu(BuildContext context, FeedbackSender sender) =>
    PopupMenuButton<String>(
      tooltip: 'More options',
      onSelected: (action) {
        if (action == 'feedback') {
          showAppFeedbackSheet(context, sender: sender);
        } else {
          Navigator.of(context).push<void>(MaterialPageRoute<void>(
            builder: (_) => ErrorLogScreen(feedbackSender: sender),
          ));
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'feedback', child: Text('Send feedback')),
        PopupMenuItem(value: 'errors', child: Text('View error log')),
      ],
    );
