import 'dart:async';
import 'dart:io';

import 'package:dart_lipgloss/dart_lipgloss.dart';
import 'package:cake_headless/events/event_bus.dart';
import 'package:cake_headless/commands/command_bus.dart';
import 'package:cake_console/tui/terminal_driver.dart';
import 'package:cake_console/tui/tui_theme.dart';
import 'package:cake_console/tui/screen.dart';
import 'package:cake_console/tui/screens/dashboard_screen.dart';
import 'package:cake_console/tui/screens/wallet_list_screen.dart';
import 'package:cake_console/tui/screens/send_screen.dart';
import 'package:cake_console/tui/screens/receive_screen.dart';
import 'package:cake_console/tui/screens/history_screen.dart';
import 'package:cake_console/tui/screens/exchange_screen.dart';
import 'package:cake_console/tui/screens/settings_screen.dart';
import 'package:cake_console/tui/screens/contacts_screen.dart';

class TuiApp {
  final CommandBus commandBus;
  final WalletEventBus eventBus;
  final TerminalDriver terminal;

  late final List<TuiScreen> screens;
  int _activeTab = 0;
  StreamSubscription? _eventSub;

  TuiApp({
    required this.commandBus,
    required this.eventBus,
  }) : terminal = TerminalDriver() {
    screens = [
      DashboardScreen(commandBus),
      WalletListScreen(commandBus),
      SendScreen(commandBus),
      ReceiveScreen(commandBus),
      HistoryScreen(commandBus),
      ExchangeScreen(commandBus),
      SettingsScreen(commandBus),
      ContactsScreen(commandBus),
    ];
  }

  Future<void> run() async {
    terminal.enableRawMode();
    terminal.enterAlternateScreen();
    terminal.hideCursor();

    _eventSub = eventBus.events.listen((_) => _render());

    _render();

    await for (final event in terminal.events) {
      if (event.key == TerminalKey.char && event.char == 'q') {
        break;
      }
      if (event.key == TerminalKey.tab) {
        _activeTab = (_activeTab + 1) % screens.length;
      }
      if (event.key == TerminalKey.shiftTab) {
        _activeTab = (_activeTab - 1 + screens.length) % screens.length;
      }
      screens[_activeTab].handleInput(event);
      _render();
    }

    _cleanup();
  }

  void _render() {
    terminal.clearScreen();
    final w = terminal.width;
    final h = terminal.height;

    // Header
    final header = headerStyle().width(w).render(
        ' Cake Wallet TUI');

    // Tab bar
    final tabs = screens.asMap().entries.map((e) {
      final isActive = e.key == _activeTab;
      final style = isActive
          ? Style().bold(true).foreground(cakeText).background(cakePrimary).paddingLeft(1).paddingRight(1)
          : Style().foreground(cakeMuted).paddingLeft(1).paddingRight(1);
      final marker = isActive ? '> ' : '  ';
      return style.render('$marker${e.value.title}');
    }).toList();
    final tabBar = joinHorizontal(Position.top, tabs);

    // Screen content
    final content = screens[_activeTab].render(w, h - 4, commandBus);

    // Status bar
    final statusBar = mutedStyle().width(w).render(
        ' Tab: switch  q: quit  Up/Down: navigate  Enter: select  Esc: back');

    final output = joinVertical(Position.left, [header, tabBar, content, statusBar]);
    stdout.write(output);
  }

  void _cleanup() {
    _eventSub?.cancel();
    terminal.exitAlternateScreen();
    terminal.showCursor();
    terminal.dispose();
  }
}
