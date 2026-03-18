import 'dart:convert';

import 'package:dart_lipgloss/dart_lipgloss.dart';
import 'package:cake_headless/commands/command.dart';
import 'package:cake_headless/commands/command_bus.dart';
import 'package:cake_console/tui/tui_theme.dart';
import 'package:cake_console/tui/terminal_driver.dart';
import 'package:cake_console/tui/screen.dart';

enum _PaletteState { browsing, enteringArgs, showingResult }

/// Registry-driven command palette that provides TUI access to ALL registered
/// commands via fuzzy search, auto-rendered input forms, and inline results.
class CommandPaletteScreen extends TuiScreen {
  final CommandBus _bus;
  String _filter = '';
  int _selectedIndex = 0;
  int _scrollOffset = 0;
  _PaletteState _state = _PaletteState.browsing;

  // Arg entry state
  WalletCommand? _activeCommand;
  List<String> _argKeys = [];
  Map<String, String> _argValues = {};
  int _activeArgIndex = 0;
  String _currentArgInput = '';

  // Result display
  String? _resultText;
  bool _resultIsError = false;

  CommandPaletteScreen(this._bus);

  @override
  String get title => 'Commands';

  @override
  bool get capturesInput => true;

  List<WalletCommand> get _filteredCommands {
    if (_filter.isEmpty) return _bus.commands;
    final lower = _filter.toLowerCase();
    return _bus.commands
        .where((c) =>
            c.name.toLowerCase().contains(lower) ||
            c.description.toLowerCase().contains(lower))
        .toList();
  }

  @override
  String render(int width, int height, CommandBus bus) {
    final header = panelStyle().width(width - 4).render('Command Palette');

    switch (_state) {
      case _PaletteState.browsing:
        return _renderBrowsing(header, width, height);
      case _PaletteState.enteringArgs:
        return _renderArgEntry(header, width, height);
      case _PaletteState.showingResult:
        return _renderResult(header, width, height);
    }
  }

  String _renderBrowsing(String header, int width, int height) {
    final searchLine = Style().bold(true).foreground(cakeText)
        .render('  > $_filter');
    final commands = _filteredCommands;

    if (commands.isNotEmpty) {
      _selectedIndex = _selectedIndex.clamp(0, commands.length - 1);
    } else {
      _selectedIndex = 0;
    }

    final availableHeight = (height - 8).clamp(1, commands.isEmpty ? 1 : commands.length);
    if (_selectedIndex < _scrollOffset) _scrollOffset = _selectedIndex;
    if (_selectedIndex >= _scrollOffset + availableHeight) {
      _scrollOffset = _selectedIndex - availableHeight + 1;
    }

    final visible = commands.isEmpty
        ? <MapEntry<int, WalletCommand>>[]
        : commands.asMap().entries.skip(_scrollOffset).take(availableHeight).toList();

    final rows = visible.map((e) {
      final isSelected = e.key == _selectedIndex;
      final cmd = e.value;
      final marker = isSelected ? '> ' : '  ';
      final statusTag = cmd.status == CommandStatus.unsupported
          ? ' [unsupported]'
          : cmd.status == CommandStatus.stub
              ? ' [stub]'
              : '';
      final style = isSelected
          ? Style().bold(true).foreground(cakeText)
          : cmd.status == CommandStatus.unsupported
              ? Style().foreground(cakeMuted)
              : mutedStyle();
      return style.render('$marker${cmd.name}$statusTag — ${cmd.description}');
    }).toList();

    if (rows.isEmpty) {
      rows.add(mutedStyle().render('  No matching commands'));
    }

    final hints = mutedStyle()
        .render('  Type to filter  Enter: select  Esc: clear  Backspace: delete');

    return joinVertical(posLeft, [header, '', searchLine, '', ...rows, '', hints]);
  }

  String _renderArgEntry(String header, int width, int height) {
    final cmdName = Style().bold(true).foreground(cakeText)
        .render('  Command: ${_activeCommand!.name}');

    final argRows = <String>[];
    for (int i = 0; i < _argKeys.length; i++) {
      final key = _argKeys[i];
      final argDef = _activeCommand!.args[key]!;
      final isCurrent = i == _activeArgIndex;
      final value = i == _activeArgIndex ? _currentArgInput : (_argValues[key] ?? '');
      final reqMark = argDef.required ? '*' : '';
      final style = isCurrent
          ? Style().bold(true).foreground(cakeText)
          : mutedStyle();
      final marker = isCurrent ? '> ' : '  ';
      argRows.add(style.render('$marker$key$reqMark: $value'));
    }

    final hints = mutedStyle()
        .render('  Up/Down: switch arg  Enter: execute  Esc: back');

    return joinVertical(posLeft, [header, '', cmdName, '', ...argRows, '', hints]);
  }

