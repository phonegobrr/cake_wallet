import 'package:cake_headless/commands/command.dart';
import 'package:cake_headless/commands/command_result.dart';
import 'package:cake_headless/dto/swap_quote.dart';
import 'package:cake_headless/dto/swap_status.dart';
import 'package:cake_headless/runtime_context.dart';

class CreateSwapCommand extends WalletCommand<SwapQuote> {
  @override
  String get name => 'swap.create';
  @override
  String get description => 'Create an exchange trade from a quote';
  @override
  Map<String, CommandArg> get args => {
        'from': CommandArg(
            name: 'from', description: 'Source currency', required: true),
        'to': CommandArg(
            name: 'to', description: 'Target currency', required: true),
        'amount': CommandArg(
            name: 'amount', description: 'Amount to swap', required: true),
        'address': CommandArg(
            name: 'address', description: 'Receiving address', required: true),
        'refund': CommandArg(
            name: 'refund', description: 'Refund address'),
      };

  @override
  bool get isSafeForNonInteractive => false;

  @override
  Future<CommandResult<SwapQuote>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    if (ctx.getSwapQuote == null) {
      return CommandResult.error('SERVICE_UNAVAILABLE',
          message: 'Exchange provider not configured in this runtime');
    }
    // swap.create reuses the quote flow — actual trade creation
    // requires provider-specific API calls wired through the runtime
    final from = params['from']?.toString() ?? '';
    final to = params['to']?.toString() ?? '';
    final amount = params['amount']?.toString() ?? '';
    try {
      final quote = await ctx.getSwapQuote!(from, to, amount);
      return CommandResult.ok(quote,
          message: 'Quote obtained for swap $from -> $to. '
              'Full trade creation requires exchange provider integration.');
    } catch (e) {
      return CommandResult.error('SWAP_CREATE_FAILED', message: e.toString());
    }
  }
}

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
    final from = params['from']?.toString() ?? '';
    final to = params['to']?.toString() ?? '';
    final amount = params['amount']?.toString() ?? '';

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
    final tradeId = params['trade-id']?.toString() ?? '';

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
