import '../../models/feedback_submission.dart' show FeedbackSubmission;

abstract interface class FeedbackSender {
  Future<void> send(FeedbackSubmission feedback);
}

class UnavailableFeedbackSender implements FeedbackSender {
  const UnavailableFeedbackSender();

  @override
  Future<void> send(FeedbackSubmission feedback) async {
    throw StateError(
      'Configure Supabase remote mode to send feedback.',
    );
  }
}
