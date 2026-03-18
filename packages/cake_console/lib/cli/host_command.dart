import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:cake_headless/commands/command_bus.dart';
import 'package:cake_headless/events/event_bus.dart';
import 'package:cake_console/api/api_server.dart';
import 'package:cake_console/mcp/mcp_server.dart';

/// Long-lived host mode: serves HTTP API, optional MCP on stdio.
class HostCommand extends Command<void> {
  @override
  String get name => 'host';
  @override
  String get description => 'Run wallet as long-lived API/MCP server';

  final CommandBus _bus;
  final WalletEventBus _eventBus;

  HostCommand(this._bus, this._eventBus) {
    argParser.addOption('port', abbr: 'p', defaultsTo: '8080',
        help: 'API server port');
    argParser.addOption('bind', abbr: 'b', defaultsTo: '127.0.0.1',
        help: 'Bind address (use 0.0.0.0 for external access)');
    argParser.addFlag('mcp', help: 'Also serve MCP on stdio', defaultsTo: false);
    argParser.addOption('auth-token', help: 'Bearer auth token for API');
  }

  @override
  Future<void> run() async {
    final port = int.parse(argResults!['port'] as String);
    final bind = argResults!['bind'] as String;
    final serveMcp = argResults!['mcp'] as bool;
    final authToken = argResults!['auth-token'] as String?;

    // Start API server
    final api = ApiServer(_bus, _eventBus, authToken: authToken);
    await api.serve(bind: bind, port: port);

    // Optionally multiplex MCP on stdio
    if (serveMcp) {
      await McpServer(_bus, _eventBus).serve();
    } else {
      // Keep process alive
      await Completer<void>().future;
    }
  }
}
