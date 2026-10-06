import 'package:flutter/material.dart'
    show
        BuildContext,
        Column,
        CrossAxisAlignment,
        EdgeInsets,
        FilledButton,
        Icon,
        IconButton,
        Icons,
        MainAxisSize,
        MediaQuery,
        Navigator,
        Padding,
        ScaffoldMessenger,
        SnackBar,
        SingleChildScrollView,
        SizedBox,
        State,
        StatefulWidget,
        Text,
        TextStyle,
        TextButton,
        TextEditingController,
        Widget,
        showModalBottomSheet;

import '../../../models/feedback_submission.dart' show FeedbackSubmission;
import '../../../services/diagnostics/app_error_log.dart' show AppErrorLog;
import '../../../services/feedback/feedback_sender.dart' show FeedbackSender;
import 'fields.dart' show FeedbackFields;

Widget feedbackButton(
  BuildContext context, {
  required FeedbackSender sender,
}) =>
    IconButton(
      tooltip: 'Send feedback',
      icon: const Icon(Icons.feedback_outlined),
      onPressed: () => showFeedbackSheet(context, sender: sender),
    );

Future<void> showFeedbackSheet(
  BuildContext context, {
  required FeedbackSender sender,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => FeedbackForm(sender: sender),
  );
  if (sent == true && context.mounted) {
    messenger.showSnackBar(const SnackBar(content: Text('Feedback sent.')));
  }
}

class FeedbackForm extends StatefulWidget {
  const FeedbackForm({super.key, required this.sender});

  final FeedbackSender sender;

  @override
  State<FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  static const _categories = [
    'Bug report',
    'Research question',
    'Idea',
    'Other'
  ];
  final _messageController = TextEditingController();
  final _emailController = TextEditingController();
  String _category = _categories.first;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _messageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Send feedback', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 12),
              FeedbackFields(
                category: _category,
                messageController: _messageController,
                emailController: _emailController,
                onCategoryChanged: _setCategory,
              ),
              const SizedBox(height: 8),
              const Text(
                'Do not include API keys, private prompts, or source documents. '
                'Nothing is attached automatically.',
              ),
              if (_error case final error?) _errorText(error),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _sending ? null : _send,
                child: Text(_sending ? 'Sending…' : 'Send feedback'),
              ),
              TextButton(
                onPressed: _sending ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      );

  void _setCategory(String? category) {
    if (category != null) setState(() => _category = category);
  }

  Widget _errorText(String error) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(error),
      );

  Future<void> _send() async {
    final message = _messageController.text.trim();
    if (message.length < 5) {
      setState(() => _error = 'Please enter at least five characters.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.sender.send(FeedbackSubmission(
        category: _category,
        message: message,
        contactEmail: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
      ));
      if (mounted) Navigator.pop(context, true);
    } catch (error, stackTrace) {
      await AppErrorLog.instance.record(
        error,
        source: 'Feedback submission',
        stackTrace: stackTrace,
      );
      if (mounted) setState(() => _error = 'Could not send feedback: $error');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}
