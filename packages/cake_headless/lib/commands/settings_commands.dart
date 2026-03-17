import 'package:cake_headless/commands/command.dart';
import 'package:cake_headless/commands/command_result.dart';
import 'package:cake_headless/dto/sync_status_summary.dart';
import 'package:cake_headless/runtime_context.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/wallet_base.dart';

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
    final keys = [
      'current_fiat_currency',
      'current_exchange_mode',
      'current_default_settings_migration_version',
      'current_pin_length',
      'current_language_code',
      'current_theme',
      'bitcoin_amount_display_mode',
      'should_save_recipient_address',
      'allow_biometrical_authentication',
    ];
    final result = <String, String>{};
    for (final key in keys) {
      final val = await ctx.settings.getString(key);
      if (val != null) result[key] = val;
    }
    return CommandResult.ok(result);
  }
}

class SetSettingCommand extends WalletCommand<Map<String, String>> {
  @override
  String get name => 'settings.set';
  @override
  String get description => 'Update a setting';
  @override
  Map<String, CommandArg> get args => {
        'key': CommandArg(
            name: 'key', description: 'Setting key', required: true),
        'value': CommandArg(
            name: 'value', description: 'Setting value', required: true),
      };

  @override
  Future<CommandResult<Map<String, String>>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    final key = params['key']?.toString() ?? '';
    final value = params['value']?.toString() ?? '';
    await ctx.settings.setString(key, value);
    ctx.logger.info('Setting updated: $key = $value');
    return CommandResult.ok(
      {key: value},
      message: ctx.strings.settingUpdated,
    );
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
    if (ctx.wallet == null || ctx.wallet is! WalletBase) {
      return CommandResult.error('NO_WALLET',
          message: ctx.strings.noWalletOpen);
    }
    final wallet = ctx.wallet as WalletBase;
    final status = wallet.syncStatus;

    return CommandResult.ok(SyncStatusSummary(
      isSynced: status is SyncedSyncStatus,
      progress: status.progress(),
      displayText: status.toString(),
    ));
  }
}
