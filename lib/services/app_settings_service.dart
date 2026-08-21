import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// App Settings & Environment Configuration Manager.
/// Manages API keys, direct vs BFF mode, and runtime overrides.
/// Does NOT hardcode secrets; loads dynamically from .env or local storage.
class AppSettingsService extends ChangeNotifier {
  static AppSettingsService? _instance;

  bool _useDirectApi = true;
  String _bffServerUrl = 'http://localhost:8080';

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
    // 1. Try reading .env if available at runtime
    try {
      final envFile = File('.env');
      if (await envFile.exists()) {
        final lines = await envFile.readAsLines();
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
          final parts = trimmed.split('=');
          if (parts.length >= 2) {
            final key = parts[0].trim();
            final value = parts.sublist(1).join('=').trim();
            if (value.isNotEmpty) {
              _keys[key] = value;
            }
          }
        }
      }
    } catch (_) {}

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

  Future<File> _getSettingsFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/swediscover_settings.json');
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
