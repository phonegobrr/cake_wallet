import 'dart:convert';
import 'dart:io';

import 'package:cake_headless/ports/settings_store_port.dart';

/// JSON file-backed settings store for CLI/TUI/server contexts.
class JsonSettingsStore implements SettingsStorePort {
  final String _filePath;
  Map<String, dynamic>? _cache;

  JsonSettingsStore(this._filePath);

  Future<Map<String, dynamic>> _load() async {
    if (_cache != null) return _cache!;
    final file = File(_filePath);
    if (!await file.exists()) {
      _cache = {};
      return _cache!;
    }
    _cache = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return _cache!;
  }

  Future<void> _save() async {
    final tempFile = File('$_filePath.tmp');
    await tempFile.parent.create(recursive: true);
    await tempFile.writeAsString(jsonEncode(_cache ?? {}));
    await tempFile.rename(_filePath);
  }

  @override
  Future<String?> getString(String key) async => (await _load())[key] as String?;

  @override
  Future<void> setString(String key, String value) async {
    await _load();
    _cache![key] = value;
    await _save();
  }

  @override
  Future<int?> getInt(String key) async => (await _load())[key] as int?;

  @override
  Future<void> setInt(String key, int value) async {
    await _load();
    _cache![key] = value;
    await _save();
  }

  @override
  Future<bool?> getBool(String key) async => (await _load())[key] as bool?;

  @override
  Future<void> setBool(String key, bool value) async {
    await _load();
    _cache![key] = value;
    await _save();
  }
}
