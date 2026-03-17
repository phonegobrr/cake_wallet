import 'package:cake_headless/commands/command.dart';
import 'package:cake_headless/commands/command_result.dart';
import 'package:cake_headless/dto/backup_result.dart';
import 'package:cake_headless/runtime_context.dart';

class ExportBackupCommand extends WalletCommand<BackupResult> {
  @override
  String get name => 'backup.export';
  @override
  String get description => 'Export encrypted backup';
  @override
  Map<String, CommandArg> get args => {
        'output': CommandArg(
            name: 'output',
            description: 'Output file path',
            required: true),
      };

  @override
  bool get isSafeForNonInteractive => false;

  @override
  Future<CommandResult<BackupResult>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    final output = params['output'] as String;

    ctx.logger.info('Exporting backup to: $output');

    // Backup export requires BackupServiceV3 which depends on full DI.
    // Return structured error until backup service is wired.
    return CommandResult.error('NOT_IMPLEMENTED',
        message: 'Backup export requires BackupServiceV3 integration');
  }
}

class ImportBackupCommand extends WalletCommand<BackupResult> {
  @override
  String get name => 'backup.import';
  @override
  String get description => 'Import encrypted backup';
  @override
  Map<String, CommandArg> get args => {
        'input': CommandArg(
            name: 'input',
            description: 'Input backup file path',
            required: true),
      };

  @override
  bool get isSafeForNonInteractive => false;

  @override
  Future<CommandResult<BackupResult>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    final input = params['input'] as String;

    ctx.logger.info('Importing backup from: $input');

    return CommandResult.error('NOT_IMPLEMENTED',
        message: 'Backup import requires BackupServiceV3 integration');
  }
}
