import 'package:flutter/material.dart'
    show
        AppBar,
        BuildContext,
        FontWeight,
        Icon,
        IconButton,
        Icons,
        IndexedStack,
        NavigationBar,
        NavigationDestination,
        Scaffold,
        State,
        StatefulWidget,
        Text,
        TextStyle,
        VoidCallback,
        Widget;
import '../../services/storage/storage_service_interface.dart'
    show StorageServiceInterface;
import '../widgets/api_keys/sheet.dart' show showApiKeySettingsSheet;
import 'history/screen.dart' show HistoryScreen;
import 'runner_screen.dart' show RunnerScreen;

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({
    super.key,
    required this.storageService,
    this.onSignOut,
  });

  final StorageServiceInterface storageService;
  final VoidCallback? onSignOut;

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
          ..._appBarActions(context),
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

  List<Widget> _appBarActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.vpn_key_outlined),
          tooltip: 'Configure API Keys',
          onPressed: () => showApiKeySettingsSheet(context),
        ),
        if (widget.onSignOut != null)
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: widget.onSignOut,
          ),
      ];
}
