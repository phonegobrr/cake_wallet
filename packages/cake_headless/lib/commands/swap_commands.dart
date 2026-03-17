import 'package:cake_headless/commands/command.dart';
import 'package:cake_headless/commands/command_result.dart';
import 'package:cake_headless/dto/swap_quote.dart';
import 'package:cake_headless/dto/swap_status.dart';
import 'package:cake_headless/runtime_context.dart';

class GetSwapQuoteCommand extends WalletCommand<SwapQuote> {
  @override
  String get name => 'swap.quote';
  @override
  String get description => 'Get exchange quote for a swap';
  @override
  Map<String, CommandArg> get args => {
        'from': CommandArg(
            name: 'from',
            description: 'Source currency (e.g. XMR)',
            required: true),
        'to': CommandArg(
            name: 'to',
            description: 'Target currency (e.g. BTC)',
            required: true),
        'amount': CommandArg(
            name: 'amount',
            description: 'Amount to swap',
            required: true),
      };

  @override
  Future<CommandResult<SwapQuote>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    final from = params['from'] as String;
    final to = params['to'] as String;
    final amount = params['amount'] as String;

    if (ctx.getSwapQuote == null) {
      return CommandResult.error('SERVICE_UNAVAILABLE',
          message: 'Exchange provider not configured in this runtime');
    }

    try {
      final quote = await ctx.getSwapQuote!(from, to, amount);
      return CommandResult.ok(quote);
    } catch (e) {
      return CommandResult.error('SWAP_QUOTE_FAILED', message: e.toString());
    }
  }
}

class GetSwapStatusCommand extends WalletCommand<SwapStatus> {
  @override
  String get name => 'swap.status';
  @override
  String get description => 'Check status of an exchange trade';
  @override
  Map<String, CommandArg> get args => {
        'trade-id': CommandArg(
            name: 'trade-id',
            description: 'Trade ID to check',
            required: true),
      };

  @override
  Future<CommandResult<SwapStatus>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    final tradeId = params['trade-id'] as String;

    if (ctx.getSwapStatus == null) {
      return CommandResult.error('SERVICE_UNAVAILABLE',
          message: 'Exchange provider not configured in this runtime');
    }

    try {
      final status = await ctx.getSwapStatus!(tradeId);
      return CommandResult.ok(status);
    } catch (e) {
      return CommandResult.error('SWAP_STATUS_FAILED', message: e.toString());
    }
  }
}
