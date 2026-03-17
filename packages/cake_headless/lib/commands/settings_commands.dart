import 'package:cake_headless/commands/command.dart';
import 'package:cake_headless/commands/command_result.dart';
import 'package:cake_headless/dto/sync_status_summary.dart';
import 'package:cake_headless/runtime_context.dart';

class ListSettingsCommand extends WalletCommand<Map<String, String>> {
  @override
  String get name => 'settings.list';
  @override
  String get description => 'List current settings';
  @override
  Map<String, CommandArg> get args => {};

  @override
  Future<CommandResult<Map<String, String>>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    ctx.logger.info('Listing settings...');
    return CommandResult.ok(<String, String>{});
  }
}

class GetSyncStatusCommand extends WalletCommand<SyncStatusSummary> {
  @override
  String get name => 'sync.status';
  @override
  String get description => 'Get wallet sync status';
  @override
  Map<String, CommandArg> get args => {};

  @override
  Future<CommandResult<SyncStatusSummary>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    ctx.logger.info('Getting sync status...');
    return CommandResult.error('NO_WALLET', message: ctx.strings.noWalletOpen);
  }
}
