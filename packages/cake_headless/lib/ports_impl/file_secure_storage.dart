import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cake_headless/ports/secure_storage_port.dart';
import 'package:encrypt/encrypt.dart';

/// Encrypted file-based secure storage for CLI/TUI/server.
/// Uses AES encryption with a provided key.
class FileSecureStorage implements SecureStoragePort {
  final String _filePath;
  final Uint8List _encryptionKey;

  FileSecureStorage(this._filePath, this._encryptionKey);

  Map<String, String>? _cache;

  Future<Map<String, String>> _load() async {
    if (_cache != null) return _cache!;
    final file = File(_filePath);
    if (!await file.exists()) {
      _cache = {};
      return _cache!;
    }
    final encrypted = await file.readAsString();
    final decrypted = _decrypt(encrypted);
    _cache = Map<String, String>.from(jsonDecode(decrypted) as Map);
    return _cache!;
  }

  Future<void> _save() async {
    final data = jsonEncode(_cache ?? {});
    final encrypted = _encrypt(data);
    final file = File(_filePath);
    await file.parent.create(recursive: true);
    await file.writeAsString(encrypted);
  }

  String _encrypt(String plaintext) {
    final key = Key(Uint8List.fromList(_encryptionKey.take(32).toList()));
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  String _decrypt(String ciphertext) {
    final parts = ciphertext.split(':');
    if (parts.length != 2) throw StateError('Invalid encrypted data format');
    final iv = IV.fromBase64(parts[0]);
    final key = Key(Uint8List.fromList(_encryptionKey.take(32).toList()));
    final encrypter = Encrypter(AES(key));
    return encrypter.decrypt64(parts[1], iv: iv);
  }

  @override
  Future<String?> read({required String key}) async {
    final data = await _load();
    return data[key];
  }

  @override
  Future<void> write({required String key, required String value}) async {
    await _load();
    _cache![key] = value;
    await _save();
  }

  @override
  Future<void> delete({required String key}) async {
    await _load();
    _cache!.remove(key);
    await _save();
  }

  @override
  Future<Map<String, String>> readAll() async {
    return Map.unmodifiable(await _load());
  }
}
