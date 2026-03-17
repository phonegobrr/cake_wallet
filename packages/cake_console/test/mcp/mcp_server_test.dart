import 'package:cake_headless/cake_headless.dart';
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

CakeRuntimeContext _makeCtx() {
  return CakeRuntimeContext(
    secureStorage: _MockSecureStorage(),
    settings: JsonSettingsStore(
        '/tmp/test_mcp_${DateTime.now().millisecondsSinceEpoch}.json'),
    pathProvider: CliPathProvider(),
    assetLoader: FilesystemAssetLoader('.'),
    logger: StderrLogger(),
    interaction: StdinUserInteraction(autoConfirm: true),
  );
}

void main() {
  group('McpServer protocol', () {
    late CakeRuntimeContext ctx;
    late CommandBus bus;

    setUp(() {
      ctx = _makeCtx();
      bus = CommandBus(ctx);
      bus.register(ListWalletsCommand());
      bus.register(GetBalanceCommand());
    });

    test('command bus has registered commands', () {
      expect(bus.commands.length, 2);
      expect(bus.getCommand('wallet.list'), isNotNull);
      expect(bus.getCommand('balance.get'), isNotNull);
    });

    test('wallet.list returns empty list when no services wired', () async {
      final result = await bus.dispatch('wallet.list', {});
      expect(result.success, isTrue);
      expect(result.data, isA<List>());
    });

    test('balance.get returns error when no wallet open', () async {
      final result = await bus.dispatch('balance.get', {});
      expect(result.success, isFalse);
      expect(result.errorCode, 'NO_WALLET');
    });

    test('unknown command returns UNKNOWN_COMMAND', () async {
      final result = await bus.dispatch('nonexistent.tool', {});
      expect(result.success, isFalse);
      expect(result.errorCode, 'UNKNOWN_COMMAND');
    });

    test('missing required arg returns MISSING_ARG', () async {
      bus.register(SendCommand());
      final result = await bus.dispatch('send', {});
      expect(result.success, isFalse);
      expect(result.errorCode, 'MISSING_ARG');
    });

    test('CommandResult.toJson serializes correctly', () {
      final result = CommandResult.ok({'key': 'value'}, message: 'test');
      final json = result.toJson((data) => data as Map<String, dynamic>);
      expect(json['success'], isTrue);
      expect(json['data'], {'key': 'value'});
      expect(json['message'], 'test');
    });

    test('CommandResult error toJson serializes correctly', () {
      final result =
          CommandResult.error('ERR_CODE', message: 'something failed');
      final json = result.toJson((data) => <String, dynamic>{});
      expect(json['success'], isFalse);
      expect(json['error_code'], 'ERR_CODE');
      expect(json['message'], 'something failed');
    });

    test('serializeData handles maps', () {
      // Importing via cli/json_output.dart
      final data = {'a': 1, 'b': 'c'};
      final result = CommandResult.ok(data);
      final json = result.toJson((d) => d);
      expect(json['data']['a'], 1);
    });
  });
}
