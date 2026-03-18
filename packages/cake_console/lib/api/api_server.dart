import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:cake_headless/commands/command_bus.dart';
import 'package:cake_headless/events/event_bus.dart';
import 'package:cake_console/cli/json_output.dart' show serializeData;

class ApiServer {
  final CommandBus bus;
  final WalletEventBus eventBus;
  final String? authToken;

  ApiServer(this.bus, this.eventBus, {this.authToken});

  Future<HttpServer> serve({
    String bind = '127.0.0.1',
    int port = 8080,
  }) async {
    var handler = const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(_authMiddleware())
        .addHandler(_router);

    final server = await shelf_io.serve(handler, bind, port);
    stderr.writeln('[API] Server running on http://$bind:$port');
    return server;
  }

  Future<Response> _router(Request request) async {
    final path = request.url.path;
    final method = request.method;

    // POST /api/v1/command/<name>
    if (method == 'POST' && path.startsWith('api/v1/command/')) {
      final name = path.substring('api/v1/command/'.length);
      if (name.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Missing command name'}),
            headers: _jsonHeaders);
      }
      return _handleCommand(request, name);
    }

    // GET /api/v1/capabilities
    if (method == 'GET' && path == 'api/v1/capabilities') {
      return _handleCapabilities(request);
    }

    // GET /api/v1/events
    if (method == 'GET' && path == 'api/v1/events') {
      return _handleSSE(request);
    }

    // GET /api/v1/health
    if (method == 'GET' && path == 'api/v1/health') {
      return Response.ok(
        jsonEncode(
            {'status': 'ok', 'timestamp': DateTime.now().toIso8601String()}),
        headers: _jsonHeaders,
      );
    }

    // GET /ws — WebSocket for bidirectional JSON-RPC + event push
    if (method == 'GET' && path == 'ws') {
      return _wsHandler(request);
    }

    return Response.notFound(jsonEncode({'error': 'Not found'}),
        headers: _jsonHeaders);
  }

  late final Handler _wsHandler = webSocketHandler((WebSocketChannel webSocket, String? _) {
    final sub = eventBus.events.listen((event) {
      webSocket.sink.add(jsonEncode({
        'jsonrpc': '2.0',
        'method': 'notifications/wallet_event',
        'params': event.toJson(),
      }));
    });
    webSocket.stream.listen((message) async {
      try {
        final req = jsonDecode(message as String) as Map<String, dynamic>;
        final method = req['method'] as String?;
        final params = (req['params'] as Map<String, dynamic>?) ?? {};
        final id = req['id'];
        if (method == null) {
          webSocket.sink.add(jsonEncode({
            'jsonrpc': '2.0',
            'error': {'code': -32600, 'message': 'Missing method'},
            'id': id,
          }));
          return;
        }
        final result = await bus.dispatch(method, params);
        webSocket.sink.add(jsonEncode({
          'jsonrpc': '2.0',
          'id': id,
          'result': result.toJson(serializeData),
        }));
      } catch (e) {
        webSocket.sink.add(jsonEncode({
          'jsonrpc': '2.0',
          'error': {'code': -32700, 'message': 'Parse error: $e'},
          'id': null,
        }));
      }
    }, onDone: () => sub.cancel());
  });

  static const _jsonHeaders = {'Content-Type': 'application/json'};

  Middleware _authMiddleware() {
    return (Handler handler) {
      return (Request request) {
        if (authToken != null) {
          final auth = request.headers['authorization'];
          if (auth != 'Bearer $authToken') {
            return Response.forbidden(
              jsonEncode({'error': 'Unauthorized'}),
              headers: _jsonHeaders,
            );
          }
        }
        return handler(request);
      };
    };
  }

  Future<Response> _handleCommand(Request request, String name) async {
    try {
      final payload = await request.readAsString();
      final params = payload.isNotEmpty
          ? jsonDecode(payload) as Map<String, dynamic>
          : <String, dynamic>{};
      final result = await bus.dispatch(name, params);
      return Response.ok(
        jsonEncode(result.toJson(serializeData)),
        headers: _jsonHeaders,
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'success': false, 'error': e.toString()}),
        headers: _jsonHeaders,
      );
    }
  }

  Future<Response> _handleCapabilities(Request request) async {
    final manifest = {
      'version': '0.1.0',
      'commands': bus.commands
          .map((cmd) => {
                'name': cmd.name,
                'description': cmd.description,
                'safe_for_non_interactive': cmd.isSafeForNonInteractive,
                'status': cmd.status.name,
                'destructive': cmd.isDestructive,
                'args': cmd.args.map((k, v) => MapEntry(k, {
                      'type': v.type.toString(),
                      'required': v.required,
                      'description': v.description,
                      if (v.choices != null) 'choices': v.choices,
                      if (v.defaultValue != null) 'default': v.defaultValue,
                    })),
              })
          .toList(),
    };
    return Response.ok(jsonEncode(manifest), headers: _jsonHeaders);
  }

  Future<Response> _handleSSE(Request request) async {
    final controller = StreamController<List<int>>();
    final sub = eventBus.events.listen((event) {
      final json = jsonEncode(event.toJson());
      controller.add(utf8.encode('data: $json\n\n'));
    });

    controller.onCancel = () {
      sub.cancel();
    };

    return Response.ok(
      controller.stream,
      headers: {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
      },
    );
  }
}
