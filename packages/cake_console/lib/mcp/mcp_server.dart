import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cake_headless/commands/command.dart';
import 'package:cake_headless/commands/command_bus.dart';
import 'package:cake_headless/events/event_bus.dart';
import 'package:cake_console/cli/json_output.dart' show serializeData;

class McpServer {
  final CommandBus _bus;
  final WalletEventBus _eventBus;

  /// Serialized output sink to prevent interleaved writes from concurrent async paths
  final _outputCompleter = StreamController<String>();
  StreamSubscription? _outputSub;

  McpServer(this._bus, this._eventBus);

  Future<void> serve() async {
    stderr.writeln('[MCP] Cake Wallet MCP server starting...');

    // Single outbound write queue for all stdout JSON-RPC output
    _outputSub = _outputCompleter.stream.listen((line) {
      stdout.writeln(line);
    });

    // Subscribe to wallet events and emit MCP notifications
    final eventSub = _eventBus.events.listen((event) {
      final notification = {
        'jsonrpc': '2.0',
        'method': 'notifications/cakewallet/wallet_event',
        'params': {
          'type': event.type.name,
          'data': event.data,
          'timestamp': event.timestamp.toIso8601String(),
        },
      };
      _writeLine(jsonEncode(notification));
    });

    // Redirect all print() calls to stderr to keep stdout protocol-clean
    await runZoned(() async {
      final lines =
          stdin.transform(utf8.decoder).transform(const LineSplitter());

      await for (final line in lines) {
        // Skip empty lines (10.4)
        if (line.trim().isEmpty) continue;

        try {
          final request = jsonDecode(line) as Map<String, dynamic>;
          final response = await _handleRequest(request);
          // Notifications (no id) must not receive a response
          if (response != null) {
            _writeLine(jsonEncode(response));
          }
        } catch (e) {
          _writeLine(jsonEncode({
            'jsonrpc': '2.0',
            'error': {'code': -32700, 'message': 'Parse error: $e'},
            'id': null,
          }));
        }
      }
    }, zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) => stderr.writeln(line),
    ));

    await eventSub.cancel();
    await _outputSub?.cancel();
    await _outputCompleter.close();
  }

  void _writeLine(String line) {
    _outputCompleter.add(line);
  }

  Future<Map<String, dynamic>?> _handleRequest(
      Map<String, dynamic> request) async {
    final id = request['id'];
    final method = request['method'] as String?;
    final params = (request['params'] as Map<String, dynamic>?) ?? {};

    // All notifications (no id field) must not receive a response
    if (!request.containsKey('id')) {
      return null;
    }

    // Handle notification methods that arrive with an id (shouldn't per spec, but be safe)
    if (method != null && method.startsWith('notifications/')) {
      return null;
    }

    if (method == 'initialize') {
      return _initializeResponse(id);
    }

    if (method == 'ping') {
      return {'jsonrpc': '2.0', 'result': {}, 'id': id};
    }

    if (method == 'tools/list') {
      return _listToolsResponse(id);
    }

    if (method == 'resources/list') {
      return {
        'jsonrpc': '2.0',
        'result': {'resources': []},
        'id': id,
      };
    }

    // Stub handlers for compliant MCP clients (10.5)
    if (method == 'resources/templates/list') {
      return {
        'jsonrpc': '2.0',
        'result': {'resourceTemplates': []},
        'id': id,
      };
    }

    if (method == 'completion/complete') {
      return {
        'jsonrpc': '2.0',
        'result': {
          'completion': {'values': [], 'hasMore': false, 'total': 0}
        },
        'id': id,
      };
    }

    if (method == 'prompts/list') {
      return {
        'jsonrpc': '2.0',
        'result': {'prompts': []},
        'id': id,
      };
    }

    // MCP logging support (10.11)
    if (method == 'logging/setLevel') {
      return {
        'jsonrpc': '2.0',
        'result': {},
        'id': id,
      };
    }

    if (method == 'tools/call') {
      final toolName = params['name'] as String?;
      final toolArgs =
          (params['arguments'] as Map<String, dynamic>?) ?? {};

      if (toolName == null) {
        return {
          'jsonrpc': '2.0',
          'error': {'code': -32602, 'message': 'Missing tool name'},
          'id': id,
        };
      }

      // Type coercion for MCP (10.6): MCP sends JSON numbers as int/double
      // Coerce using command arg definitions
      final cmd = _bus.getCommand(toolName);
      if (cmd != null) {
        _coerceToolArgs(toolArgs, cmd);
      }

      try {
        final result = await _bus.dispatch(toolName, toolArgs);
        final serialized = result.toJson(serializeData);
        return {
          'jsonrpc': '2.0',
          'result': {
            'content': [
              {
                'type': 'text',
                'text': jsonEncode(serialized),
              }
            ],
            if (!result.success) 'isError': true,
          },
          'id': id,
        };
      } catch (e) {
        return {
          'jsonrpc': '2.0',
          'result': {
            'content': [
              {
                'type': 'text',
                'text': jsonEncode({'success': false, 'error': e.toString()}),
              }
            ],
            'isError': true,
          },
          'id': id,
        };
      }
    }

    return {
      'jsonrpc': '2.0',
      'error': {'code': -32601, 'message': 'Method not found: $method'},
      'id': id,
    };
  }

  /// Coerce MCP tool arguments to match command arg type definitions.
  void _coerceToolArgs(Map<String, dynamic> toolArgs, WalletCommand cmd) {
    for (final entry in cmd.args.entries) {
      if (!toolArgs.containsKey(entry.key)) continue;
      final val = toolArgs[entry.key];
      if (val == null) continue;

      // MCP sends JSON numbers — convert to expected types
      if (entry.value.type == String && val is! String) {
        toolArgs[entry.key] = val.toString();
      } else if (entry.value.type == int && val is! int) {
        if (val is double) {
          toolArgs[entry.key] = val.toInt();
        } else {
          toolArgs[entry.key] = int.tryParse(val.toString()) ?? val;
        }
      } else if (entry.value.type == double && val is! double) {
        if (val is int) {
          toolArgs[entry.key] = val.toDouble();
        } else {
          toolArgs[entry.key] = double.tryParse(val.toString()) ?? val;
        }
      }
    }
  }

  Map<String, dynamic> _initializeResponse(dynamic id) => {
        'jsonrpc': '2.0',
        'result': {
          'protocolVersion': '2024-11-05',
          'capabilities': {
            'tools': {'listChanged': false},
            'resources': {},
            'prompts': {},
          },
          'serverInfo': {
            'name': 'cake-wallet-mcp',
            'version': '0.1.0',
          },
        },
        'id': id,
      };

  Map<String, dynamic> _listToolsResponse(dynamic id) => {
        'jsonrpc': '2.0',
        'result': {
          'tools': _bus.commands
              .map((cmd) => {
                    'name': cmd.name,
                    'description': cmd.description,
                    'inputSchema': {
                      'type': 'object',
                      'properties': cmd.args.map((k, v) => MapEntry(k, {
                            'type': v.type == int
                                ? 'integer'
                                : v.type == double
                                    ? 'number'
                                    : v.type == bool
                                        ? 'boolean'
                                        : 'string',
                            'description': v.description,
                            if (v.choices != null) 'enum': v.choices,
                          })),
                      'required': cmd.args.entries
                          .where((e) => e.value.required)
                          .map((e) => e.key)
                          .toList(),
                      if (cmd.args.isEmpty) 'additionalProperties': false,
                    },
                  })
              .toList(),
        },
        'id': id,
      };
}
