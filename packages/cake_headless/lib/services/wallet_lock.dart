import 'dart:io';

class WalletLock {
  RandomAccessFile? _lockFile;

  /// Acquires an advisory lock on the wallet directory.
  /// Fails fast if another process holds the lock.
  Future<void> acquire(String walletDir) async {
    final lockPath = '$walletDir/.cake_wallet.lock';
    _lockFile = await File(lockPath).open(mode: FileMode.write);
    try {
      _lockFile!.lockSync(FileLock.exclusive);
    } on FileSystemException {
      _lockFile!.closeSync();
      _lockFile = null;
      throw StateError(
        'Another Cake Wallet process is using this wallet directory.\n'
        'Close it first, or use a different --data-dir.',
      );
    }
    _lockFile!.writeStringSync('${pid}\n');
  }

  void release() {
    try {
      _lockFile?.unlockSync();
    } catch (_) {}
    try {
      _lockFile?.closeSync();
    } catch (_) {}
    _lockFile = null;
  }
}
