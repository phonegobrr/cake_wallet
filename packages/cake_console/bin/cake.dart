import 'dart:io';
import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:cake_headless/cake_headless.dart';
import 'package:cake_console/cli/cli_runner.dart';

Future<void> main(List<String> args) async {
  // Build runtime context with CLI port implementations
  final pathProvider = CliPathProvider();
  final appDir = await pathProvider.getAppDir();
  final logger = StderrLogger();

  final ctx = CakeRuntimeContext(
    secureStorage: FileSecureStorage(
        '$appDir/.secure_storage', Uint8List(32)),
    settings: JsonSettingsStore('$appDir/settings.json'),
    pathProvider: pathProvider,
    assetLoader: FilesystemAssetLoader('.'),
    logger: logger,
    interaction: StdinUserInteraction(),
  );

  // Build command bus and register all commands
  final bus = CommandBus(ctx);

  // Wallet
  bus.register(ListWalletsCommand());
  bus.register(GetBalanceCommand());

  // Send / Receive
  bus.register(SendCommand());
  bus.register(GetReceiveAddressCommand());

  // History
  bus.register(ListTransactionsCommand());

  // Nodes
  bus.register(ListNodesCommand());

  // Settings & Sync
  bus.register(ListSettingsCommand());
  bus.register(SetSettingCommand());
  bus.register(GetSyncStatusCommand());

  // Exchange / Swap
  bus.register(GetSwapQuoteCommand());
  bus.register(GetSwapStatusCommand());

  // Contacts
  bus.register(ListContactsCommand());
  bus.register(AddContactCommand());

  // Backup
  bus.register(ExportBackupCommand());
  bus.register(ImportBackupCommand());

  // Build CLI runner
  final runner = CommandRunner<void>('cake', 'Cake Wallet CLI/TUI')
    ..addCommand(TuiCommand(bus, ctx.eventBus))
    ..addCommand(McpCommand(bus))
    ..addCommand(HeadlessCliCommand(
      name: 'wallet',
      description: 'Wallet operations (list)',
      headlessCommand: 'wallet.list',
      bus: bus,
      isJsonMode: () => _isJson(args),
    ))
    ..addCommand(HeadlessCliCommand(
      name: 'balance',
      description: 'Show wallet balance',
      headlessCommand: 'balance.get',
      bus: bus,
      isJsonMode: () => _isJson(args),
    ))
    ..addCommand(HeadlessCliCommand(
      name: 'send',
      description: 'Send a transaction',
      headlessCommand: 'send',
      bus: bus,
      isJsonMode: () => _isJson(args),
    ))
    ..addCommand(HeadlessCliCommand(
      name: 'receive',
      description: 'Show receive address',
      headlessCommand: 'receive.address',
      bus: bus,
      isJsonMode: () => _isJson(args),
    ))
    ..addCommand(HeadlessCliCommand(
      name: 'history',
      description: 'Show transaction history',
      headlessCommand: 'history.list',
      bus: bus,
      isJsonMode: () => _isJson(args),
    ))
    ..addCommand(HeadlessCliCommand(
      name: 'nodes',
      description: 'Node management',
      headlessCommand: 'nodes.list',
      bus: bus,
      isJsonMode: () => _isJson(args),
    ))
    ..addCommand(HeadlessCliCommand(
      name: 'settings',
      description: 'Settings management',
      headlessCommand: 'settings.list',
      bus: bus,
      isJsonMode: () => _isJson(args),
    ))
    ..addCommand(HeadlessCliCommand(
      name: 'sync-status',
      description: 'Show sync status',
      headlessCommand: 'sync.status',
      bus: bus,
      isJsonMode: () => _isJson(args),
    ))
    ..addCommand(HeadlessCliCommand(
      name: 'swap',
      description: 'Get exchange quote',
      headlessCommand: 'swap.quote',
      bus: bus,
      isJsonMode: () => _isJson(args),
    ))
    ..addCommand(HeadlessCliCommand(
      name: 'contacts',
      description: 'Contact management',
      headlessCommand: 'contacts.list',
      bus: bus,
      isJsonMode: () => _isJson(args),
    ))
    ..addCommand(HeadlessCliCommand(
      name: 'backup',
      description: 'Backup management',
      headlessCommand: 'backup.export',
      bus: bus,
      isJsonMode: () => _isJson(args),
    ));

  // Global flags
  runner.argParser
    ..addOption('data-dir', help: 'Override wallet data directory')
    ..addOption('wallet', abbr: 'w', help: 'Wallet name')
    ..addFlag('json', help: 'Output as JSON', negatable: false)
    ..addFlag('no-color', help: 'Disable colors', negatable: false)
    ..addFlag('yes', abbr: 'y', help: 'Auto-confirm prompts', negatable: false);

  // If no subcommand given, launch interactive TUI
  if (args.isEmpty) {
    args = ['tui'];
  }

  try {
    await runner.run(args);
  } on UsageException catch (e) {
    stderr.writeln(e);
    exitCode = 64;
  }
}

bool _isJson(List<String> args) => args.contains('--json');
