import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:vidrocket_pro/providers/ad_provider.dart';
import 'package:vidrocket_pro/providers/download_provider.dart';
import 'package:vidrocket_pro/providers/theme_provider.dart';
import 'package:vidrocket_pro/screens/downloads_screen.dart';
import 'package:vidrocket_pro/screens/main_screen.dart';
import 'package:vidrocket_pro/screens/settings_screen.dart';
import 'package:vidrocket_pro/screens/browser_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AdProvider()),
        ChangeNotifierProvider(create: (_) => DownloadProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'VidRocket Pro',
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeProvider.themeMode,
          home: const MainScreen(),
          routes: {
            '/settings': (context) => const SettingsScreen(),
            '/browser': (context) => BrowserScreen(url: ModalRoute.of(context)!.settings.arguments as String),
          },
        );
      },
    );
  }
}
