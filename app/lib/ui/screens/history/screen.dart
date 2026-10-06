import 'package:flutter/material.dart';

import '../../../services/storage/storage_service_interface.dart';
import 'content.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.storageService});

  final StorageServiceInterface storageService;

  @override
  Widget build(BuildContext context) => HistoryScreenContent(
        storageService: storageService,
      );
}
