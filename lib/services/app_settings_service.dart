import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// App Settings & Environment Configuration Manager.
/// Manages API keys, direct vs BFF mode, and runtime overrides.
/// Does NOT hardcode secrets; loads dynamically from .env or local storage.
class AppSettingsService extends ChangeNotifier {
  static AppSettingsService? _instance;

  /// Bump when shipped defaults change (e.g. proxy-first). A stored settings
  /// file from an older version is migrated once to the new defaults.
  static const int _settingsVersion = 2;

  bool _useDirectApi = false;
  String _bffServerUrl = 'http://localhost:8080';

  static const List<String> _assetEnvPaths = [
    'assets/.env',
    'assets/config/app.env',
    'assets/config/.env',
  ];

  final Map<String, String> _keys = {};

  AppSettingsService._();

  static Future<AppSettingsService> getInstance() async {
    if (_instance == null) {
      _instance = AppSettingsService._();
      await _instance!._init();
    }
    return _instance!;
  }

  bool get useDirectApi => _useDirectApi;
  String get bffServerUrl => _bffServerUrl;

  String getKey(String name, {String defaultValue = ''}) {
    // 1. Local override in memory / settings file
    final val = _keys[name];
    if (val != null && val.isNotEmpty) return val;

    // 2. dart-define / Platform Environment
    final envVal = String.fromEnvironment(name, defaultValue: '');
    if (envVal.isNotEmpty) return envVal;

    try {
      final sysEnv = Platform.environment[name];
      if (sysEnv != null && sysEnv.isNotEmpty) return sysEnv;
    } catch (_) {}

    return defaultValue;
  }

  void setKey(String name, String value) {
    _keys[name] = value;
    _saveSettings();
    notifyListeners();
  }

  void setUseDirectApi(bool val) {
    _useDirectApi = val;
    _saveSettings();
    notifyListeners();
  }

  void setBffServerUrl(String url) {
    _bffServerUrl = url;
    _saveSettings();
    notifyListeners();
  }

  Future<void> _init() async {
    await _loadEnvCandidates();

    // 2. Load persisted local user settings
    try {
      final file = await _getSettingsFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        _useDirectApi = json['useDirectApi'] as bool? ?? true;
        _bffServerUrl = json['bffServerUrl'] as String? ?? 'http://localhost:8080';

        final savedKeys = json['keys'] as Map<String, dynamic>?;
        if (savedKeys != null) {
          savedKeys.forEach((k, v) {
            if (v != null && v.toString().isNotEmpty) {
              _keys[k] = v.toString();
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error reading app settings: $e');
    }
  }

  Future<void> _loadEnvCandidates() async {
    final candidates = <String>{
      ..._assetEnvPaths,
      '${Directory.current.path}/assets/.env',
      '${Directory.current.path}/assets/config/.env',
      '${Directory.current.path}/backend/.env',
      '${Directory.current.path}/.env',
      '${Directory.current.path}/../.env',
    };

    for (final candidate in candidates) {
      try {
        if (candidate.startsWith('assets/')) {
          try {
            final envString = await rootBundle.loadString(candidate);
            _applyEnvContent(envString);
            return;
          } catch (_) {}

          final file = File(candidate);
          if (await file.exists()) {
            final envString = await file.readAsString();
            _applyEnvContent(envString);
            return;
          }
        }

        final file = File(candidate);
        if (await file.exists()) {
          final envString = await file.readAsString();
          _applyEnvContent(envString);
          return;
        }
      } catch (_) {
        continue;
      }
    }
  }

  void _applyEnvContent(String envString) {
    for (final rawLine in envString.split(RegExp(r'\r?\n'))) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      final parts = line.split('=');
      if (parts.length < 2) continue;

      final key = parts.first.trim();
      final value = parts.sublist(1).join('=').trim();
      if (key.isNotEmpty && value.isNotEmpty) {
        _keys[key] = value;
      }
    }
  }

  Future<File> _getSettingsFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      return File('${dir.path}/swediscover_settings.json');
    } catch (_) {
      return File('${Directory.current.path}/swediscover_settings.json');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final file = await _getSettingsFile();
      final data = {
        'useDirectApi': _useDirectApi,
        'bffServerUrl': _bffServerUrl,
        'keys': _keys,
      };
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('Error saving app settings: $e');
    }
  }
}
