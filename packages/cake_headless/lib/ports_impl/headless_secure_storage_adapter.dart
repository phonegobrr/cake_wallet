import 'package:cw_core/secure_storage.dart';
import 'package:cake_headless/ports/secure_storage_port.dart';

/// Bridges [SecureStoragePort] (headless file-based) to [SecureStorage] (cw_core interface).
/// Used by [initializeHeadlessCore] which expects the cw_core SecureStorage type.
class HeadlessSecureStorageAdapter implements SecureStorage {
  final SecureStoragePort _port;

  HeadlessSecureStorageAdapter(this._port);

  @override
  Future<String?> read({required String key}) => _port.read(key: key);

  @override
  Future<String?> readNoIOptions({required String key}) => _port.read(key: key);

  @override
  Future<void> write({required String key, required String? value}) =>
      _port.write(key: key, value: value ?? '');

  @override
  Future<void> delete({required String key}) => _port.delete(key: key);

  @override
  Future<Map<String, String>> readAll() => _port.readAll();

  @override
  Future<void> deleteAll() async {
    final all = await _port.readAll();
    for (final key in all.keys) {
      await _port.delete(key: key);
    }
  }
}
