import 'dart:io';

import 'package:cake_headless/ports/path_provider_port.dart';

class CliPathProvider implements PathProviderPort {
  @override
  Future<String> getAppDir() async {
    const String appName = 'cake_wallet';
    if (Platform.isLinux) {
      final xdg = Platform.environment['XDG_DATA_HOME'];
      if (xdg != null && xdg.isNotEmpty) return '$xdg/$appName';
      final home = Platform.environment['HOME'];
      if (home != null) return '$home/.config/$appName';
      return '.$appName';
    }
    if (Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      if (home != null) return '$home/Library/Application Support/$appName';
      return '.$appName';
    }
    if (Platform.isWindows) {
      final appdata = Platform.environment['APPDATA'];
      if (appdata != null) return '$appdata\\$appName';
      return '.$appName';
    }
    return '.$appName';
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
