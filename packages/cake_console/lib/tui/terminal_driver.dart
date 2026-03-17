import 'dart:async';
import 'dart:io';

enum TerminalKey {
  up,
  down,
  left,
  right,
  enter,
  escape,
  backspace,
  tab,
  shiftTab,
  home,
  end,
  pageUp,
  pageDown,
  delete,
  char,
}

class TerminalEvent {
  final TerminalKey key;
  final String? char;

  TerminalEvent(this.key, [this.char]);

  @override
  String toString() => 'TerminalEvent($key${char != null ? ', "$char"' : ''})';
}

class TerminalDriver {
  StreamSubscription? _sub;
  StreamController<TerminalEvent>? _controller;

  int get width => stdout.hasTerminal ? stdout.terminalColumns : 80;
  int get height => stdout.hasTerminal ? stdout.terminalLines : 24;

  void enableRawMode() {
    if (stdin.hasTerminal) {
      stdin.echoMode = false;
      stdin.lineMode = false;
    }
  }

  void disableRawMode() {
    if (stdin.hasTerminal) {
      stdin.echoMode = true;
      stdin.lineMode = true;
    }
  }

  void enterAlternateScreen() => stdout.write('\x1b[?1049h');
  void exitAlternateScreen() => stdout.write('\x1b[?1049l');
  void hideCursor() => stdout.write('\x1b[?25l');
  void showCursor() => stdout.write('\x1b[?25h');
  void clearScreen() => stdout.write('\x1b[2J\x1b[H');
  void moveTo(int row, int col) => stdout.write('\x1b[$row;${col}H');

  Stream<TerminalEvent> get events {
    _controller ??= StreamController<TerminalEvent>.broadcast();
    _sub ??= stdin.listen((data) {
      _controller!.add(_parseInput(data));
    });
    return _controller!.stream;
  }

  TerminalEvent _parseInput(List<int> data) {
    if (data.length == 1) {
      switch (data[0]) {
        case 10:
        case 13:
          return TerminalEvent(TerminalKey.enter);
        case 27:
          return TerminalEvent(TerminalKey.escape);
        case 127:
          return TerminalEvent(TerminalKey.backspace);
        case 9:
          return TerminalEvent(TerminalKey.tab);
        default:
          return TerminalEvent(TerminalKey.char, String.fromCharCode(data[0]));
      }
    }
    // ESC [ sequences
    if (data.length == 3 && data[0] == 27 && data[1] == 91) {
      switch (data[2]) {
        case 65:
          return TerminalEvent(TerminalKey.up);
        case 66:
          return TerminalEvent(TerminalKey.down);
        case 67:
          return TerminalEvent(TerminalKey.right);
        case 68:
          return TerminalEvent(TerminalKey.left);
        case 72:
          return TerminalEvent(TerminalKey.home);
        case 70:
          return TerminalEvent(TerminalKey.end);
        case 90:
          return TerminalEvent(TerminalKey.shiftTab);
      }
    }
    // ESC [ n ~ sequences
    if (data.length == 4 && data[0] == 27 && data[1] == 91 && data[3] == 126) {
      switch (data[2]) {
        case 51:
          return TerminalEvent(TerminalKey.delete);
        case 53:
          return TerminalEvent(TerminalKey.pageUp);
        case 54:
          return TerminalEvent(TerminalKey.pageDown);
      }
    }
    return TerminalEvent(TerminalKey.char, String.fromCharCodes(data));
  }

  void dispose() {
    _sub?.cancel();
    _controller?.close();
    disableRawMode();
    showCursor();
  }
}
