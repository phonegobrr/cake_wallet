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
  bus.register(ListWalletsCommand());
  bus.register(GetBalanceCommand());
  bus.register(SendCommand());
  bus.register(GetReceiveAddressCommand());
  bus.register(ListTransactionsCommand());
  bus.register(ListNodesCommand());
  bus.register(ListSettingsCommand());
  bus.register(GetSyncStatusCommand());

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
