import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cake_headless/commands/command_bus.dart';

class McpServer {
  final CommandBus _bus;

  McpServer(this._bus);

  Future<void> serve() async {
    stderr.writeln('[MCP] Cake Wallet MCP server starting...');

    final lines = stdin.transform(utf8.decoder).transform(const LineSplitter());

    await for (final line in lines) {
      try {
        final request = jsonDecode(line) as Map<String, dynamic>;
        final response = await _handleRequest(request);
        stdout.writeln(jsonEncode(response));
      } catch (e) {
        stdout.writeln(jsonEncode({
          'jsonrpc': '2.0',
          'error': {'code': -32700, 'message': 'Parse error: $e'},
          'id': null,
        }));
      }
    }
  }

  Future<Map<String, dynamic>> _handleRequest(
      Map<String, dynamic> request) async {
    final id = request['id'];
    final method = request['method'] as String?;
    final params = (request['params'] as Map<String, dynamic>?) ?? {};

    if (method == 'initialize') {
      return _initializeResponse(id);
    }

    if (method == 'tools/list') {
      return _listToolsResponse(id);
    }

    if (method == 'tools/call') {
      final toolName = params['name'] as String;
      final toolArgs =
          (params['arguments'] as Map<String, dynamic>?) ?? {};
      final result = await _bus.dispatch(toolName, toolArgs);
      return {
        'jsonrpc': '2.0',
        'result': {
          'content': [
            {
              'type': 'text',
              'text': jsonEncode(result.toJson((d) {
                if (d is Map) return d as Map<String, dynamic>;
                final toJson = (d as dynamic).toJson;
                if (toJson != null) return toJson() as Map<String, dynamic>;
                return {'value': d.toString()};
              })),
            }
          ],
        },
        'id': id,
      };
    }

    return {
      'jsonrpc': '2.0',
      'error': {'code': -32601, 'message': 'Method not found: $method'},
      'id': id,
    };
  }

  Map<String, dynamic> _initializeResponse(dynamic id) => {
        'jsonrpc': '2.0',
        'result': {
          'protocolVersion': '2024-11-05',
          'capabilities': {
            'tools': {'listChanged': false},
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
                                : v.type == bool
                                    ? 'boolean'
                                    : 'string',
                            'description': v.description,
                          })),
                      'required': cmd.args.entries
                          .where((e) => e.value.required)
                          .map((e) => e.key)
                          .toList(),
                    },
                  })
              .toList(),
        },
        'id': id,
      };
}
