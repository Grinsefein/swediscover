import 'package:flutter/material.dart';

import '../services/app_settings_service.dart';

class SettingsView extends StatefulWidget {
  final AppSettingsService settings;

  const SettingsView({super.key, required this.settings});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late bool _useDirectApi;
  late TextEditingController _bffUrlController;

  final Map<String, TextEditingController> _keyControllers = {};

  final List<Map<String, String>> _managedKeys = [
    {'key': 'TRAFIKLAB_API_KEY', 'label': 'Trafiklab API Key (General)'},
    {'key': 'RES_ROBOT_V2_1', 'label': 'ResRobot v2.1 (Journey Planning)'},
    {'key': 'GTFS_SWEDEN_3_REALTIME', 'label': 'GTFS Sweden 3 Realtime'},
    {'key': 'GTFS_SWEDEN_3_STATIC', 'label': 'GTFS Sweden 3 Static'},
    {'key': 'STOPS', 'label': 'Stops & Locations API'},
    {'key': 'TRAFIKVERKET_API_KEY', 'label': 'Trafikverket Open API'},
    {'key': 'MAP_TILER_API_KEY', 'label': 'MapTiler Vector Tiles Key'},
  ];

  @override
  void initState() {
    super.initState();
    _useDirectApi = widget.settings.useDirectApi;
    _bffUrlController = TextEditingController(text: widget.settings.bffServerUrl);

    for (final item in _managedKeys) {
      final k = item['key']!;
      _keyControllers[k] = TextEditingController(
        text: widget.settings.getKey(k),
      );
    }
  }

  @override
  void dispose() {
    _bffUrlController.dispose();
    for (final controller in _keyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveAll() {
    widget.settings.setUseDirectApi(_useDirectApi);
    widget.settings.setBffServerUrl(_bffUrlController.text.trim());

    _keyControllers.forEach((key, controller) {
      widget.settings.setKey(key, controller.text.trim());
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Inställningar sparades successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('API & App Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded),
            onPressed: _saveAll,
            tooltip: 'Spara inställningar',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.hub_rounded, color: theme.colorScheme.onPrimaryContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Anslutningsläge (Connection Mode)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Direkt API-Anrop (Direct Mode)'),
                    subtitle: const Text(
                      'Hämta data direkt från Trafiklab/Trafikverket på enheten',
                    ),
                    value: _useDirectApi,
                    onChanged: (val) {
                      setState(() {
                        _useDirectApi = val;
                      });
                    },
                  ),
                  if (!_useDirectApi)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: TextField(
                        controller: _bffUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Go BFF Server URL',
                          hintText: 'http://localhost:8080 oder http://10.0.2.2:8080',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'API-Nycklar (.env Overrides)',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Redigera API-nycklar dynamiskt utan att behöva kompilera om appen:',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          ..._managedKeys.map((item) {
            final keyName = item['key']!;
            final label = item['label']!;
            final controller = _keyControllers[keyName]!;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: label,
                  helperText: keyName,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () => controller.clear(),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _saveAll,
            icon: const Icon(Icons.save_rounded),
            label: const Text('Spara Alla Ändringar'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}
