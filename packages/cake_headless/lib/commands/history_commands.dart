import 'package:cake_headless/commands/command.dart';
import 'package:cake_headless/commands/command_result.dart';
import 'package:cake_headless/dto/transaction_summary.dart';
import 'package:cake_headless/runtime_context.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/wallet_base.dart';

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
    final wallet = ctx.wallet as WalletBase?;
    if (wallet == null) {
      return CommandResult.error('NO_WALLET', message: ctx.strings.noWalletOpen);
    }

    final limit = (params['limit'] is int)
        ? params['limit'] as int
        : int.tryParse(params['limit']?.toString() ?? '50') ?? 50;

    final history = wallet.transactionHistory;
    final txs = history.transactions.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final limited = txs.take(limit).toList();

    return CommandResult.ok(limited
        .map((tx) => TransactionSummary(
              id: tx.id,
              amount: tx.amountFormatted(),
              fee: tx.feeFormatted() ?? '0',
              dateFormatted: tx.date.toIso8601String(),
              isIncoming: tx.direction == TransactionDirection.incoming,
              isPending: tx.isPending,
              confirmations: tx.confirmations,
            ))
        .toList());
  }
}
