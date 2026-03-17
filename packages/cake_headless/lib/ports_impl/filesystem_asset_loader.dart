import 'dart:io';

import 'package:cake_headless/ports/asset_loader_port.dart';

class FilesystemAssetLoader implements AssetLoaderPort {
  final String _basePath;

  FilesystemAssetLoader(this._basePath);

  @override
  Future<String> loadString(String path) async {
    final file = File('$_basePath/$path');
    if (!await file.exists()) {
      throw StateError('Asset not found: $path (looked in $_basePath)');
    }
    return file.readAsString();
  }

  @override
  Future<List<int>> loadBytes(String path) async {
    final file = File('$_basePath/$path');
    if (!await file.exists()) {
      throw StateError('Asset not found: $path (looked in $_basePath)');
    }
    return file.readAsBytes();
  }
}
