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

    // Create a mutable copy — never modify the caller's map
    final effectiveParams = Map<String, dynamic>.from(params);

    // Validate required args (check both missing key and null value)
    for (final arg in cmd.args.entries) {
      if (arg.value.required &&
          (!effectiveParams.containsKey(arg.key) ||
              effectiveParams[arg.key] == null)) {
        return CommandResult.error('MISSING_ARG',
            message: 'Required argument "${arg.key}" missing');
      }
    }

    // Apply defaults for missing optional args
    for (final arg in cmd.args.entries) {
      if (!effectiveParams.containsKey(arg.key) &&
          arg.value.defaultValue != null) {
        effectiveParams[arg.key] = arg.value.defaultValue;
      }
    }

    // Central type coercion based on CommandArg.type
    for (final arg in cmd.args.entries) {
      if (!effectiveParams.containsKey(arg.key)) continue;
      final val = effectiveParams[arg.key];
      if (val == null) continue;

      if (arg.value.type == int && val is! int) {
        final parsed = int.tryParse(val.toString());
        if (parsed != null) {
          effectiveParams[arg.key] = parsed;
        } else if (arg.value.required) {
          return CommandResult.error('INVALID_ARG_TYPE',
              message:
                  'Argument "${arg.key}" must be an integer, got: $val');
        }
      } else if (arg.value.type == double && val is! double) {
        final parsed = double.tryParse(val.toString());
        if (parsed != null) {
          effectiveParams[arg.key] = parsed;
        } else if (arg.value.required) {
          return CommandResult.error('INVALID_ARG_TYPE',
              message:
                  'Argument "${arg.key}" must be a number, got: $val');
        }
      } else if (arg.value.type == bool && val is! bool) {
        effectiveParams[arg.key] =
            val.toString().toLowerCase() == 'true';
      }
    }

    // Enforce isSafeForNonInteractive
    if (!cmd.isSafeForNonInteractive &&
        _ctx.nonInteractive &&
        !_ctx.autoConfirm) {
      return CommandResult.error('INTERACTION_REQUIRED',
          message: 'Command "${cmd.name}" requires interactive confirmation. '
              'Use --yes to auto-confirm.');
    }
    try {
      return await cmd.execute(_ctx, effectiveParams);
    } catch (e, s) {
      _ctx.logger.error('Command "$name" failed: $e', s);
      return CommandResult.error('COMMAND_FAILED', message: e.toString());
    }
  }
}
