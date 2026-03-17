import 'dart:ffi';
import 'dart:io';

import 'package:cw_core/root_dir.dart';
import 'package:monero/wownero.dart' as wownero;

/// Returns the effective path for loading the Wownero native library.
/// If [setNativeLibDirOverride] was called in cw_core, prepends that
/// directory to the default library name; otherwise uses [wownero.libPath].
String getWowneroLibPath() {
  final override = getNativeLibDirOverride();
  if (override != null) {
    final name = Platform.isAndroid || Platform.isLinux
        ? 'libwownero_libwallet2_api_c.so'
        : wownero.libPath;
    return '$override/$name';
  }
  return wownero.libPath;
}

/// Opens the Wownero native library using the effective path.
DynamicLibrary openWowneroLib() => DynamicLibrary.open(getWowneroLibPath());
