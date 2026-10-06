class FeedbackSubmission {
  const FeedbackSubmission({
    required this.category,
    required this.message,
    this.contactEmail,
  });

  final String category;
  final String message;
  final String? contactEmail;
}
