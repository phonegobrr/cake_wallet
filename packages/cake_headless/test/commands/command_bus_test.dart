import 'package:cake_headless/commands/command.dart';
import 'package:cake_headless/commands/command_bus.dart';
import 'package:cake_headless/commands/command_result.dart';
import 'package:cake_headless/ports_impl/cli_path_provider.dart';
import 'package:cake_headless/ports_impl/filesystem_asset_loader.dart';
import 'package:cake_headless/ports_impl/json_settings_store.dart';
import 'package:cake_headless/ports_impl/stderr_logger.dart';
import 'package:cake_headless/ports_impl/stdin_secret_input.dart';
import 'package:cake_headless/ports/secure_storage_port.dart';
import 'package:cake_headless/runtime_context.dart';
import 'package:test/test.dart';

class _MockSecureStorage implements SecureStoragePort {
  final Map<String, String> _data = {};
  @override
  Future<String?> read({required String key}) async => _data[key];
  @override
  Future<void> write({required String key, required String value}) async =>
      _data[key] = value;
  @override
  Future<void> delete({required String key}) async => _data.remove(key);
  @override
  Future<Map<String, String>> readAll() async => Map.unmodifiable(_data);
}

class _TestCommand extends WalletCommand<String> {
  @override
  String get name => 'test.echo';
  @override
  String get description => 'Echo test';
  @override
  Map<String, CommandArg> get args => {
        'message': CommandArg(
            name: 'message', description: 'Message to echo', required: true),
      };

  @override
  Future<CommandResult<String>> execute(
      CakeRuntimeContext ctx, Map<String, dynamic> params) async {
    return CommandResult.ok(params['message'] as String);
  }
}

void main() {
  group('CommandBus', () {
    late CakeRuntimeContext ctx;
    late CommandBus bus;

    setUp(() {
      ctx = CakeRuntimeContext(
        secureStorage: _MockSecureStorage(),
        settings: JsonSettingsStore('/tmp/test_settings.json'),
        pathProvider: CliPathProvider(),
        assetLoader: FilesystemAssetLoader('.'),
        logger: StderrLogger(),
        interaction: StdinUserInteraction(autoConfirm: true),
      );
      bus = CommandBus(ctx);
    });

    test('registers and dispatches commands', () async {
      bus.register(_TestCommand());
      final result = await bus.dispatch('test.echo', {'message': 'hello'});
      expect(result.success, isTrue);
      expect(result.data, 'hello');
    });

    test('returns error for unknown command', () async {
      final result = await bus.dispatch('nonexistent', {});
      expect(result.success, isFalse);
      expect(result.errorCode, 'UNKNOWN_COMMAND');
    });

    test('validates required args', () async {
      bus.register(_TestCommand());
      final result = await bus.dispatch('test.echo', {});
      expect(result.success, isFalse);
      expect(result.errorCode, 'MISSING_ARG');
    });

    test('prevents duplicate registration', () {
      bus.register(_TestCommand());
      expect(() => bus.register(_TestCommand()), throwsStateError);
    });
  });
}
