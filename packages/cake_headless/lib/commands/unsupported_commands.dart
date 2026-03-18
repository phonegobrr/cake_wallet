import 'package:cake_headless/commands/command.dart';
import 'package:cake_headless/commands/command_result.dart';
import 'package:cake_headless/runtime_context.dart';

/// Generic command stub for features intentionally unsupported in headless mode.
class UnsupportedCommand extends WalletCommand<Map<String, String>> {
  @override
  final String name;
  @override
  final String description;
  final String reason;

  UnsupportedCommand({
    required this.name,
    required this.description,
    required this.reason,
  });

  @override
  Map<String, CommandArg> get args => {};

  @override
  CommandStatus get status => CommandStatus.unsupported;

  @override
  Future<CommandResult<Map<String, String>>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    return CommandResult.error('UNSUPPORTED_ON_PLATFORM',
        message: reason);
  }
}

/// Factory for all UNSUPPORTED stubs
List<UnsupportedCommand> createUnsupportedCommands() => [
      UnsupportedCommand(
        name: 'buy.providers',
        description: 'List fiat on-ramp providers',
        reason: 'Fiat purchases require browser-based KYC flow',
      ),
      UnsupportedCommand(
        name: 'buy.quote',
        description: 'Get fiat purchase quote',
        reason: 'Fiat purchases require browser-based KYC flow',
      ),
      UnsupportedCommand(
        name: 'cakepay.cards',
        description: 'List Cake Pay gift cards',
        reason: 'Cake Pay requires authenticated session with Cake Pay API',
      ),
      UnsupportedCommand(
        name: 'cakepay.purchase',
        description: 'Purchase a Cake Pay gift card',
        reason: 'Cake Pay requires authenticated session with Cake Pay API',
      ),
      UnsupportedCommand(
        name: 'hardware.connect',
        description: 'Connect to hardware wallet',
        reason: 'Hardware wallet interaction requires USB/BLE which is not available headless',
      ),
      UnsupportedCommand(
        name: 'hardware.sign',
        description: 'Sign transaction with hardware wallet',
        reason: 'Hardware wallet interaction requires USB/BLE which is not available headless',
      ),
      UnsupportedCommand(
        name: 'wallet.sign',
        description: 'Sign a message with wallet key',
        reason: 'Message signing requires wallet-type-specific cryptographic operations not yet available headless',
      ),
      UnsupportedCommand(
        name: 'wallet.verify',
        description: 'Verify a signed message',
        reason: 'Message verification requires wallet-type-specific cryptographic operations not yet available headless',
      ),
    ];
