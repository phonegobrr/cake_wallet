import 'package:dart_lipgloss/dart_lipgloss.dart';
import 'package:cake_headless/commands/command_bus.dart';
import 'package:cake_console/tui/tui_theme.dart';
import 'package:cake_console/tui/terminal_driver.dart';
import 'package:cake_console/tui/screen.dart';

class ContactsScreen implements TuiScreen {
  final CommandBus _bus;

  ContactsScreen(this._bus);

  @override
  String get title => 'Contacts';

  @override
  String render(int width, int height, CommandBus bus) {
    final header = panelStyle().width(width - 4).render('Contacts');

    return joinVertical(posLeft, [
      header,
      '',
      mutedStyle().render('  Contact management coming soon'),
    ]);
  }

  @override
  void handleInput(TerminalEvent event) {}
}
