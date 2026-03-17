import 'package:cake_headless/commands/command.dart';
import 'package:cake_headless/commands/command_result.dart';
import 'package:cake_headless/runtime_context.dart';

class FiatConvertCommand extends WalletCommand<Map<String, String>> {
  @override
  String get name => 'fiat.convert';
  @override
  String get description => 'Convert between fiat and crypto amounts';
  @override
  Map<String, CommandArg> get args => {
        'amount': CommandArg(
            name: 'amount', description: 'Amount to convert', required: true),
        'from': CommandArg(
            name: 'from',
            description: 'Source currency (e.g. USD, XMR)',
            required: true),
        'to': CommandArg(
            name: 'to',
            description: 'Target currency (e.g. XMR, USD)',
            required: true),
      };

  @override
  Future<CommandResult<Map<String, String>>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    return CommandResult.error('SERVICE_UNAVAILABLE',
        message: 'Fiat conversion requires fiat rate provider integration');
  }
}
