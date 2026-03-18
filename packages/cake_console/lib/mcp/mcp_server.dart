import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cake_headless/commands/command.dart';
import 'package:cake_headless/commands/command_bus.dart';
import 'package:cake_headless/events/event_bus.dart';
import 'package:cake_headless/events/wallet_event.dart';
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

    // Subscribe to wallet events and emit MCP notifications + resource updates
    final eventSub = _eventBus.events.listen((event) {
      // Custom wallet event notification
      _writeLine(jsonEncode({
        'jsonrpc': '2.0',
        'method': 'notifications/cakewallet/wallet_event',
        'params': event.toJson(),
      }));
      // Standards-compliant resource update notifications (10.13)
      final resourceUris = _eventTypeToResourceUris(event.type);
      for (final uri in resourceUris) {
        _writeLine(jsonEncode({
          'jsonrpc': '2.0',
          'method': 'notifications/resources/updated',
          'params': {'uri': uri},
        }));
      }
    });

    // Redirect all print() calls to stderr to keep stdout protocol-clean
    await runZoned(() async {
      final lines =
          stdin.transform(utf8.decoder).transform(const LineSplitter());

      await for (final line in lines) {
        // Skip empty lines (10.4) and Content-Length headers (10.12)
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        if (trimmed.startsWith('Content-Length:')) continue;

        try {
          final request = jsonDecode(trimmed) as Map<String, dynamic>;
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
      final clientVersion = params['protocolVersion'] as String?;
      return _initializeResponse(id, clientProtocolVersion: clientVersion);
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
        'result': {
          'resources': [
            {'uri': 'cake://wallet/current', 'name': 'Current Wallet', 'mimeType': 'application/json'},
            {'uri': 'cake://wallet/current/balance', 'name': 'Wallet Balance', 'mimeType': 'application/json'},
            {'uri': 'cake://wallet/current/sync', 'name': 'Sync Status', 'mimeType': 'application/json'},
          ],
        },
        'id': id,
      };
    }

    if (method == 'resources/read') {
      return _handleResourceRead(id, params);
    }

    if (method == 'resources/subscribe' || method == 'resources/unsubscribe') {
      return {'jsonrpc': '2.0', 'result': {}, 'id': id};
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

  static const _supportedVersions = ['2024-11-05', '2025-03-26', '2025-06-18'];

  Map<String, dynamic> _initializeResponse(dynamic id, {String? clientProtocolVersion}) {
    // Negotiate: use client's version if supported, otherwise latest supported
    final protocolVersion = (clientProtocolVersion != null && _supportedVersions.contains(clientProtocolVersion))
        ? clientProtocolVersion
        : _supportedVersions.last;
    return {
      'jsonrpc': '2.0',
      'result': {
        'protocolVersion': protocolVersion,
        'capabilities': {
          'tools': {'listChanged': false},
          'resources': {'subscribe': true, 'listChanged': false},
          'prompts': {},
          'logging': {},
        },
        'serverInfo': {
          'name': 'cake-wallet-mcp',
          'version': '0.1.0',
        },
      },
      'id': id,
    };
  }

  Future<Map<String, dynamic>> _handleResourceRead(dynamic id, Map<String, dynamic> params) async {
    final uri = params['uri'] as String?;
    if (uri == null) {
      return {
        'jsonrpc': '2.0',
        'error': {'code': -32602, 'message': 'Missing resource URI'},
        'id': id,
      };
    }

    Map<String, dynamic>? content;
    switch (uri) {
      case 'cake://wallet/current':
        final result = await _bus.dispatch('wallet.list', {});
        content = result.toJson(serializeData);
        break;
      case 'cake://wallet/current/balance':
        final result = await _bus.dispatch('balance.get', {});
        content = result.toJson(serializeData);
        break;
      case 'cake://wallet/current/sync':
        final result = await _bus.dispatch('sync.status', {});
        content = result.toJson(serializeData);
        break;
      default:
        return {
          'jsonrpc': '2.0',
          'error': {'code': -32602, 'message': 'Unknown resource: $uri'},
          'id': id,
        };
    }

    return {
      'jsonrpc': '2.0',
      'result': {
        'contents': [
          {
            'uri': uri,
            'mimeType': 'application/json',
            'text': jsonEncode(content),
          },
        ],
      },
      'id': id,
    };
  }

  /// Map event types to affected resource URIs for resource update notifications.
  List<String> _eventTypeToResourceUris(WalletEventType type) {
    switch (type) {
      case WalletEventType.balanceChanged:
        return ['cake://wallet/current/balance'];
      case WalletEventType.syncStatusChanged:
        return ['cake://wallet/current/sync'];
      case WalletEventType.walletOpened:
      case WalletEventType.walletClosed:
        return ['cake://wallet/current', 'cake://wallet/current/balance', 'cake://wallet/current/sync'];
      default:
        return [];
    }
  }

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
