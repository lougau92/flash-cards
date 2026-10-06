import 'package:flutter/material.dart'
    show
        BorderRadius,
        Brightness,
        BuildContext,
        CardThemeData,
        Color,
        ColorScheme,
        EdgeInsets,
        InputDecorationTheme,
        MaterialApp,
        OutlineInputBorder,
        RoundedRectangleBorder,
        StatelessWidget,
        ThemeData,
        VoidCallback,
        Widget;
import 'package:provider/provider.dart' show Consumer;
import '../services/storage/storage_service_interface.dart'
    show StorageServiceInterface;
import '../state/settings_notifier.dart' show SettingsNotifier;
import 'screens/main_layout_screen.dart' show MainLayoutScreen;

class App extends StatelessWidget {
  const App({
    super.key,
    required this.storageService,
    this.onSignOut,
    this.home,
  });

  final StorageServiceInterface storageService;
  final VoidCallback? onSignOut;
  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsNotifier>(
      builder: (context, settings, _) => MaterialApp(
        title: 'LLM Summary Lab',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF087F8C),
            brightness: Brightness.light,
          ),
          cardTheme: CardThemeData(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFD0BCFF),
            brightness: Brightness.dark,
          ),
          cardTheme: CardThemeData(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        themeMode: settings.themeMode,
        home: home ??
            MainLayoutScreen(
              storageService: storageService,
              onSignOut: onSignOut,
            ),
      ),
    );
  }
}
