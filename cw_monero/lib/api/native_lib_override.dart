import 'dart:ffi';
import 'dart:io';

import 'package:cw_core/root_dir.dart';
import 'package:monero/monero.dart' as monero;

/// Returns the effective path for loading the Monero native library.
/// If [setNativeLibDirOverride] was called in cw_core, prepends that
/// directory to the default library name; otherwise uses [monero.libPath].
String getMoneroLibPath() {
  final override = getNativeLibDirOverride();
  if (override != null) {
    final name = Platform.isAndroid || Platform.isLinux
        ? 'libmonero_libwallet2_api_c.so'
        : monero.libPath;
    return '$override/$name';
  }
  return monero.libPath;
}

/// Opens the Monero native library using the effective path.
DynamicLibrary openMoneroLib() => DynamicLibrary.open(getMoneroLibPath());
