/// Platform-agnostic secure storage interface.
///
/// On Flutter: implemented by DefaultSecureStorage (flutter_secure_storage).
/// On headless: implemented by FileSecureStorage (AES-encrypted JSON file).
///
/// This interface lives in cw_core so both the Flutter app and
/// headless packages can reference it without a Flutter dependency.
abstract class SecureStorage {
  Future<String?> read({required String key});
  Future<void> write({required String key, required String? value});
  Future<void> delete({required String key});
  Future<void> deleteAll();
  Future<String?> readNoIOptions({required String key});
  Future<Map<String, String>> readAll();
}
