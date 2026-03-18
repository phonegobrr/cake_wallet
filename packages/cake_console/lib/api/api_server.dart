import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
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
    final router = Router();

    // REST command dispatch
    router.post('/api/v1/command/<name>', _handleCommand);

    // Capabilities / manifest
    router.get('/api/v1/capabilities', _handleCapabilities);

    // SSE event stream
    router.get('/api/v1/events', _handleSSE);

    // Health check
    router.get('/api/v1/health', (Request request) {
      return Response.ok(
        jsonEncode({'status': 'ok', 'timestamp': DateTime.now().toIso8601String()}),
        headers: {'Content-Type': 'application/json'},
      );
    });

    var handler = const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(_authMiddleware())
        .addHandler(router.call);

    final server = await shelf_io.serve(handler, bind, port);
    stderr.writeln('[API] Server running on http://$bind:$port');
    return server;
  }

  Middleware _authMiddleware() {
    return (Handler handler) {
      return (Request request) {
        if (authToken != null) {
          final auth = request.headers['authorization'];
          if (auth != 'Bearer $authToken') {
            return Response.forbidden(
              jsonEncode({'error': 'Unauthorized'}),
              headers: {'Content-Type': 'application/json'},
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
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'success': false, 'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
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
    return Response.ok(
      jsonEncode(manifest),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> _handleSSE(Request request) async {
    // Server-Sent Events stream
    final controller = StreamController<List<int>>();
    final sub = eventBus.events.listen((event) {
      final json = jsonEncode({
        'type': event.type.name,
        'data': event.data,
        'timestamp': event.timestamp.toIso8601String(),
      });
      controller.add(utf8.encode('data: $json\n\n'));
    });

    // Clean up when client disconnects
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

  /// Create a WebSocket handler for bidirectional JSON-RPC + event push
  FutureOr<Response> handleWebSocket(Request request) {
    // Use shelf_web_socket or raw upgrade — keeping simple for now
    // This would be registered as: router.get('/ws', handleWebSocket);
    return Response(
      HttpStatus.notImplemented,
      body: 'WebSocket endpoint — use /api/v1/events for SSE or /api/v1/command for REST',
    );
  }
}
