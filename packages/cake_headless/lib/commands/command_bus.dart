import 'package:cake_headless/commands/command.dart';
import 'package:cake_headless/commands/command_result.dart';
import 'package:cake_headless/runtime_context.dart';

class CommandBus {
  final Map<String, WalletCommand> _commands = {};
  final CakeRuntimeContext _ctx;

  CommandBus(this._ctx);

  void register(WalletCommand cmd) {
    if (_commands.containsKey(cmd.name)) {
      throw StateError('Command "${cmd.name}" already registered');
    }
    _commands[cmd.name] = cmd;
  }

  List<WalletCommand> get commands => _commands.values.toList();

  WalletCommand? getCommand(String name) => _commands[name];

  Future<CommandResult> dispatch(
    String name,
    Map<String, dynamic> params,
  ) async {
    final cmd = _commands[name];
    if (cmd == null) {
      return CommandResult.error('UNKNOWN_COMMAND',
          message: 'Command "$name" not found');
    }
    for (final arg in cmd.args.entries) {
      if (arg.value.required && !params.containsKey(arg.key)) {
        return CommandResult.error('MISSING_ARG',
            message: 'Required argument "${arg.key}" missing');
      }
    }
    return cmd.execute(_ctx, params);
  }
}
