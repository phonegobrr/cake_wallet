import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cake_headless/commands/command.dart';
import 'package:cake_headless/commands/command_bus.dart';
import 'package:cake_headless/events/event_bus.dart';
import 'package:cake_console/cli/json_output.dart';
import 'package:cake_console/tui/tui_app.dart';
import 'package:cake_console/mcp/mcp_server.dart';

class TuiCommand extends Command<void> {
  @override
  String get name => 'tui';
  @override
  String get description => 'Launch interactive TUI';

  final CommandBus _bus;
  final WalletEventBus _eventBus;

  TuiCommand(this._bus, this._eventBus);

  @override
  Future<void> run() async {
    final app = TuiApp(commandBus: _bus, eventBus: _eventBus);
    await app.run();
  }
}

class McpCommand extends Command<void> {
  @override
  String get name => 'mcp';
  @override
  String get description => 'Start MCP server (JSON-RPC over stdio)';

  final CommandBus _bus;
  final WalletEventBus _eventBus;

  McpCommand(this._bus, this._eventBus);

  @override
  Future<void> run() async {
    final server = McpServer(_bus, _eventBus);
    await server.serve();
  }
}

/// Generic CLI command that dispatches to a headless command.
/// Introspects the registered WalletCommand's args to create CLI options.
class HeadlessCliCommand extends Command<void> {
  @override
  final String name;
  @override
  final String description;

  final String headlessCommand;
  final CommandBus _bus;
  final bool Function() _isJsonMode;
  final bool Function() _isWatchMode;
  final WalletEventBus? _eventBus;

  HeadlessCliCommand({
    required this.name,
    required this.description,
    required this.headlessCommand,
    required CommandBus bus,
    required bool Function() isJsonMode,
    bool Function()? isWatchMode,
    WalletEventBus? eventBus,
  })  : _bus = bus,
        _isJsonMode = isJsonMode,
        _isWatchMode = isWatchMode ?? (() => false),
        _eventBus = eventBus {
    // Register CLI options from the headless command's arg definitions
    final cmd = bus.getCommand(headlessCommand);
    if (cmd != null) {
      for (final entry in cmd.args.entries) {
        final arg = entry.value;
        if (arg.type == bool) {
          argParser.addFlag(
            entry.key,
            help: arg.description,
            defaultsTo: arg.defaultValue == true ||
                arg.defaultValue?.toString() == 'true',
          );
        } else {
          argParser.addOption(
            entry.key,
            help: arg.description,
            mandatory: arg.required,
            defaultsTo: arg.defaultValue?.toString(),
            allowed: arg.choices,
          );
        }
      }
    }
  }

  @override
  Future<void> run() async {
    final cmd = _bus.getCommand(headlessCommand);
    final params = <String, dynamic>{};
    // Only forward options that the command declares, not global flags
    if (cmd != null) {
      for (final arg in cmd.args.keys) {
        if (argResults!.wasParsed(arg)) {
          var value = argResults![arg];
          // Coerce types based on command arg definitions
          final argDef = cmd.args[arg]!;
          if (argDef.type == int && value is String) {
            value = int.tryParse(value) ?? value;
          } else if (argDef.type == double && value is String) {
            value = double.tryParse(value) ?? value;
          }
          params[arg] = value;
        }
      }
    }

    final result = await _bus.dispatch(headlessCommand, params);

    if (_isJsonMode()) {
      outputJson(result);
    } else {
      outputText(result);
    }

    if (!result.success) {
      exitCode = 1;
      return;
    }

    // --watch mode: re-execute on each wallet event (read-only commands only)
    final watchCmd = _bus.getCommand(headlessCommand);
    if (_isWatchMode() && _eventBus != null &&
        watchCmd != null && watchCmd.isSafeForNonInteractive) {
      await for (final _ in _eventBus!.events) {
        final updated = await _bus.dispatch(headlessCommand, params);
        if (_isJsonMode()) {
          outputJson(updated);
        } else {
          // Clear line and re-output for terminal
          if (stdout.hasTerminal) stderr.write('\x1B[2K\r');
          outputText(updated);
        }
      }
    }
  }
}

