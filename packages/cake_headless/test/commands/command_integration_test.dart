import 'package:cake_headless/commands/command_bus.dart';
import 'package:cake_headless/commands/wallet_commands.dart';
import 'package:cake_headless/commands/send_commands.dart';
import 'package:cake_headless/commands/receive_commands.dart';
import 'package:cake_headless/commands/history_commands.dart';
import 'package:cake_headless/commands/node_commands.dart';
import 'package:cake_headless/commands/settings_commands.dart';
import 'package:cake_headless/commands/swap_commands.dart';
import 'package:cake_headless/commands/contact_commands.dart';
import 'package:cake_headless/commands/backup_commands.dart';
import 'package:cake_headless/commands/tor_commands.dart';
import 'package:cake_headless/commands/coin_commands.dart';
import 'package:cake_headless/commands/token_commands.dart';
import 'package:cake_headless/commands/fiat_commands.dart';
import 'package:cake_headless/commands/unsupported_commands.dart';
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

CakeRuntimeContext _makeCtx() {
  return CakeRuntimeContext(
    secureStorage: _MockSecureStorage(),
    settings: JsonSettingsStore(
        '/tmp/test_cmd_${DateTime.now().millisecondsSinceEpoch}.json'),
    pathProvider: CliPathProvider(),
    assetLoader: FilesystemAssetLoader('.'),
    logger: StderrLogger(),
    interaction: StdinUserInteraction(autoConfirm: true),
  );
}

