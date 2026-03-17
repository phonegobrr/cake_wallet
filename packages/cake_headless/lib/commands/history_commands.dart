import 'package:cake_headless/commands/command.dart';
import 'package:cake_headless/commands/command_result.dart';
import 'package:cake_headless/dto/transaction_summary.dart';
import 'package:cake_headless/runtime_context.dart';
import 'package:cw_core/transaction_direction.dart';


class GetTransactionDetailsCommand extends WalletCommand<TransactionSummary> {
  @override
  String get name => 'history.details';
  @override
  String get description => 'Get details of a specific transaction';
  @override
  Map<String, CommandArg> get args => {
        'id': CommandArg(
            name: 'id', description: 'Transaction ID', required: true),
      };

  @override
  Future<CommandResult<TransactionSummary>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    if (!ctx.hasWallet) {
      return CommandResult.error('NO_WALLET', message: ctx.strings.noWalletOpen);
    }
    final wallet = ctx.wallet!;
    final txId = params['id']?.toString() ?? '';
    final history = wallet.transactionHistory;
    final tx = history.transactions[txId];
    if (tx == null) {
      return CommandResult.error('NOT_FOUND',
          message: 'Transaction "$txId" not found');
    }
    return CommandResult.ok(TransactionSummary(
      id: tx.id,
      amount: tx.amountFormatted(),
      fee: tx.feeFormatted() ?? '0',
      dateFormatted: tx.date.toIso8601String(),
      isIncoming: tx.direction == TransactionDirection.incoming,
      isPending: tx.isPending,
      confirmations: tx.confirmations,
    ));
  }
}

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
    if (!ctx.hasWallet) {
      return CommandResult.error('NO_WALLET', message: ctx.strings.noWalletOpen);
    }
    final wallet = ctx.wallet!;

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
