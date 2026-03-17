import 'dart:convert';

import 'package:cake_headless/cake_headless.dart';
import 'package:cake_console/mcp/mcp_server.dart';
import 'package:test/test.dart';

void main() {
  group('McpServer', () {
    late CakeRuntimeContext ctx;
    late CommandBus bus;

    setUp(() {
      ctx = CakeRuntimeContext(
        secureStorage: _MockSecureStorage(),
        settings: JsonSettingsStore('/tmp/test_mcp_settings.json'),
        pathProvider: CliPathProvider(),
        assetLoader: FilesystemAssetLoader('.'),
        logger: StderrLogger(),
        interaction: StdinUserInteraction(autoConfirm: true),
      );
      bus = CommandBus(ctx);
      bus.register(ListWalletsCommand());
      bus.register(GetBalanceCommand());
    });

    test('command bus has registered commands', () {
      expect(bus.commands.length, 2);
      expect(bus.getCommand('wallet.list'), isNotNull);
      expect(bus.getCommand('balance.get'), isNotNull);
    });

    test('wallet.list returns empty list', () async {
      final result = await bus.dispatch('wallet.list', {});
      expect(result.success, isTrue);
      expect(result.data, isA<List>());
    });

    test('balance.get returns error when no wallet open', () async {
      final result = await bus.dispatch('balance.get', {});
      expect(result.success, isFalse);
      expect(result.errorCode, 'NO_WALLET');
    });
  });
}

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