  String _renderResult(String header, int width, int height) {
    final style = _resultIsError ? errorStyle() : successStyle();
    final resultLabel = _resultIsError ? 'Error' : 'Result';
    final parts = <String>[
      header,
      '',
      style.render('  $resultLabel:'),
      '',
    ];

    // Show result text, line by line
    if (_resultText != null) {
      for (final line in _resultText!.split('\n').take(height - 8)) {
        parts.add(mutedStyle().render('  $line'));
      }
    }

    parts.add('');
    parts.add(mutedStyle().render('  Esc: back to palette'));

    return joinVertical(posLeft, parts);
  }

  @override
  void handleInput(TerminalEvent event) {
    switch (_state) {
      case _PaletteState.browsing:
        _handleBrowsing(event);
        break;
      case _PaletteState.enteringArgs:
        _handleArgEntry(event);
        break;
      case _PaletteState.showingResult:
        if (event.key == TerminalKey.escape) {
          _state = _PaletteState.browsing;
          _resultText = null;
        }
        break;
    }
  }

  void _handleBrowsing(TerminalEvent event) {
    if (event.key == TerminalKey.escape) {
      _filter = '';
      _selectedIndex = 0;
      _scrollOffset = 0;
    } else if (event.key == TerminalKey.up) {
      if (_selectedIndex > 0) _selectedIndex--;
    } else if (event.key == TerminalKey.down) {
      final max = _filteredCommands.length - 1;
      if (_selectedIndex < max) _selectedIndex++;
    } else if (event.key == TerminalKey.enter) {
      _selectCommand();
    } else if (event.key == TerminalKey.backspace) {
      if (_filter.isNotEmpty) {
        _filter = _filter.substring(0, _filter.length - 1);
        _selectedIndex = 0;
        _scrollOffset = 0;
      }
    } else if (event.key == TerminalKey.char && event.char != null) {
      _filter += event.char!;
      _selectedIndex = 0;
      _scrollOffset = 0;
    }
  }

  void _selectCommand() {
    final commands = _filteredCommands;
    if (commands.isEmpty) return;
    final cmd = commands[_selectedIndex];

    _activeCommand = cmd;
    _argKeys = cmd.args.keys.toList();
    _argValues = {};
    _activeArgIndex = 0;
    _currentArgInput = '';

    if (_argKeys.isEmpty) {
      // No args needed — execute immediately
      _executeCommand();
    } else {
      _state = _PaletteState.enteringArgs;
    }
  }

  void _handleArgEntry(TerminalEvent event) {
    if (event.key == TerminalKey.escape) {
      _state = _PaletteState.browsing;
      _activeCommand = null;
    } else if (event.key == TerminalKey.up) {
      _argValues[_argKeys[_activeArgIndex]] = _currentArgInput;
      _activeArgIndex = (_activeArgIndex - 1).clamp(0, _argKeys.length - 1);
      _currentArgInput = _argValues[_argKeys[_activeArgIndex]] ?? '';
    } else if (event.key == TerminalKey.down) {
      _argValues[_argKeys[_activeArgIndex]] = _currentArgInput;
      _activeArgIndex = (_activeArgIndex + 1).clamp(0, _argKeys.length - 1);
      _currentArgInput = _argValues[_argKeys[_activeArgIndex]] ?? '';
    } else if (event.key == TerminalKey.enter) {
      _argValues[_argKeys[_activeArgIndex]] = _currentArgInput;
      _executeCommand();
    } else if (event.key == TerminalKey.backspace) {
      if (_currentArgInput.isNotEmpty) {
        _currentArgInput =
            _currentArgInput.substring(0, _currentArgInput.length - 1);
      }
    } else if (event.key == TerminalKey.char && event.char != null) {
      _currentArgInput += event.char!;
    }
  }

  void _executeCommand() {
    final cmd = _activeCommand!;
    final params = <String, dynamic>{};
    for (final key in _argKeys) {
      final val = _argValues[key] ?? '';
      if (val.isNotEmpty) params[key] = val;
    }

    _bus.dispatch(cmd.name, params).then((result) {
      _resultIsError = !result.success;
      try {
        final json = result.toJson((d) {
          if (d is Map) return d;
          if (d is List) return {'items': d};
          try { return (d as dynamic).toJson(); }
          catch (_) { return {'value': d.toString()}; }
        });
        _resultText = const JsonEncoder.withIndent('  ').convert(json);
      } catch (_) {
        _resultText = result.message ?? result.errorCode ?? 'No output';
      }
      _state = _PaletteState.showingResult;
      onStateChanged?.call();
    });
  }
}
