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

  SettingsScreen(this._bus);

  @override
  String get title => 'Settings';

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

    // Clamp selection after list changes
    if (entries.isNotEmpty) {
      _selectedIndex = _selectedIndex.clamp(0, entries.length - 1);
    } else {
      _selectedIndex = 0;
    }

    // Viewport
    final availableHeight = (height - 6).clamp(1, entries.length);
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

    return joinVertical(posLeft, [header, '', ...rows]);
  }

  @override
  void handleInput(TerminalEvent event) {
    if (_settings.isEmpty) return;
    final maxIndex = _settings.length - 1;
    if (event.key == TerminalKey.up) {
      _selectedIndex = (_selectedIndex - 1).clamp(0, maxIndex);
    } else if (event.key == TerminalKey.down) {
      _selectedIndex = (_selectedIndex + 1).clamp(0, maxIndex);
    }
  }
}
