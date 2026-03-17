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
    final wallet = ctx.wallet;
    if (wallet == null) {
      return CommandResult.error('NO_WALLET', message: ctx.strings.noWalletOpen);
    }

    final address = params['address'] as String;
    final amount = params['amount'] as String;

    ctx.logger.info(
        'Preparing transaction: $amount ${wallet.currency.title} -> $address');

    // Transaction creation requires wallet-type-specific credential building.
    // The actual implementation will be wired through a send service that
    // creates credentials, calls wallet.createTransaction(), and commits.
    // For now, return the validated parameters as a preview.
    return CommandResult.ok(
      SendResult(
        txHash: '',
        amount: amount,
        address: address,
        fee: '0',
      ),
      message: 'Send command received — full transaction creation '
          'requires wallet-type-specific credential building',
    );
  }
}
