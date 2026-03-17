import 'package:cake_headless/commands/command_bus.dart';
import 'package:cake_console/tui/terminal_driver.dart';

abstract class TuiScreen {
  String get title;
  String render(int width, int height, CommandBus bus);
  void handleInput(TerminalEvent event);

  /// Whether this screen captures text input (prevents global hotkeys like 'q').
  bool get capturesInput => false;

  /// Called once when the screen is first initialized.
  Future<void> init() async {}

  /// Called when refreshing data (on tab switch, periodic, etc).
  Future<void> refresh() async {}

  /// Called when this screen becomes the active tab.
  void onEnter() {}

  /// Called when leaving this screen for another tab.
  void onLeave() {}

  /// Callback to trigger re-render from async operations.
  void Function()? onStateChanged;
}
