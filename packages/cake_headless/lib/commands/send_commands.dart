import 'package:cake_headless/commands/command.dart';
import 'package:cake_headless/commands/command_result.dart';
import 'package:cake_headless/dto/send_result.dart';
import 'package:cake_headless/runtime_context.dart';

class SendPreviewCommand extends WalletCommand<Map<String, String>> {
  @override
  String get name => 'send.preview';
  @override
  String get description => 'Preview a transaction without sending';
  @override
  Map<String, CommandArg> get args => {
        'address': CommandArg(
            name: 'address', description: 'Destination address', required: true),
        'amount': CommandArg(
            name: 'amount', description: 'Amount to send', required: true),
        'priority':
            CommandArg(name: 'priority', description: 'Transaction priority'),
      };

  @override
  Future<CommandResult<Map<String, String>>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    if (!ctx.hasWallet) {
      return CommandResult.error('NO_WALLET', message: ctx.strings.noWalletOpen);
    }
    final address = params['address']?.toString() ?? '';
    final amount = params['amount']?.toString() ?? '';

    // Resolve address via headless resolver if available
    String resolvedAddress = address;
    if (ctx.resolveAddress != null) {
      try {
        resolvedAddress = await ctx.resolveAddress!(
            address, ctx.wallet!.currency.title);
      } catch (_) {
        // Fall back to raw address
      }
    }

    return CommandResult.ok({
      'address': resolvedAddress,
      'amount': amount,
      'currency': ctx.wallet!.currency.title,
      'priority': params['priority']?.toString() ?? 'default',
    }, message: 'Transaction preview — use send to execute');
  }
}

class SendMaxCommand extends WalletCommand<Map<String, String>> {
  @override
  String get name => 'send.max';
  @override
  String get description => 'Get maximum sendable amount';
  @override
  Map<String, CommandArg> get args => {};

  @override
  Future<CommandResult<Map<String, String>>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    if (!ctx.hasWallet) {
      return CommandResult.error('NO_WALLET', message: ctx.strings.noWalletOpen);
    }
    final wallet = ctx.wallet!;
    final balanceMap = wallet.balance;
    if (balanceMap.isEmpty) {
      return CommandResult.error('NO_BALANCE', message: 'No balance available');
    }
    final primaryBalance = balanceMap.values.first;
    return CommandResult.ok({
      'available': primaryBalance.available.toString(),
      'currency': wallet.currency.title,
    }, message: 'Maximum sendable: ${primaryBalance.available} ${wallet.currency.title}');
  }
}

class SendAllCommand extends WalletCommand<SendResult> {
  @override
  String get name => 'send.send-all';
  @override
  String get description => 'Send entire wallet balance to an address';
  @override
  Map<String, CommandArg> get args => {
        'address': CommandArg(
            name: 'address', description: 'Destination address', required: true),
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
    final address = params['address']?.toString() ?? '';
    if (address.isEmpty) {
      return CommandResult.error('INVALID_ARGS',
          message: 'Address is required');
    }

    // Get max sendable amount
    final balanceMap = ctx.wallet!.balance;
    if (balanceMap.isEmpty) {
      return CommandResult.error('NO_BALANCE', message: 'No balance available');
    }
    final maxAmount = balanceMap.values.first.available.toString();
    final priority = params['priority']?.toString();

    if (ctx.sendTransaction != null) {
      try {
        final result = await ctx.sendTransaction!(address, maxAmount,
            priority: priority);
        return CommandResult.ok(result,
            message: 'Send-all transaction sent: ${result.txHash}');
      } catch (e) {
        return CommandResult.error('SEND_FAILED', message: e.toString());
      }
    }

    return CommandResult.error('SERVICE_UNAVAILABLE',
        message: 'Send service not configured in this runtime');
  }
}

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
