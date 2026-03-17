import 'package:cake_headless/commands/command.dart';
import 'package:cake_headless/commands/command_result.dart';
import 'package:cake_headless/dto/node_info.dart';
import 'package:cake_headless/runtime_context.dart';

class ListNodesCommand extends WalletCommand<List<NodeInfo>> {
  @override
  String get name => 'nodes.list';
  @override
  String get description => 'List configured nodes';
  @override
  Map<String, CommandArg> get args => {};

  @override
  Future<CommandResult<List<NodeInfo>>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    if (ctx.listNodes == null) {
      return CommandResult.ok(<NodeInfo>[],
          message: 'Node services not initialized');
    }
    final nodes = await ctx.listNodes!();
    return CommandResult.ok(nodes);
  }
}

class AddNodeCommand extends WalletCommand<NodeInfo> {
  @override
  String get name => 'nodes.add';
  @override
  String get description => 'Add a new node';
  @override
  Map<String, CommandArg> get args => {
        'uri': CommandArg(
            name: 'uri', description: 'Node URI', required: true),
        'name': CommandArg(
            name: 'name', description: 'Node label'),
        'trusted':
            CommandArg(name: 'trusted', description: 'Is trusted', type: bool),
      };

  @override
  Future<CommandResult<NodeInfo>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    if (ctx.addNode == null) {
      return CommandResult.error('SERVICE_UNAVAILABLE',
          message: 'Node management not configured in this runtime');
    }
    final uri = params['uri']?.toString() ?? '';
    final nodeName = params['name']?.toString() ?? uri;
    final trusted = params['trusted'] == true || params['trusted'] == 'true';

    try {
      final node = await ctx.addNode!(uri, nodeName, trusted);
      return CommandResult.ok(node, message: 'Node added: $uri');
    } catch (e) {
      return CommandResult.error('NODE_ADD_FAILED', message: e.toString());
    }
  }
}

class TestNodeCommand extends WalletCommand<Map<String, dynamic>> {
  @override
  String get name => 'nodes.test';
  @override
  String get description => 'Test connection to a node';
  @override
  Map<String, CommandArg> get args => {
        'uri': CommandArg(
            name: 'uri', description: 'Node URI to test', required: true),
      };

  @override
  Future<CommandResult<Map<String, dynamic>>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    final uri = params['uri']?.toString() ?? '';
    return CommandResult.error('SERVICE_UNAVAILABLE',
        message: 'Node testing requires wallet-type-specific connection logic');
  }
}

class SelectNodeCommand extends WalletCommand<NodeInfo> {
  @override
  String get name => 'nodes.select';
  @override
  String get description => 'Select active node by URI';
  @override
  Map<String, CommandArg> get args => {
        'uri': CommandArg(
            name: 'uri', description: 'Node URI to select', required: true),
      };

  @override
  Future<CommandResult<NodeInfo>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    if (ctx.selectNode == null) {
      return CommandResult.error('SERVICE_UNAVAILABLE',
          message: 'Node selection not configured in this runtime');
    }
    final uri = params['uri']?.toString() ?? '';
    try {
      final node = await ctx.selectNode!(uri);
      return CommandResult.ok(node, message: 'Node selected: $uri');
    } catch (e) {
      return CommandResult.error('NODE_SELECT_FAILED', message: e.toString());
    }
  }
}

class DeleteNodeCommand extends WalletCommand<Map<String, String>> {
  @override
  String get name => 'nodes.delete';
  @override
  String get description => 'Delete a node by URI';
  @override
  Map<String, CommandArg> get args => {
        'uri': CommandArg(
            name: 'uri', description: 'Node URI to delete', required: true),
      };

  @override
  Future<CommandResult<Map<String, String>>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    if (ctx.deleteNode == null) {
      return CommandResult.error('SERVICE_UNAVAILABLE',
          message: 'Node management not configured in this runtime');
    }
    final uri = params['uri']?.toString() ?? '';
    try {
      await ctx.deleteNode!(uri);
      return CommandResult.ok({'deleted': uri}, message: 'Node deleted: $uri');
    } catch (e) {
      return CommandResult.error('NODE_DELETE_FAILED', message: e.toString());
    }
  }
}

class EditNodeCommand extends WalletCommand<NodeInfo> {
  @override
  String get name => 'nodes.edit';
  @override
  String get description => 'Edit an existing node';
  @override
  Map<String, CommandArg> get args => {
        'uri': CommandArg(
            name: 'uri', description: 'Current node URI', required: true),
        'new-uri': CommandArg(
            name: 'new-uri', description: 'New node URI'),
        'name': CommandArg(
            name: 'name', description: 'New node label'),
        'trusted':
            CommandArg(name: 'trusted', description: 'Is trusted', type: bool),
      };

  @override
  Future<CommandResult<NodeInfo>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    // Node editing requires delete + re-add since nodes are keyed by URI
    if (ctx.deleteNode == null || ctx.addNode == null) {
      return CommandResult.error('SERVICE_UNAVAILABLE',
          message: 'Node management not configured in this runtime');
    }
    final uri = params['uri']?.toString() ?? '';
    final newUri = params['new-uri']?.toString() ?? uri;
    final nodeName = params['name']?.toString() ?? newUri;
    final trusted = params['trusted'] == true || params['trusted'] == 'true';

    try {
      await ctx.deleteNode!(uri);
      final node = await ctx.addNode!(newUri, nodeName, trusted);
      return CommandResult.ok(node, message: 'Node updated: $newUri');
    } catch (e) {
      return CommandResult.error('NODE_EDIT_FAILED', message: e.toString());
    }
  }
}

class ResetNodesCommand extends WalletCommand<Map<String, String>> {
  @override
  String get name => 'nodes.reset';
  @override
  String get description => 'Reset nodes to defaults for the current wallet type';
  @override
  Map<String, CommandArg> get args => {};

  @override
  Future<CommandResult<Map<String, String>>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    return CommandResult.error('SERVICE_UNAVAILABLE',
        message: 'Node reset requires wallet-type-specific default node list');
  }
}
