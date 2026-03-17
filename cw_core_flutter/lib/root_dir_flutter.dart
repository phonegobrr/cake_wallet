import 'dart:io';

import 'package:cw_core/root_dir.dart';
import 'package:path_provider/path_provider.dart';

/// Call this early in Flutter app startup to configure the root dir
/// using path_provider, before any wallet operations.
Future<void> initFlutterRootDir() async {
  final dir = await _getFlutterAppDir();
  setRootDirOverride(dir.path);
}

Future<Directory> _getFlutterAppDir() async {
  if (Platform.isWindows) {
    return await getApplicationSupportDirectory();
  } else if (Platform.isLinux) {
    return await getApplicationDocumentsDirectory();
  } else {
    return await getApplicationDocumentsDirectory();
  }
}
