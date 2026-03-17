import 'package:cake_headless/commands/command.dart';
import 'package:cake_headless/commands/command_result.dart';
import 'package:cake_headless/dto/address_entry.dart';
import 'package:cake_headless/runtime_context.dart';

class GetReceiveAddressCommand extends WalletCommand<AddressEntry> {
  @override
  String get name => 'receive.address';
  @override
  String get description => 'Get receive address for current wallet';
  @override
  Map<String, CommandArg> get args => {};

  @override
  Future<CommandResult<AddressEntry>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    final wallet = ctx.wallet;
    if (wallet == null) {
      return CommandResult.error('NO_WALLET', message: ctx.strings.noWalletOpen);
    }

    final address = wallet.walletAddresses.address;
    return CommandResult.ok(AddressEntry(
      address: address,
      label: wallet.walletInfo.name,
      currencyTitle: wallet.currency.title,
    ));
  }
}
