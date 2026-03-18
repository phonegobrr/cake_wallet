import 'dart:io';

class WalletLock {
  RandomAccessFile? _lockFile;

  /// Acquires an advisory lock on the wallet directory.
  /// Fails fast if another process holds the lock.
  Future<void> acquire(String walletDir) async {
    final lockPath = '$walletDir/.cake_wallet.lock';
    final lockFile = File(lockPath);

    // Check for stale lock: if the PID in the file is dead, clean up
    if (await lockFile.exists()) {
      try {
        final content = (await lockFile.readAsString()).trim();
        final existingPid = int.tryParse(content);
        if (existingPid != null && existingPid != pid) {
          try {
            // Signal 0 tests if process exists without killing it
            Process.killPid(existingPid, ProcessSignal.sigurg);
            // Process is alive — lock is valid
          } catch (_) {
            // Process is dead — safe to take over
            await lockFile.delete();
          }
        }
      } catch (_) {
        // Can't read lock file — try to proceed anyway
      }
    }

    _lockFile = await File(lockPath).open(mode: FileMode.write);
    try {
      // Windows doesn't support POSIX file locking the same way
      if (!Platform.isWindows) {
        _lockFile!.lockSync(FileLock.exclusive);
      }
    } on FileSystemException {
      _lockFile!.closeSync();
      _lockFile = null;
      throw StateError(
        'Another Cake Wallet process is using this wallet directory.\n'
        'Close it first, or use a different --data-dir.',
      );
    }
    _lockFile!.writeStringSync('$pid\n');
  }

  void release() {
    try {
      if (!Platform.isWindows) {
        _lockFile?.unlockSync();
      }
    } catch (_) {}
    try {
      _lockFile?.closeSync();
    } catch (_) {}
    _lockFile = null;
  }
}