/// Compound CLI command that groups multiple dotted commands under a prefix.
/// e.g. "wallet.list", "wallet.create" → `cake wallet list`, `cake wallet create`
///
/// Handles multi-level nesting: "wallet.restore.seed" → `cake wallet restore seed`
/// If a standalone command matches the group name (e.g. "send"), it becomes
/// the default run() behavior of the compound command.
///
/// [prefix] is the full dotted prefix consumed so far (e.g. "wallet" or "wallet.restore").
/// Used to determine the next segment to group on.
class CompoundCliCommand extends Command<void> {
  @override
  final String name;
  @override
  final String description;

  final CommandBus _bus;
  final bool Function() _isJsonMode;
  final String _prefix;
  /// If the group has a standalone command (e.g. "send" alongside "send.preview"),
  /// store its full dotted name here so run() dispatches it by default.
  String? _defaultCommand;

  CompoundCliCommand({
    required String groupName,
    required String groupDescription,
    required List<WalletCommand> commands,
    required CommandBus bus,
    required bool Function() isJsonMode,
    String? prefix,
  })  : name = groupName,
        description = groupDescription,
        _bus = bus,
        _isJsonMode = isJsonMode,
        _prefix = prefix ?? groupName {
    // The prefix includes all segments consumed so far.
    // e.g. for top-level "wallet" group, prefix = "wallet"
    // e.g. for nested "restore" under "wallet", prefix = "wallet.restore"
    final prefixDot = '$_prefix.';

    // Find standalone command matching this exact prefix
    for (final cmd in commands) {
      if (cmd.name == _prefix) {
        _defaultCommand = cmd.name;
        // Register default command's args on this command's argParser
        for (final entry in cmd.args.entries) {
          final arg = entry.value;
          if (arg.type == bool) {
            argParser.addFlag(entry.key, help: arg.description,
                defaultsTo: arg.defaultValue == true ||
                    arg.defaultValue?.toString() == 'true');
          } else {
            argParser.addOption(entry.key, help: arg.description,
                mandatory: arg.required,
                defaultsTo: arg.defaultValue?.toString(),
                allowed: arg.choices);
          }
        }
        break;
      }
    }

    // Group remaining dotted commands by the next segment after the prefix
    final subGroups = <String, List<WalletCommand>>{};
    for (final cmd in commands) {
      if (cmd.name == _prefix) continue; // standalone already handled
      if (!cmd.name.startsWith(prefixDot)) continue;

      final remaining = cmd.name.substring(prefixDot.length);
      final nextSegment = remaining.split('.').first;
      subGroups.putIfAbsent(nextSegment, () => []).add(cmd);
    }

    for (final entry in subGroups.entries) {
      final subName = entry.key;
      final subCommands = entry.value;
      final subPrefix = '$_prefix.$subName';

      // Check if all subcommands resolve to exactly this sub-prefix level
      final allDirect = subCommands.every((c) => c.name == subPrefix);

      if (subCommands.length == 1 && allDirect) {
        // Single subcommand at this level — register directly
        final cmd = subCommands.first;
        try {
          addSubcommand(HeadlessCliCommand(
            name: subName,
            description: cmd.description,
            headlessCommand: cmd.name,
            bus: bus,
            isJsonMode: isJsonMode,
          ));
        } on ArgumentError catch (_) {}
      } else {
        // Multiple commands or deeper nesting — recurse
        try {
          addSubcommand(CompoundCliCommand(
            groupName: subName,
            groupDescription:
                '${subName[0].toUpperCase()}${subName.substring(1)} operations',
            commands: subCommands,
            bus: bus,
            isJsonMode: isJsonMode,
            prefix: subPrefix,
          ));
        } on ArgumentError catch (_) {}
      }
    }
  }

  @override
  Future<void> run() async {
    if (_defaultCommand != null) {
      // Dispatch the standalone command (e.g. "send" when user runs `cake send`)
      final cmd = _bus.getCommand(_defaultCommand!);
      final params = <String, dynamic>{};
      if (cmd != null) {
        for (final arg in cmd.args.keys) {
          if (argResults!.wasParsed(arg)) {
            params[arg] = argResults![arg];
          }
        }
      }
      final result = await _bus.dispatch(_defaultCommand!, params);
      if (_isJsonMode()) {
        outputJson(result);
      } else {
        outputText(result);
      }
      if (!result.success) {
        exitCode = 1;
      }
      return;
    }
    // No default command and no subcommand specified — show usage
    stderr.writeln(usage);
    exitCode = 64;
  }
}
