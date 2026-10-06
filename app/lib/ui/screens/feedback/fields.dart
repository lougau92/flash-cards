import 'package:flutter/material.dart'
    show
        BuildContext,
        Column,
        DropdownButtonFormField,
        DropdownMenuItem,
        InputDecoration,
        OutlineInputBorder,
        SizedBox,
        StatelessWidget,
        Text,
        TextEditingController,
        TextField,
        TextInputType,
        ValueChanged,
        Widget;

class FeedbackFields extends StatelessWidget {
  const FeedbackFields({
    super.key,
    required this.category,
    required this.messageController,
    required this.emailController,
    required this.onCategoryChanged,
  });

  static const _categories = [
    'Bug report',
    'Research question',
    'Idea',
    'Other'
  ];

  final String category;
  final TextEditingController messageController;
  final TextEditingController emailController;
  final ValueChanged<String?> onCategoryChanged;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: category,
            decoration: const InputDecoration(labelText: 'Feedback type'),
            items: _categories
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: onCategoryChanged,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: messageController,
            maxLength: 4000,
            maxLines: 7,
            decoration: const InputDecoration(
              labelText: 'Your feedback',
              hintText:
                  'Describe what happened or what would help your research.',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email for a reply (optional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      );
}
