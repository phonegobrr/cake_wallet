import 'package:test/test.dart';
import 'package:cake_headless/commands/command_bus.dart';
import 'package:cake_headless/commands/command.dart';
import 'package:cake_headless/commands/command_result.dart';
import 'package:cake_headless/runtime_context.dart';
import 'package:cake_headless/ports_impl/json_settings_store.dart';
import 'package:cake_headless/ports_impl/cli_path_provider.dart';
import 'package:cake_headless/ports_impl/filesystem_asset_loader.dart';
import 'package:cake_headless/ports_impl/stderr_logger.dart';
import 'package:cake_headless/ports_impl/stdin_secret_input.dart';
import 'package:cake_headless/ports_impl/file_secure_storage.dart';
import 'package:cake_console/tui/screen.dart';
import 'package:cake_console/tui/terminal_driver.dart';
import 'package:cake_console/tui/screens/dashboard_screen.dart';
import 'package:cake_console/tui/screens/wallet_list_screen.dart';
import 'package:cake_console/tui/screens/send_screen.dart';
import 'package:cake_console/tui/screens/receive_screen.dart';
import 'package:cake_console/tui/screens/history_screen.dart';
import 'package:cake_console/tui/screens/exchange_screen.dart';
import 'package:cake_console/tui/screens/settings_screen.dart';
import 'package:cake_console/tui/screens/contacts_screen.dart';
import 'dart:typed_data';
import 'dart:io';

CakeRuntimeContext _createTestCtx() {
  final tmpDir = Directory.systemTemp.createTempSync('cake_tui_test_');
  return CakeRuntimeContext(
    secureStorage:
        FileSecureStorage('${tmpDir.path}/.secure', Uint8List(32)),
    settings: JsonSettingsStore('${tmpDir.path}/settings.json'),
    pathProvider: CliPathProvider(),
    assetLoader: FilesystemAssetLoader('.'),
    logger: StderrLogger(),
    interaction: StdinUserInteraction(autoConfirm: true),
  );
}

CommandBus _createBus(CakeRuntimeContext ctx) {
  final bus = CommandBus(ctx);
  // Register a minimal stub command for each used command name
  bus.register(_StubCommand('balance.get'));
  bus.register(_StubCommand('sync.status'));
  bus.register(_StubCommand('history.list'));
  bus.register(_StubCommand('wallet.list'));
  bus.register(_StubCommand('receive.address'));
  bus.register(_StubCommand('settings.list'));
  bus.register(_StubCommand('contacts.list'));
  return bus;
}

class _StubCommand extends WalletCommand<Map<String, String>> {
  @override
  final String name;
  _StubCommand(this.name);

  @override
  String get description => 'Test stub';
  @override
  Map<String, CommandArg> get args => {};

  @override
  Future<CommandResult<Map<String, String>>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    return CommandResult.ok({}, message: 'stub');
  }
}

