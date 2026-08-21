import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/stop_repository.dart';
import 'repositories/realtime_repository.dart';
import 'services/app_services.dart';
import 'theme/m3_expressive_theme.dart';
import 'views/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'sv_SE';
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<RealtimeRepository>.value(
          value: widget.services!.realtimeRepository,
        ),
        Provider<StopRepository>.value(
          value: widget.services!.stopRepository,
        ),
      ],
      child: MaterialApp(
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
        ],
        supportedLocales: const [
          Locale('sv', 'SE'),
          Locale('en', 'US'),
        ],
        localeListResolutionCallback: (supportedLocales, compactLocale) {
          return compactLocale ?? const Locale('sv', 'SE');
        },
        locale: const Locale('sv', 'SE'),
      ),
    );
  }
}