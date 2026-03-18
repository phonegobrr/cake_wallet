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
  ctrlC,
  resize,
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

  bool get supportsAnsi => stdout.supportsAnsiEscapes;

  void enterAlternateScreen() {
    if (supportsAnsi) stdout.write('\x1b[?1049h');
  }

  void exitAlternateScreen() {
    if (supportsAnsi) stdout.write('\x1b[?1049l');
  }

  void hideCursor() {
    if (supportsAnsi) stdout.write('\x1b[?25l');
  }

  void showCursor() {
    if (supportsAnsi) stdout.write('\x1b[?25h');
  }

  void clearScreen() {
    if (supportsAnsi) stdout.write('\x1b[2J\x1b[H');
  }

  void moveTo(int row, int col) {
    if (supportsAnsi) stdout.write('\x1b[$row;${col}H');
  }

  Stream<TerminalEvent> get events {
    _controller ??= StreamController<TerminalEvent>.broadcast();
    _sub ??= stdin.listen((data) {
      // Parse all events from the data chunk (handles rapid input/paste)
      for (final event in _parseInput(data)) {
        _controller!.add(event);
      }
    });
    return _controller!.stream;
  }

  /// Parse raw terminal input bytes into a list of events.
  /// Handles multiple key sequences in a single data chunk (paste, rapid typing).
  List<TerminalEvent> _parseInput(List<int> data) {
    final events = <TerminalEvent>[];
    int i = 0;
    while (i < data.length) {
      // ESC sequences
      if (data[i] == 27) {
        // Check for ESC [ sequences
        if (i + 1 < data.length && data[i + 1] == 91) {
          // ESC [ n ~ sequences (delete, pgup, pgdn)
          if (i + 3 < data.length && data[i + 3] == 126) {
            switch (data[i + 2]) {
              case 51:
                events.add(TerminalEvent(TerminalKey.delete));
                break;
              case 53:
                events.add(TerminalEvent(TerminalKey.pageUp));
                break;
              case 54:
                events.add(TerminalEvent(TerminalKey.pageDown));
                break;
              default:
                events.add(TerminalEvent(TerminalKey.escape));
                i++;
                continue;
            }
            i += 4;
            continue;
          }
          // ESC [ X sequences (arrows, home, end, shift-tab)
          if (i + 2 < data.length) {
            switch (data[i + 2]) {
              case 65:
                events.add(TerminalEvent(TerminalKey.up));
                i += 3;
                continue;
              case 66:
                events.add(TerminalEvent(TerminalKey.down));
                i += 3;
                continue;
              case 67:
                events.add(TerminalEvent(TerminalKey.right));
                i += 3;
                continue;
              case 68:
                events.add(TerminalEvent(TerminalKey.left));
                i += 3;
                continue;
              case 72:
                events.add(TerminalEvent(TerminalKey.home));
                i += 3;
                continue;
              case 70:
                events.add(TerminalEvent(TerminalKey.end));
                i += 3;
                continue;
              case 90:
                events.add(TerminalEvent(TerminalKey.shiftTab));
                i += 3;
                continue;
            }
          }
        }
        // Bare ESC
        events.add(TerminalEvent(TerminalKey.escape));
        i++;
        continue;
      }
      // Single-byte control/ASCII characters
      switch (data[i]) {
        case 3:
          events.add(TerminalEvent(TerminalKey.ctrlC));
          break;
        case 10:
        case 13:
          events.add(TerminalEvent(TerminalKey.enter));
          break;
        case 127:
          events.add(TerminalEvent(TerminalKey.backspace));
          break;
        case 9:
          events.add(TerminalEvent(TerminalKey.tab));
          break;
        default:
          // Multi-byte UTF-8 codepoint
          if (data[i] >= 0xC0) {
            int byteCount = 1;
            if (data[i] >= 0xF0) {
              byteCount = 4;
            } else if (data[i] >= 0xE0) {
              byteCount = 3;
            } else {
              byteCount = 2;
            }
            final end = (i + byteCount).clamp(0, data.length);
            final char = String.fromCharCodes(data.sublist(i, end));
            events.add(TerminalEvent(TerminalKey.char, char));
            i = end;
            continue;
          }
          // Regular ASCII character
          events.add(
              TerminalEvent(TerminalKey.char, String.fromCharCode(data[i])));
          break;
      }
      i++;
    }
    return events;
  }

  void dispose() {
    try { _sub?.cancel(); } catch (_) {}
    try { _controller?.close(); } catch (_) {}
    _sub = null;
    _controller = null;
    // Terminal state restoration is handled by TuiApp._cleanup(),
    // not here — dispose() is only for resource cleanup.
  }
}
