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
    final output = params['output']?.toString() ?? '';

    if (ctx.exportBackup == null) {
      return CommandResult.error('SERVICE_UNAVAILABLE',
          message: 'Backup service not configured in this runtime');
    }

    try {
      final result = await ctx.exportBackup!(output);
      return CommandResult.ok(result);
    } catch (e) {
      return CommandResult.error('BACKUP_EXPORT_FAILED', message: e.toString());
    }
  }
}

class VerifyBackupCommand extends WalletCommand<Map<String, String>> {
  @override
  String get name => 'backup.verify';
  @override
  String get description => 'Verify a backup file is readable';
  @override
  Map<String, CommandArg> get args => {
        'input': CommandArg(
            name: 'input',
            description: 'Backup file path to verify',
            required: true),
      };

  @override
  Future<CommandResult<Map<String, String>>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    return CommandResult.error('SERVICE_UNAVAILABLE',
        message: 'Backup verification requires decryption service');
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
    final input = params['input']?.toString() ?? '';

    if (ctx.importBackup == null) {
      return CommandResult.error('SERVICE_UNAVAILABLE',
          message: 'Backup service not configured in this runtime');
    }

    try {
      final result = await ctx.importBackup!(input);
      return CommandResult.ok(result);
    } catch (e) {
      return CommandResult.error('BACKUP_IMPORT_FAILED', message: e.toString());
    }
  }
}
