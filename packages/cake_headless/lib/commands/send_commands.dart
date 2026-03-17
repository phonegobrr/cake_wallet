import 'package:cake_headless/commands/command.dart';
import 'package:cake_headless/commands/command_result.dart';
import 'package:cake_headless/dto/send_result.dart';
import 'package:cake_headless/runtime_context.dart';

class SendCommand extends WalletCommand<SendResult> {
  @override
  String get name => 'send';
  @override
  String get description => 'Send a transaction';
  @override
  Map<String, CommandArg> get args => {
        'address': CommandArg(
            name: 'address',
            description: 'Destination address',
            required: true),
        'amount': CommandArg(
            name: 'amount', description: 'Amount to send', required: true),
        'priority':
            CommandArg(name: 'priority', description: 'Transaction priority'),
      };

  @override
  Future<CommandResult<SendResult>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    ctx.logger.info('Creating transaction...');
    return CommandResult.error('NO_WALLET', message: ctx.strings.noWalletOpen);
  }
}
