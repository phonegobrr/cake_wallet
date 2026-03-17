import 'dart:io';

import 'package:cake_headless/ports/path_provider_port.dart';
import 'package:cw_core/root_dir.dart' as root_dir;

/// CLI path provider that delegates to cw_core/root_dir.dart for consistency.
/// If a root dir override was set via setRootDirOverride(), that takes precedence.
/// Otherwise uses the same platform-specific logic as the main app.
class CliPathProvider implements PathProviderPort {
  @override
  Future<String> getAppDir() async {
    final dir = await root_dir.getAppDir();
    return dir.path;
  }

  @override
  Future<String> getCacheDir() async {
    const String appName = 'cake_wallet';
    if (Platform.isLinux) {
      final xdg = Platform.environment['XDG_CACHE_HOME'];
      if (xdg != null && xdg.isNotEmpty) return '$xdg/$appName';
      final home = Platform.environment['HOME'];
      if (home != null) return '$home/.cache/$appName';
      return '.${appName}_cache';
    }
    if (Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      if (home != null) return '$home/Library/Caches/$appName';
      return '.${appName}_cache';
    }
    if (Platform.isWindows) {
      final localAppData = Platform.environment['LOCALAPPDATA'];
      if (localAppData != null) return '$localAppData\\$appName\\cache';
      return '.${appName}_cache';
    }
    return '.${appName}_cache';
  }
}
