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

    ctx.logger.info('Getting swap quote: $amount $from -> $to');

    // Exchange provider integration requires wallet-specific exchange services.
    // Return structured error until exchange providers are wired.
    return CommandResult.error('NOT_IMPLEMENTED',
        message: 'Exchange quote requires exchange provider integration');
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

    ctx.logger.info('Checking swap status for trade: $tradeId');

    return CommandResult.error('NOT_IMPLEMENTED',
        message: 'Swap status tracking requires exchange provider integration');
  }
}
