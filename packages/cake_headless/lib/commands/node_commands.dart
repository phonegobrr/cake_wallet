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
