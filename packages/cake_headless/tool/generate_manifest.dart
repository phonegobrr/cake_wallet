import 'dart:convert';
import 'dart:io';

import 'package:cake_headless/bootstrap.dart';
import 'package:cake_headless/runtime_context.dart';
import 'package:cake_headless/ports/secure_storage_port.dart';
import 'package:cake_headless/ports/settings_store_port.dart';
import 'package:cake_headless/ports/path_provider_port.dart';
import 'package:cake_headless/ports/asset_loader_port.dart';
import 'package:cake_headless/ports/logger_port.dart';
import 'package:cake_headless/ports/user_interaction_port.dart';

/// Generate a capability manifest from the command registry.
/// No side effects — does not acquire locks, open databases, or load wallets.
///
/// Usage:
///   dart run tool/generate_manifest.dart              # write to stdout
///   dart run tool/generate_manifest.dart --verify     # compare against existing manifest
void main(List<String> args) {
  final verify = args.contains('--verify');
  final outputPath = args.contains('--output')
      ? args[args.indexOf('--output') + 1]
      : null;

  // Create a dummy context with no-op ports (no side effects)
  final ctx = CakeRuntimeContext(
    secureStorage: _NoOpSecureStorage(),
    settings: _NoOpSettings(),
    pathProvider: _NoOpPathProvider(),
    assetLoader: _NoOpAssetLoader(),
    logger: _NoOpLogger(),
    interaction: _NoOpInteraction(),
  );

  final bus = registerAllCommands(ctx);

  final manifest = {
    'version': '0.1.0',
    'generated': DateTime.now().toIso8601String(),
    'commands': bus.commands.map((cmd) => {
          'name': cmd.name,
          'description': cmd.description,
          'safe_for_non_interactive': cmd.isSafeForNonInteractive,
          'status': cmd.status.name,
          'destructive': cmd.isDestructive,
          'args': cmd.args.map((k, v) => MapEntry(k, {
                'type': v.type.toString(),
                'required': v.required,
                'description': v.description,
                if (v.choices != null) 'choices': v.choices,
                if (v.defaultValue != null) 'default': v.defaultValue,
              })),
        })
        .toList()
      ..sort((a, b) =>
          (a['name'] as String).compareTo(b['name'] as String)),
  };

  final output = const JsonEncoder.withIndent('  ').convert(manifest);

  if (verify) {
    final existingFile = File(outputPath ?? 'command_manifest.json');
    if (!existingFile.existsSync()) {
      stderr.writeln('ERROR: Manifest file not found: ${existingFile.path}');
      stderr.writeln('Run without --verify to generate it.');
      exit(1);
    }
    final existing = existingFile.readAsStringSync();
    // Compare ignoring 'generated' timestamp
    final existingJson = jsonDecode(existing) as Map<String, dynamic>;
    final newJson = jsonDecode(output) as Map<String, dynamic>;
    existingJson.remove('generated');
    newJson.remove('generated');
    if (jsonEncode(existingJson) != jsonEncode(newJson)) {
      stderr.writeln('ERROR: Manifest drift detected!');
      stderr.writeln('Regenerate with: dart run tool/generate_manifest.dart');
      exit(1);
    }
    stdout.writeln('Manifest verified: no drift detected.');
    return;
  }

  if (outputPath != null) {
    File(outputPath).writeAsStringSync(output);
    stderr.writeln('Manifest written to $outputPath');
  } else {
    stdout.writeln(output);
  }
}

// No-op port implementations for manifest generation
class _NoOpSecureStorage implements SecureStoragePort {
  @override Future<String?> read({required String key}) async => null;
  @override Future<void> write({required String key, required String value}) async {}
  @override Future<void> delete({required String key}) async {}
  @override Future<Map<String, String>> readAll() async => {};
}

class _NoOpSettings implements SettingsStorePort {
  @override Future<String?> getString(String key) async => null;
  @override Future<void> setString(String key, String value) async {}
  @override Future<int?> getInt(String key) async => null;
  @override Future<void> setInt(String key, int value) async {}
  @override Future<bool?> getBool(String key) async => null;
  @override Future<void> setBool(String key, bool value) async {}
  @override Future<Map<String, dynamic>> readAll() async => {};
}

class _NoOpPathProvider implements PathProviderPort {
  @override Future<String> getAppDir() async => '/tmp/cake_manifest_gen';
  @override Future<String> getCacheDir() async => '/tmp/cake_manifest_gen/cache';
}

class _NoOpAssetLoader implements AssetLoaderPort {
  @override Future<String> loadString(String path) async => '';
  @override Future<List<int>> loadBytes(String path) async => [];
}

class _NoOpLogger implements LoggerPort {
  @override void info(String message) {}
  @override void error(String message, [Object? error, StackTrace? stackTrace]) {}
  @override void debug(String message) {}
  @override void warn(String message) {}
}

class _NoOpInteraction implements UserInteractionPort {
  @override Future<bool> confirm(String message) async => false;
  @override Future<String?> promptText(String message, {bool obscure = false}) async => null;
  @override Future<int?> pickOption(String message, List<String> options) async => null;
}
