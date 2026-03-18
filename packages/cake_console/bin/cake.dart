import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:cake_headless/cake_headless.dart';
import 'package:cake_console/cli/cli_runner.dart';
import 'package:cake_console/cli/host_command.dart';
import 'package:cake_console/cli/watch_command.dart';
import 'package:cake_console/cli/manifest_command.dart';
import 'package:cw_core/utils/print_verbose.dart' show printVSink;

Future<void> main(List<String> args) async {
  // Redirect all printV output to stderr so stdout stays clean for MCP/JSON
  printVSink = (line) => stderr.writeln(line);

  // Pre-parse global flags that affect initialization (before CommandRunner)
  final useYes = args.contains('--yes') || args.contains('-y');
  final noColor = args.contains('--no-color');
  final dataDirOverride = _extractOption(args, '--data-dir');

  // Build runtime context with CLI port implementations
  final pathProvider = CliPathProvider(overrideDir: dataDirOverride);
  final appDir = await pathProvider.getAppDir();
  final logger = StderrLogger();

  final storageKey = await _getOrCreateEncryptionKey('$appDir/.storage_key');
  final secureStorage = FileSecureStorage('$appDir/.secure_storage', storageKey);

  // For MCP mode, don't use stdin-based interaction (stdin is JSON-RPC).
  // Only match 'mcp' as a positional arg, not inside flag values like --data-dir=/path/mcp_stuff.
  final isMcpMode = args.where((a) => !a.startsWith('-')).contains('mcp');
  final isNonInteractive = isMcpMode || !stdin.hasTerminal || args.contains('--yes');
  final UserInteractionPort interaction = isNonInteractive
      ? NoOpUserInteraction()
      : StdinUserInteraction(autoConfirm: useYes);

  final ctx = CakeRuntimeContext(
    secureStorage: secureStorage,
    settings: JsonSettingsStore('$appDir/settings.json'),
    pathProvider: pathProvider,
    assetLoader: FilesystemAssetLoader('.'),
    logger: logger,
    interaction: interaction,
  );
  ctx.noColor = noColor;
  ctx.autoConfirm = useYes;
  ctx.nonInteractive = isNonInteractive;
  ctx.jsonMode = args.contains('--json');

  // Initialize Hive, SQLite, and register cw_core adapters + GetIt singletons
  await initializeHeadlessCore(
    dataDir: appDir,
    secureStorage: HeadlessSecureStorageAdapter(secureStorage),
  );

  // Use bootstrap() to register all commands and acquire wallet lock
  final bus = await bootstrap(ctx);

  // Wire WalletRuntime callbacks (cw_core-only: WalletInfo.getAll)
  final runtime = WalletRuntime(ctx);
  await runtime.wireAll();

  // Build CLI runner
  final runner = CommandRunner<void>('cake', 'Cake Wallet CLI/TUI')
    ..addCommand(TuiCommand(bus, ctx.eventBus))
    ..addCommand(McpCommand(bus, ctx.eventBus))
    ..addCommand(HostCommand(bus, ctx.eventBus))
    ..addCommand(WatchCommand(ctx.eventBus))
    ..addCommand(ManifestCommand(bus));

  // Generate CLI subcommands from dotted command names
  _registerCliSubcommands(runner, bus, args);

  // Global flags
  runner.argParser
    ..addOption('data-dir', help: 'Override wallet data directory')
    ..addOption('wallet', abbr: 'w', help: 'Wallet name')
    ..addFlag('json', help: 'Output as JSON', negatable: false)
    ..addFlag('no-color', help: 'Disable colors', negatable: false)
    ..addFlag('yes', abbr: 'y', help: 'Auto-confirm prompts', negatable: false);

  // If no subcommand given, launch interactive TUI or show help
  if (args.isEmpty) {
    if (stdin.hasTerminal && stdout.hasTerminal) {
      args = ['tui'];
    } else {
      stderr.writeln('No command specified. Run with --help for usage.');
      exitCode = 64;
      return;
    }
  }

  // Graceful shutdown — reuse the lock acquired by bootstrap()
  final lock = ctx.walletLock;
  ProcessSignal.sigint.watch().listen((_) {
    lock?.release();
    exit(0);
  });
  if (!Platform.isWindows) {
    ProcessSignal.sigterm.watch().listen((_) {
      lock?.release();
      exit(0);
    });
  }

  try {
    await runner.run(args);
  } on UsageException catch (e) {
    stderr.writeln(e);
    exitCode = 64;
  }
}

