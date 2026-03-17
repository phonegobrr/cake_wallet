import 'package:cake_headless/i18n/app_strings.dart';

class DefaultAppStrings implements AppStrings {
  @override
  String get insufficientFunds => 'Insufficient funds';
  @override
  String get transactionFailed => 'Transaction failed';
  @override
  String get walletNotFound => 'Wallet not found';
  @override
  String get invalidAddress => 'Invalid address';
  @override
  String get invalidAmount => 'Invalid amount';
  @override
  String get syncingWallet => 'Syncing wallet...';
  @override
  String get transactionSent => 'Transaction sent';
  @override
  String get noWalletOpen => 'No wallet is open';
  @override
  String get walletCreated => 'Wallet created';
  @override
  String get walletOpened => 'Wallet opened';
  @override
  String get walletClosed => 'Wallet closed';
  @override
  String get backupCreated => 'Backup created';
  @override
  String get backupRestored => 'Backup restored';
  @override
  String get nodeConnected => 'Connected to node';
  @override
  String get nodeDisconnected => 'Disconnected from node';
  @override
  String get contactAdded => 'Contact added';
  @override
  String get contactDeleted => 'Contact deleted';
  @override
  String get settingUpdated => 'Setting updated';
}
