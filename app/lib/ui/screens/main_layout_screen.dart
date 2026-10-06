import 'package:flutter/material.dart'
    show
        AppBar,
        BuildContext,
        FontWeight,
        Icon,
        IconData,
        Icons,
        IndexedStack,
        MaterialPageRoute,
        NavigationBar,
        NavigationDestination,
        Navigator,
        PopupMenuButton,
        PopupMenuItem,
        Row,
        Scaffold,
        SizedBox,
        State,
        StatefulWidget,
        ThemeMode,
        Text,
        TextOverflow,
        TextStyle,
        VoidCallback,
        Widget;
import 'package:provider/provider.dart' show ReadContext, WatchContext;
import '../../services/storage/storage_service_interface.dart'
    show StorageServiceInterface;
import '../widgets/api_keys/sheet.dart' show showApiKeySettingsSheet;
import '../../services/feedback/feedback_sender.dart' show FeedbackSender;
import '../../state/settings_notifier.dart' show SettingsNotifier;
import 'feedback/sheet.dart' show showFeedbackSheet;
import 'history/screen.dart' show HistoryScreen;
import 'error_log/screen.dart' show ErrorLogScreen;
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [_appBarMenu(context)],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: _destinations,
      ),
    );
  }

  Widget _appBarMenu(BuildContext context) {
    final settings = context.watch<SettingsNotifier>();
    final isLight = settings.themeMode == ThemeMode.light;
    final sender = context.read<FeedbackSender>();
    return PopupMenuButton<_MainMenuAction>(
      tooltip: 'App options',
      icon: const Icon(Icons.more_vert),
      onSelected: (action) => _handleMenuAction(context, action, sender),
      itemBuilder: (context) => [
        _menuItem(
          _MainMenuAction.toggleTheme,
          isLight ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
          isLight ? 'Switch to dark mode' : 'Switch to light mode',
        ),
        _menuItem(_MainMenuAction.feedback, Icons.feedback_outlined, 'Feedback'),
        _menuItem(_MainMenuAction.errors, Icons.bug_report_outlined, 'Error log'),
        _menuItem(_MainMenuAction.apiKeys, Icons.vpn_key_outlined, 'API keys'),
        if (widget.onSignOut != null)
          _menuItem(_MainMenuAction.signOut, Icons.logout, 'Sign out'),
      ],
    );
  }

  PopupMenuItem<_MainMenuAction> _menuItem(
    _MainMenuAction action,
    IconData icon,
    String label,
  ) =>
      PopupMenuItem(
        value: action,
        child: Row(
          children: [Icon(icon), const SizedBox(width: 12), Text(label)],
        ),
      );

  void _handleMenuAction(
    BuildContext context,
    _MainMenuAction action,
    FeedbackSender sender,
  ) {
    switch (action) {
      case _MainMenuAction.toggleTheme:
        context.read<SettingsNotifier>().toggleThemeMode();
        break;
      case _MainMenuAction.feedback:
        showFeedbackSheet(context, sender: sender);
        break;
      case _MainMenuAction.errors:
        Navigator.of(context).push<void>(MaterialPageRoute<void>(
          builder: (_) => ErrorLogScreen(feedbackSender: sender),
        ));
        break;
      case _MainMenuAction.apiKeys:
        showApiKeySettingsSheet(context);
        break;
      case _MainMenuAction.signOut:
        widget.onSignOut?.call();
        break;
    }
  }
}

enum _MainMenuAction { toggleTheme, feedback, errors, apiKeys, signOut }
