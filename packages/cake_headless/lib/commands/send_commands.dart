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
  bool get isSafeForNonInteractive => false;

  @override
  Future<CommandResult<SendResult>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    if (!ctx.hasWallet) {
      return CommandResult.error('NO_WALLET', message: ctx.strings.noWalletOpen);
    }
    final wallet = ctx.wallet!;

    final address = params['address']?.toString() ?? '';
    final amount = params['amount']?.toString() ?? '';
    final priority = params['priority']?.toString();

    if (address.isEmpty || amount.isEmpty) {
      return CommandResult.error('INVALID_ARGS',
          message: 'Address and amount are required');
    }

    ctx.logger.info(
        'Preparing transaction: $amount ${wallet.currency.title} -> $address');

    if (ctx.sendTransaction != null) {
      try {
        final result = await ctx.sendTransaction!(address, amount,
            priority: priority);
        return CommandResult.ok(result,
            message: 'Transaction sent: ${result.txHash}');
      } catch (e) {
        return CommandResult.error('SEND_FAILED', message: e.toString());
      }
    }

    return CommandResult.error('SERVICE_UNAVAILABLE',
        message: 'Send service not configured in this runtime');
  }
}
