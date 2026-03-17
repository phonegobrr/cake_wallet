import 'dart:typed_data';

/// Stub implementation for headless builds.
/// In production, use the real cake_backup package.

Future<Uint8List> encrypt(String password, Uint8List data) async {
  throw UnimplementedError('cake_backup stub: encrypt not available in headless mode');
}

Future<Uint8List> decrypt(String password, Uint8List data) async {
  throw UnimplementedError('cake_backup stub: decrypt not available in headless mode');
}

Future<Uint8List> encryptRaw(Uint8List key, Uint8List data) async {
  throw UnimplementedError('cake_backup stub: encryptRaw not available in headless mode');
}
