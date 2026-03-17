import 'dart:io';

import 'package:cake_headless/ports/logger_port.dart';

/// Logs to stderr only. Critical for MCP stdio mode where stdout is protocol-only.
class StderrLogger implements LoggerPort {
  static const bool _kDebugMode = !bool.fromEnvironment('dart.vm.product');

  @override
  void info(String message) => stderr.writeln('[INFO] $message');

  @override
  void error(String message, [Object? e, StackTrace? st]) =>
      stderr.writeln('[ERROR] $message${e != null ? ' $e' : ''}${st != null ? '\n$st' : ''}');

  @override
  void debug(String message) {
    if (_kDebugMode) stderr.writeln('[DEBUG] $message');
  }

  @override
  void warn(String message) => stderr.writeln('[WARN] $message');
}
