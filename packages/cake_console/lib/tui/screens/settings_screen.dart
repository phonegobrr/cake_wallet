import 'package:dart_lipgloss/dart_lipgloss.dart';
import 'package:cake_headless/commands/command_bus.dart';
import 'package:cake_console/tui/tui_theme.dart';
import 'package:cake_console/tui/terminal_driver.dart';
import 'package:cake_console/tui/screen.dart';

class SettingsScreen extends TuiScreen {
  final CommandBus _bus;
  Map<String, String> _settings = {};
  int _selectedIndex = 0;
  int _scrollOffset = 0;
  bool _isLoading = true;
  String? _statusMessage;
  bool _statusIsError = false;
  bool _editing = false;
  String _editValue = '';
  String? _editKey;

  SettingsScreen(this._bus);

  @override
  String get title => 'Settings';

  @override
  List<String> get supportedCommands => const ['settings.list', 'settings.get', 'settings.set'];

  @override
  bool get capturesInput => _editing;

  @override
  Future<void> init() async => refresh();

  @override
  Future<void> refresh() async {
    try {
      final result = await _bus.dispatch('settings.list', {});
      _settings = (result.success && result.data is Map)
          ? Map<String, String>.from(result.data as Map)
          : {};
    } catch (_) {
      _settings = {};
    }
    _isLoading = false;
  }

  @override
  String render(int width, int height, CommandBus bus) {
    if (_isLoading) return mutedStyle().render('  Loading...');

    final header = panelStyle().width(width - 4).render('Settings');

    if (_settings.isEmpty) {
      return joinVertical(posLeft, [
        header,
        '',
        mutedStyle().render('  No settings configured'),
      ]);
    }

    final entries = _settings.entries.toList();

    if (entries.isNotEmpty) {
      _selectedIndex = _selectedIndex.clamp(0, entries.length - 1);
    } else {
      _selectedIndex = 0;
    }

    // Viewport
    final availableHeight = (height - 8).clamp(1, entries.length);
    _scrollOffset = _scrollOffset.clamp(0, (entries.length - 1).clamp(0, entries.length));
    if (_selectedIndex < _scrollOffset) {
      _scrollOffset = _selectedIndex;
    }
    if (_selectedIndex >= _scrollOffset + availableHeight) {
      _scrollOffset = _selectedIndex - availableHeight + 1;
    }

    final visible =
        entries.asMap().entries.skip(_scrollOffset).take(availableHeight);

    final rows = visible.map((e) {
      final isSelected = e.key == _selectedIndex;
      final style = isSelected
          ? Style().bold(true).foreground(cakeText)
          : mutedStyle();
      final marker = isSelected ? '> ' : '  ';
      return style.render('$marker${e.value.key}: ${e.value.value}');
    }).toList();

    final parts = <String>[header, '', ...rows];

    if (_editing) {
      parts.add('');
      parts.add(Style().bold(true).foreground(cakeText)
          .render('  Edit "$_editKey":'));
      parts.add('  New value: $_editValue');
      parts.add('');
      parts.add(mutedStyle().render('  Enter: save  Esc: cancel'));
    } else {
      parts.add('');
      parts.add(mutedStyle().render('  Enter: edit  Up/Down: navigate'));
    }

    if (_statusMessage != null) {
      parts.add('');
      final style = _statusIsError ? errorStyle() : successStyle();
      parts.add(style.render('  $_statusMessage'));
    }

    return joinVertical(posLeft, parts);
  }

  @override
  void handleInput(TerminalEvent event) {
    if (_editing) {
      if (event.key == TerminalKey.escape) {
        _editing = false;
        _editValue = '';
        _editKey = null;
      } else if (event.key == TerminalKey.enter) {
        _saveEdit();
      } else if (event.key == TerminalKey.backspace && _editValue.isNotEmpty) {
        _editValue = _editValue.substring(0, _editValue.length - 1);
      } else if (event.key == TerminalKey.char && event.char != null) {
        _editValue += event.char!;
      }
      return;
    }

    if (_settings.isEmpty) return;
    final maxIndex = _settings.length - 1;
    if (event.key == TerminalKey.up) {
      _selectedIndex = (_selectedIndex - 1).clamp(0, maxIndex);
    } else if (event.key == TerminalKey.down) {
      _selectedIndex = (_selectedIndex + 1).clamp(0, maxIndex);
    } else if (event.key == TerminalKey.enter) {
      _startEdit();
    }
  }

  void _startEdit() {
    if (_settings.isEmpty) return;
    final entries = _settings.entries.toList();
    final entry = entries[_selectedIndex];
    _editKey = entry.key;
    _editValue = entry.value;
    _editing = true;
    _statusMessage = null;
  }

  void _saveEdit() {
    if (_editKey == null) return;
    _editing = false;
    _statusMessage = 'Saving...';
    _statusIsError = false;
    onStateChanged?.call();

    _bus.dispatch('settings.set', {
      'key': _editKey!,
      'value': _editValue,
    }).then((result) {
      if (result.success) {
        _statusMessage = 'Saved "$_editKey"';
        _statusIsError = false;
        _editKey = null;
        _editValue = '';
        refresh().then((_) => onStateChanged?.call());
      } else {
        _statusMessage = result.message ?? 'Failed to save';
        _statusIsError = true;
      }
      onStateChanged?.call();
    });
  }
}