void main() {
  late CakeRuntimeContext ctx;
  late CommandBus bus;

  setUp(() {
    ctx = _makeCtx();
    bus = CommandBus(ctx);
  });

  group('Wallet commands without wallet loaded', () {
    test('wallet.list returns empty when callback not set', () async {
      bus.register(ListWalletsCommand());
      final result = await bus.dispatch('wallet.list', {});
      expect(result.success, isTrue);
      expect(result.data, isEmpty);
    });

    test('balance.get returns NO_WALLET error', () async {
      bus.register(GetBalanceCommand());
      final result = await bus.dispatch('balance.get', {});
      expect(result.success, isFalse);
      expect(result.errorCode, 'NO_WALLET');
    });

    test('wallet.open returns SERVICE_UNAVAILABLE when not wired', () async {
      bus.register(OpenWalletCommand());
      final result =
          await bus.dispatch('wallet.open', {'name': 'test', 'type': 0});
      expect(result.success, isFalse);
      expect(result.errorCode, 'SERVICE_UNAVAILABLE');
    });

    test('wallet.close returns NO_WALLET', () async {
      bus.register(CloseWalletCommand());
      final result = await bus.dispatch('wallet.close', {});
      expect(result.success, isFalse);
      expect(result.errorCode, 'NO_WALLET');
    });

    test('wallet.seed returns NO_WALLET', () async {
      bus.register(GetWalletSeedCommand());
      final result = await bus.dispatch('wallet.seed', {});
      expect(result.success, isFalse);
      expect(result.errorCode, 'NO_WALLET');
    });

    test('wallet.keys returns NO_WALLET', () async {
      bus.register(GetWalletKeysCommand());
      final result = await bus.dispatch('wallet.keys', {});
      expect(result.success, isFalse);
      expect(result.errorCode, 'NO_WALLET');
    });

    test('wallet.rescan returns NO_WALLET', () async {
      bus.register(RescanWalletCommand());
      final result = await bus.dispatch('wallet.rescan', {});
      expect(result.success, isFalse);
      expect(result.errorCode, 'NO_WALLET');
    });
  });

  group('Send commands', () {
    test('send returns NO_WALLET without wallet', () async {
      bus.register(SendCommand());
      final result =
          await bus.dispatch('send', {'address': 'abc', 'amount': '1.0'});
      expect(result.success, isFalse);
      expect(result.errorCode, 'NO_WALLET');
    });
  });

  group('Receive commands', () {
    test('receive.address returns NO_WALLET', () async {
      bus.register(GetReceiveAddressCommand());
      final result = await bus.dispatch('receive.address', {});
      expect(result.success, isFalse);
      expect(result.errorCode, 'NO_WALLET');
    });

    test('receive.list returns NO_WALLET', () async {
      bus.register(ListAddressesCommand());
      final result = await bus.dispatch('receive.list', {});
      expect(result.success, isFalse);
      expect(result.errorCode, 'NO_WALLET');
    });

    test('receive.uri returns NO_WALLET', () async {
      bus.register(GetReceiveUriCommand());
      final result = await bus.dispatch('receive.uri', {});
      expect(result.success, isFalse);
      expect(result.errorCode, 'NO_WALLET');
    });
  });

  group('History commands', () {
    test('history.list returns NO_WALLET', () async {
      bus.register(ListTransactionsCommand());
      final result = await bus.dispatch('history.list', {});
      expect(result.success, isFalse);
      expect(result.errorCode, 'NO_WALLET');
    });

    test('history.details returns NO_WALLET', () async {
      bus.register(GetTransactionDetailsCommand());
      final result =
          await bus.dispatch('history.details', {'id': 'abc123'});
      expect(result.success, isFalse);
      expect(result.errorCode, 'NO_WALLET');
    });
  });

  group('Node commands', () {
    test('nodes.list returns empty when callback not set', () async {
      bus.register(ListNodesCommand());
      final result = await bus.dispatch('nodes.list', {});
      expect(result.success, isTrue);
      expect(result.data, isEmpty);
    });

    test('nodes.add returns SERVICE_UNAVAILABLE', () async {
      bus.register(AddNodeCommand());
      final result = await bus.dispatch('nodes.add', {'uri': 'host:port'});
      expect(result.success, isFalse);
      expect(result.errorCode, 'SERVICE_UNAVAILABLE');
    });

    test('nodes.select returns SERVICE_UNAVAILABLE', () async {
      bus.register(SelectNodeCommand());
      final result =
          await bus.dispatch('nodes.select', {'uri': 'host:port'});
      expect(result.success, isFalse);
      expect(result.errorCode, 'SERVICE_UNAVAILABLE');
    });

    test('nodes.delete returns SERVICE_UNAVAILABLE', () async {
      bus.register(DeleteNodeCommand());
      final result =
          await bus.dispatch('nodes.delete', {'uri': 'host:port'});
      expect(result.success, isFalse);
      expect(result.errorCode, 'SERVICE_UNAVAILABLE');
    });
  });

  group('Settings commands', () {
    test('settings.list returns settings', () async {
      bus.register(ListSettingsCommand());
      final result = await bus.dispatch('settings.list', {});
      expect(result.success, isTrue);
    });

    test('settings.set persists value', () async {
      bus.register(SetSettingCommand());
      bus.register(GetSettingCommand());
      final setResult = await bus.dispatch(
          'settings.set', {'key': 'test_key', 'value': 'test_val'});
      expect(setResult.success, isTrue);

      final getResult =
          await bus.dispatch('settings.get', {'key': 'test_key'});
      // This will fail since settings.list uses different keys, but set/get
      // work through the settings port
      expect(getResult.success, isTrue);
    });
  });

  group('Swap commands', () {
    test('swap.quote returns SERVICE_UNAVAILABLE', () async {
      bus.register(GetSwapQuoteCommand());
      final result = await bus.dispatch(
          'swap.quote', {'from': 'XMR', 'to': 'BTC', 'amount': '1.0'});
      expect(result.success, isFalse);
      expect(result.errorCode, 'SERVICE_UNAVAILABLE');
    });

    test('swap.status returns SERVICE_UNAVAILABLE', () async {
      bus.register(GetSwapStatusCommand());
      final result =
          await bus.dispatch('swap.status', {'trade-id': 'abc123'});
      expect(result.success, isFalse);
      expect(result.errorCode, 'SERVICE_UNAVAILABLE');
    });

    test('swap.create returns SERVICE_UNAVAILABLE', () async {
      bus.register(CreateSwapCommand());
      final result = await bus.dispatch('swap.create', {
        'from': 'XMR',
        'to': 'BTC',
        'amount': '1.0',
        'address': 'addr',
      });
      expect(result.success, isFalse);
      expect(result.errorCode, 'SERVICE_UNAVAILABLE');
    });
  });

  group('Contact commands', () {
    test('contacts.list returns empty when callback not set', () async {
      bus.register(ListContactsCommand());
      final result = await bus.dispatch('contacts.list', {});
      expect(result.success, isTrue);
      expect(result.data, isEmpty);
    });

    test('contacts.add returns SERVICE_UNAVAILABLE', () async {
      bus.register(AddContactCommand());
      final result = await bus.dispatch(
          'contacts.add', {'name': 'Alice', 'address': 'addr123'});
      expect(result.success, isFalse);
      expect(result.errorCode, 'SERVICE_UNAVAILABLE');
    });

    test('contacts.delete returns SERVICE_UNAVAILABLE', () async {
      bus.register(DeleteContactCommand());
      final result =
          await bus.dispatch('contacts.delete', {'name': 'Alice'});
      expect(result.success, isFalse);
      expect(result.errorCode, 'SERVICE_UNAVAILABLE');
    });
  });

  group('Backup commands', () {
    test('backup.export returns SERVICE_UNAVAILABLE', () async {
      bus.register(ExportBackupCommand());
      final result =
          await bus.dispatch('backup.export', {'output': '/tmp/backup'});
      expect(result.success, isFalse);
      expect(result.errorCode, 'SERVICE_UNAVAILABLE');
    });

    test('backup.verify returns SERVICE_UNAVAILABLE', () async {
      bus.register(VerifyBackupCommand());
      final result =
          await bus.dispatch('backup.verify', {'input': '/tmp/backup'});
      expect(result.success, isFalse);
      expect(result.errorCode, 'SERVICE_UNAVAILABLE');
    });
  });

  group('Tor commands', () {
    test('tor.status returns SERVICE_UNAVAILABLE', () async {
      bus.register(TorStatusCommand());
      final result = await bus.dispatch('tor.status', {});
      expect(result.success, isFalse);
      expect(result.errorCode, 'SERVICE_UNAVAILABLE');
    });
  });

  group('Send commit alias', () {
    test('send.commit returns NO_WALLET without wallet', () async {
      bus.register(SendCommitCommand());
      final result =
          await bus.dispatch('send.commit', {'address': 'abc', 'amount': '1.0'});
      expect(result.success, isFalse);
      expect(result.errorCode, 'NO_WALLET');
    });
  });

  group('Coin commands', () {
    test('coins.list returns NO_WALLET without wallet', () async {
      bus.register(ListCoinsCommand());
      final result = await bus.dispatch('coins.list', {});
      expect(result.success, isFalse);
      expect(result.errorCode, 'NO_WALLET');
    });

    test('coins.freeze returns NO_WALLET without wallet', () async {
      bus.register(FreezeCoinCommand());
      final result = await bus.dispatch('coins.freeze', {'id': 'utxo1'});
      expect(result.success, isFalse);
      expect(result.errorCode, 'NO_WALLET');
    });

    test('coins.unfreeze returns NO_WALLET without wallet', () async {
      bus.register(UnfreezeCoinCommand());
      final result = await bus.dispatch('coins.unfreeze', {'id': 'utxo1'});
      expect(result.success, isFalse);
      expect(result.errorCode, 'NO_WALLET');
    });
  });

  group('Token commands', () {
    test('tokens.list returns NO_WALLET without wallet', () async {
      bus.register(ListTokensCommand());
      final result = await bus.dispatch('tokens.list', {});
      expect(result.success, isFalse);
      expect(result.errorCode, 'NO_WALLET');
    });

    test('tokens.add returns NO_WALLET without wallet', () async {
      bus.register(AddTokenCommand());
      final result =
          await bus.dispatch('tokens.add', {'address': '0xabc'});
      expect(result.success, isFalse);
      expect(result.errorCode, 'NO_WALLET');
    });

    test('tokens.remove returns NO_WALLET without wallet', () async {
      bus.register(RemoveTokenCommand());
      final result =
          await bus.dispatch('tokens.remove', {'address': '0xabc'});
      expect(result.success, isFalse);
      expect(result.errorCode, 'NO_WALLET');
    });
  });

  group('Fiat commands', () {
    test('fiat.convert returns SERVICE_UNAVAILABLE', () async {
      bus.register(FiatConvertCommand());
      final result = await bus.dispatch(
          'fiat.convert', {'amount': '100', 'from': 'USD', 'to': 'XMR'});
      expect(result.success, isFalse);
      expect(result.errorCode, 'SERVICE_UNAVAILABLE');
    });
  });

  group('Node edit', () {
    test('nodes.edit returns SERVICE_UNAVAILABLE', () async {
      bus.register(EditNodeCommand());
      final result =
          await bus.dispatch('nodes.edit', {'uri': 'host:port'});
      expect(result.success, isFalse);
      expect(result.errorCode, 'SERVICE_UNAVAILABLE');
    });
  });

  group('Unsupported commands', () {
    test('all UNSUPPORTED stubs return UNSUPPORTED_ON_PLATFORM', () async {
      for (final cmd in createUnsupportedCommands()) {
        bus.register(cmd);
      }
      for (final cmd in createUnsupportedCommands()) {
        final result = await bus.dispatch(cmd.name, {});
        expect(result.success, isFalse,
            reason: '${cmd.name} should fail');
        expect(result.errorCode, 'UNSUPPORTED_ON_PLATFORM',
            reason: '${cmd.name} should be UNSUPPORTED');
      }
    });
  });
}
