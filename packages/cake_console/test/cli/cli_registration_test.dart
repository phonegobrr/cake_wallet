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
        '/tmp/test_cli_${DateTime.now().millisecondsSinceEpoch}.json'),
    pathProvider: CliPathProvider(),
    assetLoader: FilesystemAssetLoader('.'),
    logger: StderrLogger(),
    interaction: StdinUserInteraction(autoConfirm: true),
  );
}

void main() {
  group('CLI command registration', () {
    late CommandBus bus;

    setUp(() {
      final ctx = _makeCtx();
      bus = registerAllCommands(ctx);
    });

    test('all commands register without collision', () {
      // registerAllCommands would throw StateError if any name collision
      expect(bus.commands.length, greaterThan(50));
    });

    test('send is registered as standalone with subcommands', () {
      expect(bus.getCommand('send'), isNotNull);
      expect(bus.getCommand('send.preview'), isNotNull);
      expect(bus.getCommand('send.commit'), isNotNull);
      expect(bus.getCommand('send.max'), isNotNull);
      expect(bus.getCommand('send.send-all'), isNotNull);
    });

    test('wallet.restore has nested subcommands', () {
      expect(bus.getCommand('wallet.restore.seed'), isNotNull);
      expect(bus.getCommand('wallet.restore.keys'), isNotNull);
    });

    test('wallet.sync has nested subcommands', () {
      expect(bus.getCommand('wallet.sync.start'), isNotNull);
      expect(bus.getCommand('wallet.sync.stop'), isNotNull);
    });

    test('wallet.sign and wallet.verify are real commands', () {
      final sign = bus.getCommand('wallet.sign');
      final verify = bus.getCommand('wallet.verify');
      expect(sign, isNotNull);
      expect(verify, isNotNull);
      expect(sign!.status, CommandStatus.implemented);
      expect(verify!.status, CommandStatus.implemented);
    });

    test('unsupported commands have correct status', () {
      final buyProviders = bus.getCommand('buy.providers');
      expect(buyProviders, isNotNull);
      expect(buyProviders!.status, CommandStatus.unsupported);
    });

    test('command args are typed correctly', () {
      final open = bus.getCommand('wallet.open');
      expect(open, isNotNull);
      expect(open!.args['type']!.type, int);
      expect(open.args['name']!.required, isTrue);
    });

    test('default values work as Object? not String?', () {
      final rescan = bus.getCommand('wallet.rescan');
      expect(rescan, isNotNull);
      expect(rescan!.args['height']!.defaultValue, 0);
      expect(rescan.args['height']!.defaultValue, isA<int>());
    });
  });
}