void main() {
  late CommandBus bus;
  late CakeRuntimeContext ctx;

  setUp(() {
    ctx = _createTestCtx();
    bus = _createBus(ctx);
  });

  group('TuiScreen lifecycle', () {
    test('all screens extend TuiScreen with correct defaults', () {
      final screens = <TuiScreen>[
        DashboardScreen(bus),
        WalletListScreen(bus),
        SendScreen(bus),
        ReceiveScreen(bus),
        HistoryScreen(bus),
        ExchangeScreen(bus),
        SettingsScreen(bus),
        ContactsScreen(bus),
      ];
      for (final screen in screens) {
        expect(screen.title, isNotEmpty, reason: '${screen.runtimeType}.title');
      }
    });

    test('capturesInput is true for send and exchange screens', () {
      expect(SendScreen(bus).capturesInput, isTrue);
      expect(ExchangeScreen(bus).capturesInput, isTrue);
    });

    test('capturesInput is false for non-input screens', () {
      expect(DashboardScreen(bus).capturesInput, isFalse);
      expect(WalletListScreen(bus).capturesInput, isFalse);
      expect(HistoryScreen(bus).capturesInput, isFalse);
      expect(ReceiveScreen(bus).capturesInput, isFalse);
      expect(SettingsScreen(bus).capturesInput, isFalse);
      expect(ContactsScreen(bus).capturesInput, isFalse);
    });
  });

  group('TuiScreen rendering', () {
    test('all screens render without errors when no wallet is loaded', () async {
      final screens = <TuiScreen>[
        DashboardScreen(bus),
        WalletListScreen(bus),
        SendScreen(bus),
        ReceiveScreen(bus),
        HistoryScreen(bus),
        ExchangeScreen(bus),
        SettingsScreen(bus),
        ContactsScreen(bus),
      ];
      for (final screen in screens) {
        await screen.init();
        // Render with reasonable terminal dimensions
        final output = screen.render(80, 24, bus);
        expect(output, isNotNull, reason: '${screen.runtimeType}.render()');
        expect(output, isNotEmpty, reason: '${screen.runtimeType}.render()');
      }
    });
  });

  group('TuiScreen input handling', () {
    test('empty list screens handle input without crashing', () {
      final screens = <TuiScreen>[
        DashboardScreen(bus),
        WalletListScreen(bus),
        HistoryScreen(bus),
        SettingsScreen(bus),
        ContactsScreen(bus),
      ];
      for (final screen in screens) {
        // Should not throw on up/down with empty lists
        screen.handleInput(TerminalEvent(TerminalKey.up));
        screen.handleInput(TerminalEvent(TerminalKey.down));
        screen.handleInput(TerminalEvent(TerminalKey.enter));
      }
    });

    test('send screen handles text input', () {
      final screen = SendScreen(bus);
      screen.handleInput(TerminalEvent(TerminalKey.char, 'a'));
      screen.handleInput(TerminalEvent(TerminalKey.char, 'b'));
      final output = screen.render(80, 24, bus);
      expect(output, contains('ab'));
    });

    test('send screen handles backspace', () {
      final screen = SendScreen(bus);
      screen.handleInput(TerminalEvent(TerminalKey.char, 'a'));
      screen.handleInput(TerminalEvent(TerminalKey.char, 'b'));
      screen.handleInput(TerminalEvent(TerminalKey.backspace));
      final output = screen.render(80, 24, bus);
      expect(output, contains('a'));
    });

    test('send screen up/down switches focus fields', () {
      final screen = SendScreen(bus);
      // Start at address field (0), type 'x'
      screen.handleInput(TerminalEvent(TerminalKey.char, 'x'));
      // Down to amount field
      screen.handleInput(TerminalEvent(TerminalKey.down));
      screen.handleInput(TerminalEvent(TerminalKey.char, '5'));
      final output = screen.render(80, 24, bus);
      expect(output, contains('x'));
      expect(output, contains('5'));
    });

    test('send screen escape clears fields', () {
      final screen = SendScreen(bus);
      screen.handleInput(TerminalEvent(TerminalKey.char, 'x'));
      screen.handleInput(TerminalEvent(TerminalKey.escape));
      final output = screen.render(80, 24, bus);
      expect(output, contains('(enter address)'));
    });
  });

  group('TerminalDriver', () {
    test('TerminalKey enum has ctrlC and resize', () {
      expect(TerminalKey.ctrlC, isNotNull);
      expect(TerminalKey.resize, isNotNull);
    });

    test('TerminalEvent stores char data', () {
      final evt = TerminalEvent(TerminalKey.char, 'q');
      expect(evt.key, equals(TerminalKey.char));
      expect(evt.char, equals('q'));
    });
  });

  group('Cross-platform', () {
    test('TerminalDriver dimensions have sane defaults', () {
      final driver = TerminalDriver();
      expect(driver.width, greaterThan(0));
      expect(driver.height, greaterThan(0));
    });
  }, testOn: 'posix');
}
