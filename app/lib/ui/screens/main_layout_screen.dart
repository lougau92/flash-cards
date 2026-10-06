import 'package:flutter/material.dart';
import '../../services/storage/storage_service_interface.dart';
import '../widgets/api_keys/sheet.dart';
import 'history/screen.dart';
import 'runner_screen.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key, required this.storageService});

  final StorageServiceInterface storageService;

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.play_circle_outline),
      selectedIcon: Icon(Icons.play_circle),
      label: 'Workspace',
    ),
    NavigationDestination(
      icon: Icon(Icons.history),
      selectedIcon: Icon(Icons.manage_history),
      label: 'Run History',
    ),
  ];

  late final List<Widget> _screens;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _screens = [
      RunnerScreen(storageService: widget.storageService),
      HistoryScreen(storageService: widget.storageService),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'LLM Summary Lab',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.vpn_key_outlined),
            tooltip: 'Configure API Keys',
            onPressed: () => showApiKeySettingsSheet(context),
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: _destinations,
      ),
    );
  }
}