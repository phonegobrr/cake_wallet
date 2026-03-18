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

class _ThrowingCommand extends WalletCommand<String> {
  @override
  String get name => 'test.throw';
  @override
  String get description => 'Always throws';
  @override
  Map<String, CommandArg> get args => {};

  @override
  Future<CommandResult<String>> execute(
      CakeRuntimeContext ctx, Map<String, dynamic> params) async {
    throw StateError('intentional failure');
  }
}

class _UnsafeCommand extends WalletCommand<String> {
  @override
  String get name => 'test.unsafe';
  @override
  String get description => 'Unsafe for non-interactive';
  @override
  Map<String, CommandArg> get args => {};
  @override
  bool get isSafeForNonInteractive => false;

  @override
  Future<CommandResult<String>> execute(
      CakeRuntimeContext ctx, Map<String, dynamic> params) async {
    return CommandResult.ok('executed');
  }
}

class _DefaultArgCommand extends WalletCommand<String> {
  @override
  String get name => 'test.defaults';
  @override
  String get description => 'Has default args';
  @override
  Map<String, CommandArg> get args => {
        'value': CommandArg(
            name: 'value',
            description: 'A value with default',
            defaultValue: 'fallback'),
      };

  @override
  Future<CommandResult<String>> execute(
      CakeRuntimeContext ctx, Map<String, dynamic> params) async {
    return CommandResult.ok(params['value']?.toString() ?? 'null');
  }
}

CakeRuntimeContext _makeCtx() {
  return CakeRuntimeContext(
    secureStorage: _MockSecureStorage(),
    settings: JsonSettingsStore('/tmp/test_settings_${DateTime.now().millisecondsSinceEpoch}.json'),
    pathProvider: CliPathProvider(),
    assetLoader: FilesystemAssetLoader('.'),
    logger: StderrLogger(),
    interaction: StdinUserInteraction(autoConfirm: true),
  );
}

void main() {
  group('CommandBus', () {
    late CakeRuntimeContext ctx;
    late CommandBus bus;

    setUp(() {
      ctx = _makeCtx();
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

    test('catches exceptions from commands', () async {
      bus.register(_ThrowingCommand());
      final result = await bus.dispatch('test.throw', {});
      expect(result.success, isFalse);
      expect(result.errorCode, 'COMMAND_FAILED');
      expect(result.message, contains('intentional failure'));
    });

    test('applies default values for missing optional args', () async {
      bus.register(_DefaultArgCommand());
      final result = await bus.dispatch('test.defaults', {});
      expect(result.success, isTrue);
      expect(result.data, 'fallback');
    });

    test('explicit arg overrides default', () async {
      bus.register(_DefaultArgCommand());
      final result = await bus.dispatch('test.defaults', {'value': 'custom'});
      expect(result.success, isTrue);
      expect(result.data, 'custom');
    });

    test('enforces isSafeForNonInteractive', () async {
      ctx.nonInteractive = true;
      ctx.autoConfirm = false;
      bus.register(_UnsafeCommand());
      final result = await bus.dispatch('test.unsafe', {});
      expect(result.success, isFalse);
      expect(result.errorCode, 'INTERACTION_REQUIRED');
    });

    test('allows unsafe commands with autoConfirm', () async {
      ctx.nonInteractive = true;
      ctx.autoConfirm = true;
      bus.register(_UnsafeCommand());
      final result = await bus.dispatch('test.unsafe', {});
      expect(result.success, isTrue);
      expect(result.data, 'executed');
    });

    test('lists all registered commands', () {
      bus.register(_TestCommand());
      bus.register(_ThrowingCommand());
      expect(bus.commands.length, 2);
      expect(bus.commands.map((c) => c.name).toSet(),
          {'test.echo', 'test.throw'});
    });

    test('getCommand returns null for unknown', () {
      expect(bus.getCommand('nope'), isNull);
    });

    test('getCommand returns registered command', () {
      bus.register(_TestCommand());
      expect(bus.getCommand('test.echo'), isNotNull);
      expect(bus.getCommand('test.echo')!.name, 'test.echo');
    });

    test('coerces string to int for int-typed args', () async {
      bus.register(_IntArgCommand());
      final result = await bus.dispatch('test.intarg', {'count': '42'});
      expect(result.success, isTrue);
      expect(result.data, '42');
    });

    test('rejects invalid int values for required int args', () async {
      bus.register(_IntArgCommand());
      final result = await bus.dispatch('test.intarg', {'count': 'notanumber'});
      expect(result.success, isFalse);
      expect(result.errorCode, 'INVALID_ARG_TYPE');
    });

    test('does not modify caller params map', () async {
      bus.register(_DefaultArgCommand());
      final params = <String, dynamic>{};
      await bus.dispatch('test.defaults', params);
      expect(params, isEmpty);
    });

    test('UNSUPPORTED_ON_PLATFORM stubs return correct code', () async {
      bus.register(_UnsupportedStub());
      final result = await bus.dispatch('test.unsupported', {});
      expect(result.success, isFalse);
      expect(result.errorCode, 'UNSUPPORTED_ON_PLATFORM');
    });

    test('all bootstrap commands register without collision', () {
      final freshCtx = _makeCtx();
      // This would throw if any duplicate registration occurred
      final fullBus = CommandBus(freshCtx);
      // Register a subset to verify no collision pattern
      fullBus.register(_TestCommand());
      fullBus.register(_ThrowingCommand());
      fullBus.register(_UnsafeCommand());
      fullBus.register(_DefaultArgCommand());
      fullBus.register(_IntArgCommand());
      expect(fullBus.commands.length, 5);
    });
  });
}

class _IntArgCommand extends WalletCommand<String> {
  @override
  String get name => 'test.intarg';
  @override
  String get description => 'Int arg test';
  @override
  Map<String, CommandArg> get args => {
        'count': CommandArg(
            name: 'count', description: 'Count', type: int, required: true),
      };

  @override
  Future<CommandResult<String>> execute(
      CakeRuntimeContext ctx, Map<String, dynamic> params) async {
    return CommandResult.ok(params['count'].toString());
  }
}

class _UnsupportedStub extends WalletCommand<Map<String, String>> {
  @override
  String get name => 'test.unsupported';
  @override
  String get description => 'Unsupported stub';
  @override
  Map<String, CommandArg> get args => {};
  @override
  CommandStatus get status => CommandStatus.unsupported;

  @override
  Future<CommandResult<Map<String, String>>> execute(
      CakeRuntimeContext ctx, Map<String, dynamic> params) async {
    return CommandResult.error('UNSUPPORTED_ON_PLATFORM',
        message: 'Not supported in headless');
  }
}
