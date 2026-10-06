import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import '../../models/feedback_submission.dart' show FeedbackSubmission;
import 'feedback_sender.dart' show FeedbackSender;

class SupabaseFeedbackService implements FeedbackSender {
  const SupabaseFeedbackService(this._client);

  final SupabaseClient _client;

  @override
  Future<void> send(FeedbackSubmission feedback) async {
    final user = _client.auth.currentUser ??
        (await _client.auth.signInAnonymously()).user;
    if (user == null) throw StateError('Could not create a feedback session.');
    await _client.from('app_feedback').insert({
      'user_id': user.id,
      'category': feedback.category,
      'message': feedback.message,
      'contact_email': feedback.contactEmail,
    });
  }
}
