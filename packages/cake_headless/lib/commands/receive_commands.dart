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
    if (!ctx.hasWallet) {
      return CommandResult.error('NO_WALLET', message: ctx.strings.noWalletOpen);
    }
    final wallet = ctx.wallet!;

    final address = wallet.walletAddresses.address;
    return CommandResult.ok(AddressEntry(
      address: address,
      label: wallet.walletInfo.name,
      currencyTitle: wallet.currency.title,
    ));
  }
}

class ListAddressesCommand extends WalletCommand<List<AddressEntry>> {
  @override
  String get name => 'receive.list';
  @override
  String get description => 'List all receive addresses';
  @override
  Map<String, CommandArg> get args => {};

  @override
  Future<CommandResult<List<AddressEntry>>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    if (!ctx.hasWallet) {
      return CommandResult.error('NO_WALLET', message: ctx.strings.noWalletOpen);
    }
    final wallet = ctx.wallet!;
    try {
      final addresses = wallet.walletAddresses.addressesMap.entries
          .map((e) => AddressEntry(
                address: e.key,
                label: e.value,
                currencyTitle: wallet.currency.title,
              ))
          .toList();
      if (addresses.isEmpty) {
        return CommandResult.ok([
          AddressEntry(
            address: wallet.walletAddresses.address,
            label: 'Primary',
            currencyTitle: wallet.currency.title,
          )
        ]);
      }
      return CommandResult.ok(addresses);
    } catch (_) {
      return CommandResult.ok([
        AddressEntry(
          address: wallet.walletAddresses.address,
          label: 'Primary',
          currencyTitle: wallet.currency.title,
        )
      ]);
    }
  }
}

class GenerateNewAddressCommand extends WalletCommand<AddressEntry> {
  @override
  String get name => 'receive.new';
  @override
  String get description => 'Generate a new receive address (subaddress)';
  @override
  Map<String, CommandArg> get args => {
        'label':
            CommandArg(name: 'label', description: 'Label for the new address'),
      };

  @override
  Future<CommandResult<AddressEntry>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    if (!ctx.hasWallet) {
      return CommandResult.error('NO_WALLET', message: ctx.strings.noWalletOpen);
    }
    // Subaddress generation is wallet-type specific
    return CommandResult.error('SERVICE_UNAVAILABLE',
        message: 'Subaddress generation requires wallet-type-specific logic. '
            'Use receive.address for the current primary address.');
  }
}

class RotateAddressCommand extends WalletCommand<AddressEntry> {
  @override
  String get name => 'receive.rotate';
  @override
  String get description => 'Rotate to the next unused receive address';
  @override
  Map<String, CommandArg> get args => {};

  @override
  Future<CommandResult<AddressEntry>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    if (!ctx.hasWallet) {
      return CommandResult.error('NO_WALLET', message: ctx.strings.noWalletOpen);
    }
    return CommandResult.error('SERVICE_UNAVAILABLE',
        message: 'Address rotation requires wallet-type-specific subaddress generation. '
            'Use receive.address for the current address.');
  }
}

class LabelAddressCommand extends WalletCommand<Map<String, String>> {
  @override
  String get name => 'receive.label';
  @override
  String get description => 'Set a label on a receive address';
  @override
  Map<String, CommandArg> get args => {
        'address': CommandArg(
            name: 'address', description: 'Address to label', required: true),
        'label': CommandArg(
            name: 'label', description: 'Label text', required: true),
      };

  @override
  Future<CommandResult<Map<String, String>>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    if (!ctx.hasWallet) {
      return CommandResult.error('NO_WALLET', message: ctx.strings.noWalletOpen);
    }
    return CommandResult.error('SERVICE_UNAVAILABLE',
        message: 'Address labeling requires wallet-type-specific subaddress management');
  }
}

class HideAddressCommand extends WalletCommand<Map<String, String>> {
  @override
  String get name => 'receive.hide';
  @override
  String get description => 'Hide a receive address from the list';
  @override
  Map<String, CommandArg> get args => {
        'address': CommandArg(
            name: 'address', description: 'Address to hide', required: true),
      };

  @override
  Future<CommandResult<Map<String, String>>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    if (!ctx.hasWallet) {
      return CommandResult.error('NO_WALLET', message: ctx.strings.noWalletOpen);
    }
    return CommandResult.error('SERVICE_UNAVAILABLE',
        message: 'Address visibility requires wallet-type-specific subaddress management');
  }
}

class UnhideAddressCommand extends WalletCommand<Map<String, String>> {
  @override
  String get name => 'receive.unhide';
  @override
  String get description => 'Unhide a hidden receive address';
  @override
  Map<String, CommandArg> get args => {
        'address': CommandArg(
            name: 'address', description: 'Address to unhide', required: true),
      };

  @override
  Future<CommandResult<Map<String, String>>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    if (!ctx.hasWallet) {
      return CommandResult.error('NO_WALLET', message: ctx.strings.noWalletOpen);
    }
    return CommandResult.error('SERVICE_UNAVAILABLE',
        message: 'Address visibility requires wallet-type-specific subaddress management');
  }
}

class GetReceiveUriCommand extends WalletCommand<Map<String, String>> {
  @override
  String get name => 'receive.uri';
  @override
  String get description => 'Get a payment URI for the current address';
  @override
  Map<String, CommandArg> get args => {
        'amount':
            CommandArg(name: 'amount', description: 'Amount to request'),
      };

  @override
  Future<CommandResult<Map<String, String>>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    if (!ctx.hasWallet) {
      return CommandResult.error('NO_WALLET', message: ctx.strings.noWalletOpen);
    }
    final wallet = ctx.wallet!;
    final address = wallet.walletAddresses.address;
    final amount = params['amount']?.toString();
    // Use wallet-specific URI builder if available
    String uri;
    try {
      uri = (wallet.walletAddresses as dynamic).getPaymentUri(amount: amount) as String;
    } catch (_) {
      // Fallback for wallets without a getPaymentUri method
      final scheme = wallet.currency.title.toLowerCase();
      uri = amount != null ? '$scheme:$address?amount=$amount' : address;
    }
    return CommandResult.ok({'uri': uri, 'address': address});
  }
}
