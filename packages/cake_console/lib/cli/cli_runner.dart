import 'dart:io';

import 'package:args/command_runner.dart';
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

  McpCommand(this._bus);

  @override
  Future<void> run() async {
    final server = McpServer(_bus);
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
            defaultsTo: arg.defaultValue == 'true',
          );
        } else {
          argParser.addOption(
            entry.key,
            help: arg.description,
            mandatory: arg.required,
            defaultsTo: arg.defaultValue,
          );
        }
      }
    }
  }

  @override
  Future<void> run() async {
    final params = <String, dynamic>{};
    for (final option in argResults!.options) {
      if (argResults!.wasParsed(option)) {
        params[option] = argResults![option];
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
