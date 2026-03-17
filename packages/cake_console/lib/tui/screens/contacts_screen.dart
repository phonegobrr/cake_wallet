import 'package:dart_lipgloss/dart_lipgloss.dart';
import 'package:cake_headless/commands/command_bus.dart';
import 'package:cake_headless/dto/address_entry.dart';
import 'package:cake_console/tui/tui_theme.dart';
import 'package:cake_console/tui/terminal_driver.dart';
import 'package:cake_console/tui/screen.dart';

class ContactsScreen extends TuiScreen {
  final CommandBus _bus;
  List<AddressEntry> _contacts = [];
  int _selectedIndex = 0;
  int _scrollOffset = 0;
  bool _isLoading = true;

  ContactsScreen(this._bus);

  @override
  String get title => 'Contacts';

  @override
  Future<void> init() async => refresh();

  @override
  Future<void> refresh() async {
    try {
      final result = await _bus.dispatch('contacts.list', {});
      _contacts = result.success
          ? (result.data as List<AddressEntry>?) ?? []
          : [];
    } catch (_) {
      _contacts = [];
    }
    _isLoading = false;
  }

  @override
  String render(int width, int height, CommandBus bus) {
    if (_isLoading) return mutedStyle().render('  Loading...');

    final header = panelStyle().width(width - 4).render('Contacts');

    if (_contacts.isEmpty) {
      return joinVertical(posLeft, [
        header,
        '',
        mutedStyle().render('  No contacts.'),
      ]);
    }

    // Viewport
    final availableHeight = (height - 6).clamp(1, _contacts.length);
    if (_selectedIndex < _scrollOffset) {
      _scrollOffset = _selectedIndex;
    }
    if (_selectedIndex >= _scrollOffset + availableHeight) {
      _scrollOffset = _selectedIndex - availableHeight + 1;
    }

    final visible = _contacts
        .asMap()
        .entries
        .skip(_scrollOffset)
        .take(availableHeight);

    final rows = visible.map((e) {
      final isSelected = e.key == _selectedIndex;
      final c = e.value;
      final style = isSelected
          ? Style().bold(true).foreground(cakeText)
          : mutedStyle();
      final marker = isSelected ? '> ' : '  ';
      final currency =
          c.currencyTitle != null ? ' (${c.currencyTitle})' : '';
      return style
          .render('$marker${c.label ?? "Unnamed"}$currency: ${c.address}');
    }).toList();

    return joinVertical(posLeft, [header, '', ...rows]);
  }

  @override
  void handleInput(TerminalEvent event) {
    if (_contacts.isEmpty) return;
    final maxIndex = _contacts.length - 1;
    if (event.key == TerminalKey.up) {
      _selectedIndex = (_selectedIndex - 1).clamp(0, maxIndex);
    } else if (event.key == TerminalKey.down) {
      _selectedIndex = (_selectedIndex + 1).clamp(0, maxIndex);
    }
  }
}
