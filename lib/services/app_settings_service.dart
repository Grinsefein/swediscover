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
  /// v2: proxy-first default. v3: discard stale demo-keys saved by older builds.
  static const int _settingsVersion = 3;

  bool _useDirectApi = false;
  String _bffServerUrl = 'http://localhost:8080';

  static const List<String> _assetEnvPaths = [
    'assets/.env',
    'assets/config/app.env',
    'assets/config/.env',
  ];

  final Map<String, String> _keys = {};

  /// Woher stammt jeder Key? ('assets/.env', 'assets/config/app.env',
  /// '/path/.env', 'saved', 'manual') – für Transparenz im Settings-Screen.
  final Map<String, String> _keySources = {};

  static const List<String> _criticalKeys = [
    'TRAFIKLAB_API_KEY',
    'RES_ROBOT_V2_1',
    'GTFS_SWEDEN_3_STATIC',
    'GTFS_SWEDEN_3_REALTIME',
  ];

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

  /// Quelle des zuletzt gesetzten Werts für einen Key.
  String keySource(String name) {
    final source = _keySources[name];
    if (source != null) return source;
    return getKey(name).isEmpty ? 'missing' : 'dart-define';
  }

  void setKey(String name, String value) {
    _keys[name] = value;
    _keySources[name] = 'manual';
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
        final storedVersion = json['settingsVersion'] as int? ?? 1;

        // Migration: ältere Versionen haben defekte Env-Auflösung gehabt und
        // dabei Platzhalter-/Demo-Keys in die Settings-Datei geschrieben.
        // Diese veralteten Keys werden einmal verworfen, damit die echten
        // gebündelten Keys aus assets/.env wieder greifen.
        final isMigration = storedVersion < _settingsVersion;
        if (isMigration) {
          debugPrint('AppSettings: migrated settings v$storedVersion → v$_settingsVersion '
              '(proxy-first default, stale saved keys discarded).');
        }

        _useDirectApi = json['useDirectApi'] as bool? ?? _useDirectApi;
        _bffServerUrl = json['bffServerUrl'] as String? ?? _bffServerUrl;

        final savedKeys = json['keys'] as Map<String, dynamic>?;
        if (!isMigration && savedKeys != null) {
          savedKeys.forEach((k, v) {
            if (v != null && v.toString().isNotEmpty) {
              _keys[k] = v.toString();
              _keySources[k] = 'saved';
            }
          });
        }

        if (isMigration) {
          await _saveSettings();
        }
      }
    } catch (e) {
      debugPrint('Error reading app settings: $e');
    }

    _logKeySummary();
  }

  /// Einmaliger Startup-Summary: wie viele Keys aus welcher Quelle und ob
  /// kritische Keys fehlen – beendet das Rätselraten über "no API key".
  void _logKeySummary() {
    final bySource = <String, int>{};
    for (final source in _keySources.values) {
      bySource[source] = (bySource[source] ?? 0) + 1;
    }
    debugPrint('AppSettings: ${_keys.length} API-Keys geladen aus $bySource');

    final missing = _criticalKeys.where((k) => getKey(k).isEmpty).toList();
    if (missing.isNotEmpty) {
      debugPrint('⚠️ AppSettings: kritische Keys fehlen: $missing '
          '(assets/.env korrekt gebündelt? Nach pubspec-Änderungen full restart!)');
    } else {
      debugPrint('✅ AppSettings: alle kritischen Keys vorhanden');
    }
  }

  /// Lädt alle Env-Kandidaten und merged sie per Key.
  /// Erster nicht-leerer Wert gewinnt; es wird nicht mehr nach dem ersten
  /// erfolgreichen Kandidaten abgebrochen (das hatte die echten Keys in
  /// assets/.env hinter den demo-Platzhaltern in assets/config/app.env versteckt).
  Future<void> _loadEnvCandidates() async {
    final candidates = <String>{
      ..._assetEnvPaths,
      '${Directory.current.path}/assets/.env',
      '${Directory.current.path}/assets/config/app.env',
      '${Directory.current.path}/backend/.env',
      '${Directory.current.path}/.env',
      '${Directory.current.path}/../.env',
    };

    for (final candidate in candidates) {
      String? envString;

      try {
        if (candidate.startsWith('assets/')) {
          try {
            envString = await rootBundle.loadString(candidate);
          } catch (_) {
            envString = null;
          }
        }

        envString ??= () {
          try {
            final file = File(candidate);
            return file.existsSync() ? file.readAsStringSync() : null;
          } catch (_) {
            return null;
          }
        }();

        if (envString != null && envString.isNotEmpty) {
          _applyEnvContent(envString, source: candidate);
        }
      } catch (_) {
        continue;
      }
    }
  }

  void _applyEnvContent(String envString, {required String source}) {
    for (final rawLine in envString.split(RegExp(r'\r?\n'))) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      final parts = line.split('=');
      if (parts.length < 2) continue;

      final key = parts.first.trim();
      final value = parts.sublist(1).join('=').trim();
      if (key.isNotEmpty && value.isNotEmpty && !_keys.containsKey(key)) {
        _keys[key] = value;
        _keySources[key] = source;
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
        'settingsVersion': _settingsVersion,
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
