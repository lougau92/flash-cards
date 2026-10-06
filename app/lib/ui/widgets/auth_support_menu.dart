import 'package:flutter/material.dart'
    show
        BuildContext,
        MaterialPageRoute,
        Navigator,
        PopupMenuButton,
        PopupMenuItem,
        Text,
        Widget;

import '../../services/feedback/feedback_sender.dart' show FeedbackSender;
import '../screens/error_log/screen.dart' show ErrorLogScreen;
import '../screens/feedback/sheet.dart' show showFeedbackSheet;

Widget authSupportMenu(BuildContext context, FeedbackSender sender) =>
    PopupMenuButton<String>(
      tooltip: 'More options',
      onSelected: (action) {
        if (action == 'feedback') {
          showFeedbackSheet(context, sender: sender);
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
