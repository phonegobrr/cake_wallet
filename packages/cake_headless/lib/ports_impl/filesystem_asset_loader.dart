import 'dart:io';

import 'package:cake_headless/ports/asset_loader_port.dart';

/// Filesystem-based asset loader that searches multiple paths.
/// Search order: basePath, executable-relative, cwd fallback.
class FilesystemAssetLoader implements AssetLoaderPort {
  final String _basePath;

  FilesystemAssetLoader(this._basePath);

  @override
  Future<String> loadString(String path) async {
    final file = await _resolve(path);
    return file.readAsString();
  }

  @override
  Future<List<int>> loadBytes(String path) async {
    final file = await _resolve(path);
    return file.readAsBytes();
  }

  Future<File> _resolve(String path) async {
    // 1. Explicit base path
    final primary = File('$_basePath/$path');
    if (await primary.exists()) return primary;

    // 2. Executable-relative
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final exeRelative = File('$exeDir/$path');
    if (await exeRelative.exists()) return exeRelative;

    // 3. Executable-relative assets/ subfolder
    final exeAssets = File('$exeDir/assets/$path');
    if (await exeAssets.exists()) return exeAssets;

    // 4. CWD fallback
    final cwd = File(path);
    if (await cwd.exists()) return cwd;

    throw StateError(
        'Asset not found: $path (searched: $_basePath, $exeDir, cwd)');
  }
}
