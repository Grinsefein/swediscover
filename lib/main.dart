import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/app_database.dart';
import 'data/demo_stops.dart';
import 'data/stop_repository.dart';
import 'repositories/bff_realtime_repository.dart';
import 'repositories/mock_realtime_repository.dart';
import 'repositories/realtime_repository.dart';
import 'theme/m3_expressive_theme.dart';
import 'views/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = Locale('sv', 'SE');
  final services = await AppServices.create();
  runApp(SweDiscoverApp(services: services));
}

class SweDiscoverApp extends StatefulWidget {
  final AppServices? services;

  const SweDiscoverApp({super.key, this.services});

  @override
  State<SweDiscoverApp> createState() => _SweDiscoverAppState();
}

class _SweDiscoverAppState extends State<SweDiscoverApp> {
  bool _isDarkMode = true;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Intl.message(
        'SweDiscover',
        desc: 'App title for SweDiscover',
      ),
      debugShowCheckedModeBanner: false,
      theme: M3ExpressiveTheme.lightTheme(),
      darkTheme: M3ExpressiveTheme.darkTheme(),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: HomeScreen(
        onToggleTheme: _toggleTheme,
        isDarkMode: _isDarkMode,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        IntlDefaultMaterialLocalization.delegate,
      ],
      supportedLocales: const [
        Locale('sv', 'SE'),
        Locale('en', 'US'),
      ],
      localeListResolutionCallback: (supportedLocales, compactLocale) {
        return compactLocale ?? Locale('sv', 'SE');
      },
      locale: Intl.defaultLocale,
    );
  }
}