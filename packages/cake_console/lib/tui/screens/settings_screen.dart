import 'package:dart_lipgloss/dart_lipgloss.dart';
import 'package:cake_headless/commands/command_bus.dart';
import 'package:cake_console/tui/tui_theme.dart';
import 'package:cake_console/tui/terminal_driver.dart';
import 'package:cake_console/tui/screen.dart';

class SettingsScreen implements TuiScreen {
  final CommandBus _bus;
  Map<String, String> _settings = {};
  int _selectedIndex = 0;

  SettingsScreen(this._bus) {
    _refresh();
  }

  @override
  String get title => 'Settings';

  Future<void> _refresh() async {
    final result = await _bus.dispatch('settings.list', {});
    if (result.success && result.data is Map) {
      _settings = Map<String, String>.from(result.data as Map);
    }
  }

  @override
  String render(int width, int height, CommandBus bus) {
    final header = panelStyle().width(width - 4).render('Settings');

    if (_settings.isEmpty) {
      return joinVertical(posLeft, [
        header,
        '',
        mutedStyle().render('  No settings configured'),
      ]);
    }

    final entries = _settings.entries.toList();
    final rows = entries.asMap().entries.map((e) {
      final isSelected = e.key == _selectedIndex;
      final style = isSelected
          ? Style().bold(true).foreground(cakeText)
          : mutedStyle();
      final marker = isSelected ? '> ' : '  ';
      return style.render('$marker${e.value.key}: ${e.value.value}');
    }).toList();

    return joinVertical(posLeft, [header, '', ...rows]);
  }

  @override
  void handleInput(TerminalEvent event) {
    final maxIndex = _settings.length - 1;
    if (event.key == TerminalKey.up && maxIndex >= 0) {
      _selectedIndex = (_selectedIndex - 1).clamp(0, maxIndex);
    } else if (event.key == TerminalKey.down && maxIndex >= 0) {
      _selectedIndex = (_selectedIndex + 1).clamp(0, maxIndex);
    }
  }
}
