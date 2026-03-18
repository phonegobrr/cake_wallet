import 'package:dart_lipgloss/dart_lipgloss.dart';
import 'package:cake_headless/commands/command_bus.dart';
import 'package:cake_console/tui/tui_theme.dart';
import 'package:cake_console/tui/terminal_driver.dart';
import 'package:cake_console/tui/screen.dart';

class TorScreen extends TuiScreen {
  final CommandBus _bus;
  int _selectedAction = 0;
  String? _statusMessage;
  bool _statusIsError = false;
  Map<String, String>? _torStatus;
  bool _isLoading = true;

  static const _actions = ['Check Status', 'Enable Tor', 'Disable Tor'];

  TorScreen(this._bus);

  @override
  String get title => 'Tor';

  @override
  List<String> get supportedCommands =>
      const ['tor.status', 'tor.enable', 'tor.disable'];

  @override
  Future<void> init() async => refresh();

  @override
  Future<void> refresh() async {
    try {
      final result = await _bus.dispatch('tor.status', {});
      if (result.success && result.data is Map) {
        _torStatus = (result.data as Map).map(
            (k, v) => MapEntry(k.toString(), v.toString()));
      }
    } catch (_) {}
    _isLoading = false;
  }

  @override
  String render(int width, int height, CommandBus bus) {
    if (_isLoading) return mutedStyle().render('  Loading...');

    final header = panelStyle().width(width - 4).render('Tor');

    final parts = <String>[header, ''];

    // Show current status
    if (_torStatus != null && _torStatus!.isNotEmpty) {
      parts.add(Style().bold(true).foreground(cakeText).render('  Status:'));
      for (final entry in _torStatus!.entries) {
        parts.add(mutedStyle().render('  ${entry.key}: ${entry.value}'));
      }
      parts.add('');
    }

    // Action menu
    final rows = _actions.asMap().entries.map((e) {
      final isSelected = e.key == _selectedAction;
      final style = isSelected
          ? Style().bold(true).foreground(cakeText)
          : mutedStyle();
      final marker = isSelected ? '> ' : '  ';
      return style.render('$marker${e.value}');
    }).toList();

    parts.addAll(rows);
    parts.add('');
    parts.add(mutedStyle().render('  Enter: execute  Up/Down: navigate'));

    if (_statusMessage != null) {
      final style = _statusIsError ? errorStyle() : successStyle();
      parts.add('');
      parts.add(style.render('  $_statusMessage'));
    }

    return joinVertical(posLeft, parts);
  }

  @override
  void handleInput(TerminalEvent event) {
    if (event.key == TerminalKey.up) {
      _selectedAction = (_selectedAction - 1).clamp(0, _actions.length - 1);
    } else if (event.key == TerminalKey.down) {
      _selectedAction = (_selectedAction + 1).clamp(0, _actions.length - 1);
    } else if (event.key == TerminalKey.enter) {
      _executeAction();
    }
  }

  void _executeAction() {
    final command = _selectedAction == 0
        ? 'tor.status'
        : _selectedAction == 1
            ? 'tor.enable'
            : 'tor.disable';

    _statusMessage = '${_actions[_selectedAction]}...';
    _statusIsError = false;
    onStateChanged?.call();

    _bus.dispatch(command, {}).then((result) {
      if (result.success) {
        if (result.data is Map) {
          _torStatus = (result.data as Map).map(
              (k, v) => MapEntry(k.toString(), v.toString()));
        }
        _statusMessage = '${_actions[_selectedAction]} complete';
        _statusIsError = false;
      } else {
        _statusMessage = result.message ?? 'Failed';
        _statusIsError = true;
      }
      onStateChanged?.call();
    });
  }
}
