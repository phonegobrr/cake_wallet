import 'package:cake_headless/commands/command.dart';
import 'package:cake_headless/commands/command_result.dart';
import 'package:cake_headless/dto/transaction_summary.dart';
import 'package:cake_headless/runtime_context.dart';

class ListTransactionsCommand extends WalletCommand<List<TransactionSummary>> {
  @override
  String get name => 'history.list';
  @override
  String get description => 'List transaction history';
  @override
  Map<String, CommandArg> get args => {
        'limit': CommandArg(
            name: 'limit',
            description: 'Max number of transactions',
            type: int,
            defaultValue: '50'),
      };

  @override
  Future<CommandResult<List<TransactionSummary>>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    ctx.logger.info('Listing transactions...');
    return CommandResult.error('NO_WALLET', message: ctx.strings.noWalletOpen);
  }
}
