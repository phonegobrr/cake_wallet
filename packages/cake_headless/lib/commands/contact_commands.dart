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
    final contactName = params['name']?.toString() ?? '';
    final address = params['address']?.toString() ?? '';
    final currency = params['currency']?.toString();

    if (ctx.addContact == null) {
      return CommandResult.error('SERVICE_UNAVAILABLE',
          message: 'Contact persistence not configured in this runtime');
    }

    try {
      final entry = await ctx.addContact!(contactName, address, currency);
      return CommandResult.ok(entry, message: ctx.strings.contactAdded);
    } catch (e) {
      return CommandResult.error('CONTACT_ADD_FAILED', message: e.toString());
    }
  }
}

class DeleteContactCommand extends WalletCommand<Map<String, String>> {
  @override
  String get name => 'contacts.delete';
  @override
  String get description => 'Delete a contact by name';
  @override
  Map<String, CommandArg> get args => {
        'name': CommandArg(
            name: 'name', description: 'Contact name', required: true),
      };

  @override
  Future<CommandResult<Map<String, String>>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    if (ctx.deleteContact == null) {
      return CommandResult.error('SERVICE_UNAVAILABLE',
          message: 'Contact management not configured in this runtime');
    }
    final contactName = params['name']?.toString() ?? '';
    try {
      await ctx.deleteContact!(contactName);
      return CommandResult.ok(
        {'deleted': contactName},
        message: 'Contact "$contactName" deleted',
      );
    } catch (e) {
      return CommandResult.error('CONTACT_DELETE_FAILED',
          message: e.toString());
    }
  }
}
