import 'dart:io';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:path/path.dart' as p;

String? _rootDirPath;

/// Call from CLI/TUI/server entry points BEFORE any wallet operations.
/// For Flutter, call initFlutterRootDir() from cw_core_flutter which uses
/// path_provider to determine the correct directory, then calls this.
void setRootDirOverride(String path) => _rootDirPath = path;

const String _tailsData = '/live/persistence/TailsData_unlocked/Persistent';

bool get isNonAmnesticTails {
  try {
    final os = File("/etc/os-release").readAsLinesSync();
    for (var line in os) {
      if (!line.startsWith("ID=")) continue;
      if (!line.contains("tails")) continue;
      return Directory(_tailsData).existsSync();
    }
  } catch (e) {
    return false;
  }
  return false;
}

bool showNotice = true;

void setRootDirFromEnv() =>
    _rootDirPath = Platform.environment['CAKE_WALLET_DIR'];

void copyDirectory(Directory source, Directory destination) {
  source.listSync(recursive: false).forEach((var entity) {
    if (entity is Directory) {
      var newDirectory = Directory(p.join(destination.absolute.path, p.basename(entity.path)));
      newDirectory.createSync(recursive: true);
      copyDirectory(entity.absolute, newDirectory);
    } else if (entity is File) {
      destination.createSync(recursive: true);
      entity.copySync(p.join(destination.path, p.basename(entity.path)));
    }
  });
}

Future<void> linuxSymlinkSharedPreferences() async {
  if (!Platform.isLinux) return;
  final dataHome = Platform.environment["XDG_DATA_HOME"] ?? p.join(Platform.environment["HOME"] ?? "", ".local", "share");
  var cakeNames = ['com.example.cake_wallet', 'cake_wallet'];
  for (String name in cakeNames) {
    final oldPath = p.join(dataHome, name);
    final newPath = p.join((await getAppDir()).path, "_local_share");
    final oldDir = Directory(oldPath);
    final oldLink = Link(oldPath);
    final newDir = Directory(newPath);
    if (oldDir.existsSync()) {
      if (oldLink.existsSync()) {
        printV("not creating, link exists");
      } else {
        if (newDir.existsSync()) {
          newDir.renameSync("${newPath}_${DateTime.now().millisecondsSinceEpoch~/1000}");
        }
        copyDirectory(oldDir, newDir);
        oldDir.deleteSync(recursive: true);
      }
    }
    if (!oldLink.existsSync()) {
      oldLink.create(newPath, recursive: true);
    }
    if (!newDir.existsSync()) {
      newDir.createSync(recursive: true);
    }
  }
}

String _defaultAppDirPath() {
  const String appName = 'cake_wallet';
  if (Platform.isLinux) {
    final home = Platform.environment['HOME'];
    if (home != null) return p.join(home, '.config', appName);
    return '.$appName';
  }
  if (Platform.isMacOS) {
    final home = Platform.environment['HOME'];
    if (home != null) return p.join(home, 'Library', 'Application Support', appName);
    return '.$appName';
  }
  if (Platform.isWindows) {
    final appdata = Platform.environment['APPDATA'];
    if (appdata != null) return p.join(appdata, appName);
    return '.$appName';
  }
  return '.$appName';
}

Future<Directory> getAppDir() async {
  const String appName = 'cake_wallet';
  Directory dir;

  if (_rootDirPath != null && _rootDirPath!.isNotEmpty) {
    dir = Directory.fromUri(Uri.file(_rootDirPath!));
    dir.create(recursive: true);
  } else if (Platform.isLinux) {
    // Pure-Dart Linux path resolution (same logic as before, without path_provider)
    var linuxAppPath = [
      p.join('/home', Platform.environment['USER'] ?? "null", appName),
      if (Platform.environment['HOME'] != null) p.join(Platform.environment['HOME']!, ".$appName"),
      if (Platform.environment['HOME'] != null) p.join(Platform.environment['HOME']!, '.config', appName),
      if (isNonAmnesticTails) p.join(_tailsData, ".$appName"),
    ];

    String preferredPath = linuxAppPath.last;

    preferredLoop:
    for (String notSoPreferredPath in linuxAppPath) {
      if (notSoPreferredPath == linuxAppPath.last) continue;
      bool useThisOne = Directory(notSoPreferredPath).existsSync();
      if (useThisOne) {
        if (showNotice) {
          showNotice = false;
          printV("Not using $preferredPath because $notSoPreferredPath exists, falling back for backwards compatibility");
          printV("Can't see your wallet? Check\n - ${linuxAppPath.join("\n - ")}\n and move directory that to $preferredPath");
          printV("Or use CAKE_WALLET_DIR=/path/to/app/ ${Platform.executable}");
        }
        preferredPath = notSoPreferredPath;
        break preferredLoop;
      }
    }

    dir = Directory.fromUri(Uri.file(preferredPath));
    await dir.create(recursive: true);
  } else {
    // macOS, Windows, and other platforms: use pure-Dart path
    dir = Directory(_defaultAppDirPath());
    await dir.create(recursive: true);
  }

  return dir;
}
