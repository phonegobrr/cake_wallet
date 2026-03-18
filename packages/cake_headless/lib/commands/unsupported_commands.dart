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
      // Buy / Fiat on-ramp
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
        name: 'buy.create',
        description: 'Create fiat purchase',
        reason: 'Fiat purchases require browser-based KYC flow',
      ),

      // Sell / Fiat off-ramp
      UnsupportedCommand(
        name: 'sell.providers',
        description: 'List fiat off-ramp providers',
        reason: 'Fiat sales require browser-based KYC flow',
      ),
      UnsupportedCommand(
        name: 'sell.quote',
        description: 'Get fiat sell quote',
        reason: 'Fiat sales require browser-based KYC flow',
      ),
      UnsupportedCommand(
        name: 'sell.create',
        description: 'Create fiat sale',
        reason: 'Fiat sales require browser-based KYC flow',
      ),

      // Cake Pay
      UnsupportedCommand(
        name: 'cakepay.auth',
        description: 'Authenticate with Cake Pay',
        reason: 'Cake Pay requires authenticated session with Cake Pay API',
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
        name: 'cakepay.account',
        description: 'Get Cake Pay account info',
        reason: 'Cake Pay requires authenticated session with Cake Pay API',
      ),

      // Hardware wallet
      UnsupportedCommand(
        name: 'hardware.list',
        description: 'List hardware wallets',
        reason: 'Hardware wallet requires USB/BLE access',
      ),
      UnsupportedCommand(
        name: 'hardware.connect',
        description: 'Connect to hardware wallet',
        reason: 'Hardware wallet requires USB/BLE access',
      ),
      UnsupportedCommand(
        name: 'hardware.accounts',
        description: 'List hardware wallet accounts',
        reason: 'Hardware wallet requires USB/BLE access',
      ),
      UnsupportedCommand(
        name: 'hardware.sign',
        description: 'Sign with hardware wallet',
        reason: 'Hardware wallet requires USB/BLE access',
      ),

      // WalletConnect
      UnsupportedCommand(
        name: 'walletconnect.connect',
        description: 'Connect via WalletConnect',
        reason: 'WalletConnect requires WebSocket session management and QR code interaction',
      ),
      UnsupportedCommand(
        name: 'walletconnect.sessions',
        description: 'List WalletConnect sessions',
        reason: 'WalletConnect requires WebSocket session management',
      ),

      // Payjoin
      UnsupportedCommand(
        name: 'payjoin.create',
        description: 'Create a Payjoin transaction',
        reason: 'Payjoin requires specialized interaction flows',
      ),
      UnsupportedCommand(
        name: 'payjoin.status',
        description: 'Check Payjoin status',
        reason: 'Payjoin requires platform-specific mobile services',
      ),

    ];
