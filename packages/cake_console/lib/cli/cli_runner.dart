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

  HeadlessCliCommand({
    required this.name,
    required this.description,
    required this.headlessCommand,
    required CommandBus bus,
    required bool Function() isJsonMode,
  })  : _bus = bus,
        _isJsonMode = isJsonMode {
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
    }
  }
}

/// Compound CLI command that groups multiple dotted commands under a prefix.
/// e.g. "wallet.list", "wallet.create" → `cake wallet list`, `cake wallet create`
///
/// Handles multi-level nesting: "wallet.restore.seed" → `cake wallet restore seed`
/// If a standalone command matches the group name (e.g. "send"), it becomes
/// the default run() behavior of the compound command.
class CompoundCliCommand extends Command<void> {
  @override
  final String name;
  @override
  final String description;

  final CommandBus _bus;
  final bool Function() _isJsonMode;
  /// If the group has a standalone command (e.g. "send" alongside "send.preview"),
  /// store it here so run() dispatches it by default.
  final String? _defaultCommand;

  CompoundCliCommand({
    required String groupName,
    required String groupDescription,
    required List<WalletCommand> commands,
    required CommandBus bus,
    required bool Function() isJsonMode,
  })  : name = groupName,
        description = groupDescription,
        _bus = bus,
        _isJsonMode = isJsonMode,
        _defaultCommand = commands.any((c) => c.name == groupName)
            ? groupName
            : null {
    // Separate standalone (group-name-only) from dotted commands
    final dotted = commands.where((c) => c.name != groupName).toList();

    // Build a recursive tree for multi-level nesting
    final subGroups = <String, List<WalletCommand>>{};
    for (final cmd in dotted) {
      final parts = cmd.name.split('.');
      if (parts.length < 2) continue;
      final subName = parts[1];
      subGroups.putIfAbsent(subName, () => []).add(cmd);
    }

    for (final entry in subGroups.entries) {
      final subName = entry.key;
      final subCommands = entry.value;

      if (subCommands.length == 1) {
        // Single subcommand — register directly
        final cmd = subCommands.first;
        try {
          addSubcommand(HeadlessCliCommand(
            name: subName,
            description: cmd.description,
            headlessCommand: cmd.name,
            bus: bus,
            isJsonMode: isJsonMode,
          ));
        } on ArgumentError catch (_) {
          // Already registered
        }
      } else {
        // Multiple sub-subcommands — create nested compound
        // e.g. wallet.restore.seed, wallet.restore.keys → cake wallet restore seed|keys
        try {
          addSubcommand(CompoundCliCommand(
            groupName: subName,
            groupDescription:
                '${subName[0].toUpperCase()}${subName.substring(1)} operations',
            commands: subCommands,
            bus: bus,
            isJsonMode: isJsonMode,
          ));
        } on ArgumentError catch (_) {
          // Already registered
        }
      }
    }
  }

  @override
  Future<void> run() async {
    if (_defaultCommand != null) {
      // Dispatch the standalone command (e.g. "send" when user runs `cake send`)
      final cmd = _bus.getCommand(_defaultCommand);
      final params = <String, dynamic>{};
      if (cmd != null) {
        for (final arg in cmd.args.keys) {
          if (argResults!.wasParsed(arg)) {
            params[arg] = argResults![arg];
          }
        }
      }
      final result = await _bus.dispatch(_defaultCommand, params);
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
