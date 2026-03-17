import 'package:dart_lipgloss/dart_lipgloss.dart';
import 'package:cake_headless/commands/command_bus.dart';
import 'package:cake_console/tui/tui_theme.dart';
import 'package:cake_console/tui/terminal_driver.dart';
import 'package:cake_console/tui/screen.dart';

class ExchangeScreen implements TuiScreen {
  final CommandBus _bus;

  ExchangeScreen(this._bus);

  @override
  String get title => 'Exchange';

  @override
  String render(int width, int height, CommandBus bus) {
    final header = panelStyle().width(width - 4).render('Exchange / Swap');

    return joinVertical(Position.left, [
      header,
      '',
      mutedStyle().render('  Exchange functionality coming soon'),
    ]);
  }

  @override
  void handleInput(TerminalEvent event) {}
}
