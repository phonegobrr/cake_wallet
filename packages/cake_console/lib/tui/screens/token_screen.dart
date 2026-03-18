import 'package:dart_lipgloss/dart_lipgloss.dart';
import 'package:cake_headless/commands/command_bus.dart';
import 'package:cake_console/tui/tui_theme.dart';
import 'package:cake_console/tui/terminal_driver.dart';
import 'package:cake_console/tui/screen.dart';

class TokenScreen extends TuiScreen {
  final CommandBus _bus;
  List<Map<String, dynamic>> _tokens = [];
  int _selectedIndex = 0;
  int _scrollOffset = 0;
  bool _isLoading = true;
  String? _statusMessage;
  bool _statusIsError = false;
  bool _captureInput = false;
  String _addressInput = '';

  TokenScreen(this._bus);

  @override
  String get title => 'Tokens';

  @override
  bool get capturesInput => _captureInput;

  @override
  Future<void> init() async => refresh();

  @override
  Future<void> refresh() async {
    try {
      final result = await _bus.dispatch('tokens.list', {});
      if (result.success && result.data is List) {
        _tokens = (result.data as List).map((e) {
          if (e is Map<String, dynamic>) return e;
          try { return (e as dynamic).toJson() as Map<String, dynamic>; }
          catch (_) { return <String, dynamic>{'value': e.toString()}; }
        }).toList();
      } else {
        _tokens = [];
      }
    } catch (_) {
      _tokens = [];
    }
    if (_tokens.isNotEmpty) {
      _selectedIndex = _selectedIndex.clamp(0, _tokens.length - 1);
    } else {
      _selectedIndex = 0;
    }
    _isLoading = false;
  }

  @override
  String render(int width, int height, CommandBus bus) {
    if (_isLoading) return mutedStyle().render('  Loading...');

    final header = panelStyle().width(width - 4).render('Token Management');

    final parts = <String>[header, ''];

    if (_tokens.isEmpty) {
      parts.add(mutedStyle().render('  No tokens configured.'));
    } else {
      final availableHeight = (height - 8).clamp(1, _tokens.length);
      if (_selectedIndex < _scrollOffset) _scrollOffset = _selectedIndex;
      if (_selectedIndex >= _scrollOffset + availableHeight) {
        _scrollOffset = _selectedIndex - availableHeight + 1;
      }

      final visible = _tokens.asMap().entries.skip(_scrollOffset).take(availableHeight);
      for (final e in visible) {
        final isSelected = e.key == _selectedIndex;
        final t = e.value;
        final style = isSelected
            ? Style().bold(true).foreground(cakeText) : mutedStyle();
        final marker = isSelected ? '> ' : '  ';
        parts.add(style.render('$marker${t['name'] ?? t['address'] ?? 'Unknown'}'));
      }
    }

    if (_captureInput) {
      parts.add('');
      parts.add(Style().bold(true).foreground(cakeText)
          .render('  Token address: $_addressInput'));
      parts.add(mutedStyle().render('  Enter: add  Esc: cancel'));
    } else {
      parts.add('');
      parts.add(mutedStyle().render('  a: add token  d: remove  Up/Down: navigate'));
    }

    if (_statusMessage != null) {
      final style = _statusIsError ? errorStyle() : successStyle();
      parts.add(style.render('  $_statusMessage'));
    }

    return joinVertical(posLeft, parts);
  }

  @override
  void handleInput(TerminalEvent event) {
    if (_captureInput) {
      if (event.key == TerminalKey.escape) {
        _captureInput = false;
        _addressInput = '';
      } else if (event.key == TerminalKey.enter) {
        _addToken();
      } else if (event.key == TerminalKey.backspace && _addressInput.isNotEmpty) {
        _addressInput = _addressInput.substring(0, _addressInput.length - 1);
      } else if (event.key == TerminalKey.char && event.char != null) {
        _addressInput += event.char!;
      }
      return;
    }

    if (_tokens.isNotEmpty) {
      final maxIndex = _tokens.length - 1;
      if (event.key == TerminalKey.up) {
        _selectedIndex = (_selectedIndex - 1).clamp(0, maxIndex);
      } else if (event.key == TerminalKey.down) {
        _selectedIndex = (_selectedIndex + 1).clamp(0, maxIndex);
      }
    }

    if (event.key == TerminalKey.char && event.char == 'a') {
      _captureInput = true;
      _addressInput = '';
    } else if (event.key == TerminalKey.char && event.char == 'd') {
      _removeToken();
    }
  }

  void _addToken() {
    if (_addressInput.isEmpty) {
      _statusMessage = 'Token address required';
      _statusIsError = true;
      _captureInput = false;
      return;
    }
    _captureInput = false;
    _bus.dispatch('tokens.add', {'address': _addressInput}).then((result) {
      _statusMessage = result.success ? 'Token added' : (result.message ?? 'Failed');
      _statusIsError = !result.success;
      _addressInput = '';
      refresh().then((_) => onStateChanged?.call());
    });
  }

  void _removeToken() {
    if (_tokens.isEmpty) return;
    final addr = _tokens[_selectedIndex]['address']?.toString() ?? '';
    if (addr.isEmpty) return;
    _bus.dispatch('tokens.remove', {'address': addr}).then((result) {
      _statusMessage = result.success ? 'Token removed' : (result.message ?? 'Failed');
      _statusIsError = !result.success;
      refresh().then((_) => onStateChanged?.call());
    });
  }
}
