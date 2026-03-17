import 'package:cake_headless/commands/command_bus.dart';
import 'package:cake_console/tui/terminal_driver.dart';

abstract class TuiScreen {
  String get title;
  String render(int width, int height, CommandBus bus);
  void handleInput(TerminalEvent event);
}
