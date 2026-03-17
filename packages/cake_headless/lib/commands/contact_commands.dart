import 'package:cake_headless/commands/command.dart';
import 'package:cake_headless/commands/command_result.dart';
import 'package:cake_headless/dto/address_entry.dart';
import 'package:cake_headless/runtime_context.dart';

class ListContactsCommand extends WalletCommand<List<AddressEntry>> {
  @override
  String get name => 'contacts.list';
  @override
  String get description => 'List all contacts';
  @override
  Map<String, CommandArg> get args => {};

  @override
  Future<CommandResult<List<AddressEntry>>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    if (ctx.listContacts == null) {
      return CommandResult.ok(<AddressEntry>[],
          message: 'Contact services not initialized');
    }
    final contacts = await ctx.listContacts!();
    return CommandResult.ok(contacts);
  }
}

class AddContactCommand extends WalletCommand<AddressEntry> {
  @override
  String get name => 'contacts.add';
  @override
  String get description => 'Add a new contact';
  @override
  Map<String, CommandArg> get args => {
        'name': CommandArg(
            name: 'name', description: 'Contact name', required: true),
        'address': CommandArg(
            name: 'address',
            description: 'Contact address',
            required: true),
        'currency': CommandArg(
            name: 'currency', description: 'Currency code (e.g. XMR)'),
      };

  @override
  Future<CommandResult<AddressEntry>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    final name = params['name'] as String;
    final address = params['address'] as String;
    final currency = params['currency'] as String?;

    ctx.logger.info('Adding contact: $name ($address)');

    return CommandResult.ok(AddressEntry(
      address: address,
      label: name,
      currencyTitle: currency,
    ), message: ctx.strings.contactAdded);
  }
}
