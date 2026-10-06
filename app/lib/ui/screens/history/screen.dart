import 'package:flutter/material.dart'
    show BuildContext, StatelessWidget, Widget;

import '../../../services/storage/storage_service_interface.dart'
    show StorageServiceInterface;
import 'content.dart' show HistoryScreenContent;

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.storageService});

  final StorageServiceInterface storageService;

  @override
  Widget build(BuildContext context) => HistoryScreenContent(
        storageService: storageService,
      );
}
