import 'package:dart_lipgloss/dart_lipgloss.dart';
import 'package:cake_headless/commands/command_bus.dart';
import 'package:cake_console/tui/tui_theme.dart';
import 'package:cake_console/tui/terminal_driver.dart';
import 'package:cake_console/tui/screen.dart';

class BackupScreen extends TuiScreen {
  final CommandBus _bus;
  int _selectedAction = 0;
  String? _statusMessage;
  bool _statusIsError = false;
  bool _captureInput = false;
  String _pathInput = '';

  static const _actions = ['Export Backup', 'Import Backup', 'Verify Backup'];

  BackupScreen(this._bus);

  @override
  String get title => 'Backup';

  @override
  bool get capturesInput => _captureInput;

  @override
  String render(int width, int height, CommandBus bus) {
    final header = panelStyle().width(width - 4).render('Backup');

    final rows = _actions.asMap().entries.map((e) {
      final isSelected = e.key == _selectedAction;
      final style = isSelected
          ? Style().bold(true).foreground(cakeText)
          : mutedStyle();
      final marker = isSelected ? '> ' : '  ';
      return style.render('$marker${e.value}');
    }).toList();

    final parts = <String>[header, '', ...rows];

    if (_captureInput) {
      parts.add('');
      parts.add(Style().bold(true).foreground(cakeText).render('  Path: $_pathInput'));
      parts.add(mutedStyle().render('  Enter: confirm  Esc: cancel'));
    } else {
      parts.add('');
      parts.add(mutedStyle().render('  Enter: select  Up/Down: navigate'));
    }

    if (_statusMessage != null) {
      final style = _statusIsError ? errorStyle() : successStyle();
      parts.add('');
      parts.add(style.render('  $_statusMessage'));
    }

    return joinVertical(posLeft, parts);
  }

  @override
  void handleInput(TerminalEvent event) {
    if (_captureInput) {
      if (event.key == TerminalKey.escape) {
        _captureInput = false;
        _pathInput = '';
      } else if (event.key == TerminalKey.enter) {
        _executeAction();
      } else if (event.key == TerminalKey.backspace && _pathInput.isNotEmpty) {
        _pathInput = _pathInput.substring(0, _pathInput.length - 1);
      } else if (event.key == TerminalKey.char && event.char != null) {
        _pathInput += event.char!;
      }
      return;
    }

    if (event.key == TerminalKey.up) {
      _selectedAction = (_selectedAction - 1).clamp(0, _actions.length - 1);
    } else if (event.key == TerminalKey.down) {
      _selectedAction = (_selectedAction + 1).clamp(0, _actions.length - 1);
    } else if (event.key == TerminalKey.enter) {
      _captureInput = true;
      _pathInput = '';
    }
  }

  void _executeAction() {
    if (_pathInput.isEmpty) {
      _statusMessage = 'Path is required';
      _statusIsError = true;
      _captureInput = false;
      return;
    }
    _captureInput = false;

    final command = _selectedAction == 0
        ? 'backup.export'
        : _selectedAction == 1
            ? 'backup.import'
            : 'backup.verify';
    final paramKey = _selectedAction == 0 ? 'output' : 'input';

    _statusMessage = '${_actions[_selectedAction]}ing...';
    _statusIsError = false;
    onStateChanged?.call();

    _bus.dispatch(command, {paramKey: _pathInput}).then((result) {
      _statusMessage = result.success
          ? '${_actions[_selectedAction]} complete'
          : (result.message ?? 'Failed');
      _statusIsError = !result.success;
      onStateChanged?.call();
    });
  }
}
