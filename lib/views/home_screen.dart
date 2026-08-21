import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'live_map_view.dart';
import 'departure_monitor_view.dart';
import 'train_inspector_view.dart';
import 'traffic_cams_view.dart';
import 'bff_architecture_view.dart';
import '../repositories/realtime_repository.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const HomeScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    LiveMapView(),
    DepartureMonitorView(),
    TrainInspectorView(),
    TrafficCamsView(),
    BffArchitectureView(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bffService = Provider.of<RealtimeRepository>(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.directions_transit_filled_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
Text(
  Intl.message(
    'SweDiscover',
    desc: 'App name displayed in the header',
  ),
  style: theme.textTheme.titleMedium?.copyWith(
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  ),
),
Text(
  Intl.message(
    'Realtime ÖPNV & Verkehrsdaten SE',
    desc: 'Subtitle text in the app header',
  ),
  style: theme.textTheme.bodySmall?.copyWith(
    color: theme.colorScheme.onSurfaceVariant,
    fontSize: 10,
),
),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Live Collapsing Pill Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.flash_on_rounded, size: 14, color: Color(0xFF10B981)),
                const SizedBox(width: 4),
                Text(
                  Intl.message(
                    'BFF ${bffService.telemetry.networkSavingsPercent.toStringAsFixed(0)}% Saved',
                    desc: 'Telemetry savings percentage display',
                  ),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Theme Switcher Button
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
            onPressed: widget.onToggleTheme,
            tooltip: 'Växla mörkt/ljust tema',
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      // Material 3 Expressive Navigation Bar
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded),
            label: Intl.message('Live-Karta', desc: 'Navigation label for live map'),
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            selectedIcon: Icon(Icons.schedule_rounded),
            label: Intl.message('Avgångar', desc: 'Navigation label for departures'),
          ),
          NavigationDestination(
            icon: Icon(Icons.train_outlined),
            selectedIcon: Icon(Icons.train_rounded),
            label: Intl.message('Tåg Info', desc: 'Navigation label for train info'),
          ),
          NavigationDestination(
            icon: Icon(Icons.videocam_outlined),
            selectedIcon: Icon(Icons.videocam_rounded),
            label: Intl.message('Live-Cams', desc: 'Navigation label for live cameras'),
          ),
          NavigationDestination(
            icon: Icon(Icons.hub_outlined),
            selectedIcon: Icon(Icons.hub_rounded),
            label: Intl.message('BFF Telemetri', desc: 'Navigation label for BFF telemetry'),
          ),
        ],
      ),
    );
  }
}