bool _isJson(List<String> args) => args.contains('--json');

/// Extract an option value from raw args before CommandRunner parsing.
/// Supports both `--key value` and `--key=value` forms.
String? _extractOption(List<String> args, String key) {
  for (int i = 0; i < args.length; i++) {
    if (args[i] == key && i + 1 < args.length) return args[i + 1];
    if (args[i].startsWith('$key=')) return args[i].substring(key.length + 1);
  }
  return null;
}

/// Generates encryption key or reads existing one from disk.
Future<Uint8List> _getOrCreateEncryptionKey(String keyPath) async {
  final keyFile = File(keyPath);
  if (keyFile.existsSync()) {
    return Uint8List.fromList(keyFile.readAsBytesSync());
  }
  final key = Uint8List.fromList(
      List<int>.generate(32, (_) => Random.secure().nextInt(256)));
  await keyFile.parent.create(recursive: true);
  await keyFile.writeAsBytes(key);
  // Restrict permissions on Unix
  if (!Platform.isWindows) {
    Process.runSync('chmod', ['600', keyPath]);
  }
  return key;
}

/// Registers CLI subcommands from dotted command names.
/// e.g. "wallet.list" becomes `cake wallet list`,
///      "balance.get" becomes `cake balance`.
void _registerCliSubcommands(
    CommandRunner runner, CommandBus bus, List<String> args) {
  // Group commands by top-level prefix
  final groups = <String, List<WalletCommand>>{};
  for (final cmd in bus.commands) {
    final parts = cmd.name.split('.');
    final group = parts[0];
    groups.putIfAbsent(group, () => []).add(cmd);
  }

  for (final entry in groups.entries) {
    final group = entry.key;
    final commands = entry.value;

    if (commands.length == 1 && commands.first.name == group) {
      // Single command, no dot — register directly
      runner.addCommand(HeadlessCliCommand(
        name: group,
        description: commands.first.description,
        headlessCommand: commands.first.name,
        bus: bus,
        isJsonMode: () => _isJson(args),
      ));
    } else if (commands.length == 1) {
      // Single dotted command — register group name pointing to the subcommand
      try {
        runner.addCommand(HeadlessCliCommand(
          name: group,
          description: '${group[0].toUpperCase()}${group.substring(1)} operations',
          headlessCommand: commands.first.name,
          bus: bus,
          isJsonMode: () => _isJson(args),
        ));
      } on ArgumentError catch (_) {
        // Already registered — expected for shared prefix groups
      }
    } else {
      // Multiple commands in the group — create a compound command
      runner.addCommand(CompoundCliCommand(
        groupName: group,
        groupDescription:
            '${group[0].toUpperCase()}${group.substring(1)} operations',
        commands: commands,
        bus: bus,
        isJsonMode: () => _isJson(args),
      ));
    }
  }
}

/// No-op interaction port for MCP mode where stdin is reserved for JSON-RPC.
class NoOpUserInteraction implements UserInteractionPort {
  @override
  Future<bool> confirm(String message) async =>
      throw StateError(
          'CONFIRMATION_REQUIRED: Non-interactive mode cannot confirm: $message');

  @override
  Future<String?> promptText(String message, {bool obscure = false}) async =>
      throw StateError(
          'Interactive input not available in non-interactive mode. Use --yes flag or provide all arguments.');

  @override
  Future<int?> pickOption(String message, List<String> options) async =>
      throw StateError('Interactive input not available in non-interactive mode.');
}
