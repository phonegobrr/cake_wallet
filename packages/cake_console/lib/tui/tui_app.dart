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
  Timer? _refreshTimer;
  bool _rendering = false;
  bool _cleaned = false;

  // Hotkey-to-tab mapping
  static const _hotkeyMap = {
    's': 2, // Send
    'r': 3, // Receive
    'w': 1, // Wallets
    'e': 5, // Exchange
    'h': 4, // History
    'c': 7, // Contacts
  };

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

    // Wire render callbacks for async state changes
    for (final screen in screens) {
      screen.onStateChanged = () => _render();
    }
  }

  Future<void> run() async {
    // Signal handlers for clean shutdown
    final sigintSub = ProcessSignal.sigint.watch().listen((_) {
      _cleanup();
      exit(0);
    });
    StreamSubscription? sigtermSub;
    if (!Platform.isWindows) {
      sigtermSub = ProcessSignal.sigterm.watch().listen((_) {
        _cleanup();
        exit(0);
      });
      // Handle terminal resize
      ProcessSignal.sigwinch.watch().listen((_) => _render());
    }

    terminal.enableRawMode();
    terminal.enterAlternateScreen();
    terminal.hideCursor();

    try {
      _eventSub = eventBus.events.listen((_) => _render());

      // Initialize and render first screen
      await screens[_activeTab].init();
      await screens[_activeTab].refresh();
      screens[_activeTab].onEnter();
      _render();

      // Periodic refresh for sync status, balance, etc.
      _refreshTimer = Timer.periodic(Duration(seconds: 5), (_) async {
        await screens[_activeTab].refresh();
        _render();
      });

      await for (final event in terminal.events) {
        // Ctrl+C always quits
        if (event.key == TerminalKey.ctrlC) {
          break;
        }

        // 'q' quits only when the active screen doesn't capture input
        if (event.key == TerminalKey.char &&
            event.char == 'q' &&
            !screens[_activeTab].capturesInput) {
          break;
        }

        // Hotkey shortcuts only when not capturing input
        if (event.key == TerminalKey.char &&
            !screens[_activeTab].capturesInput &&
            event.char != null) {
          final tabIdx = _hotkeyMap[event.char!.toLowerCase()];
          if (tabIdx != null) {
            await _switchTab(tabIdx);
            _render();
            continue;
          }
        }

        // Tab/Shift-Tab only when active screen doesn't capture input
        if (event.key == TerminalKey.tab &&
            !screens[_activeTab].capturesInput) {
          await _switchTab((_activeTab + 1) % screens.length);
          _render();
          continue;
        }
        if (event.key == TerminalKey.shiftTab &&
            !screens[_activeTab].capturesInput) {
          await _switchTab((_activeTab - 1 + screens.length) % screens.length);
          _render();
          continue;
        }

        screens[_activeTab].handleInput(event);
        _render();
      }
    } catch (e) {
      stderr.writeln('TUI error: $e');
    } finally {
      sigintSub.cancel();
      sigtermSub?.cancel();
      _cleanup();
    }
  }

  Future<void> _switchTab(int newTab) async {
    if (newTab == _activeTab) return;
    screens[_activeTab].onLeave();
    _activeTab = newTab;
    screens[_activeTab].onEnter();
    await screens[_activeTab].refresh();
  }

  void _render() {
    if (_rendering) return;
    _rendering = true;
    try {
      final w = terminal.width;
      final h = terminal.height;

      // Header
      final header = headerStyle().width(w).render(' Cake Wallet TUI');

      // Tab bar
      final tabs = screens.asMap().entries.map((e) {
        final isActive = e.key == _activeTab;
        final style = isActive
            ? Style()
                .bold(true)
                .foreground(cakeText)
                .background(cakePrimary)
                .paddingLeft(1)
                .paddingRight(1)
            : Style().foreground(cakeMuted).paddingLeft(1).paddingRight(1);
        final marker = isActive ? '> ' : '  ';
        return style.render('$marker${e.value.title}');
      }).toList();
      final tabBar = joinHorizontal(posTop, tabs);

      // Screen content
      final content = screens[_activeTab].render(w, h - 4, commandBus);

      // Status bar
      final statusBar = mutedStyle().width(w).render(
          ' Tab: switch  q: quit  Ctrl+C: force quit  Up/Down: navigate  Enter: select');

      final output =
          joinVertical(posLeft, [header, tabBar, content, statusBar]);

      // Flicker-free rendering: cursor home + write + clear remainder
      if (terminal.supportsAnsi) {
        stdout.write('\x1B[H');
        stdout.write(output);
        stdout.write('\x1B[J');
      } else {
        stdout.writeln(output);
      }
    } catch (e) {
      terminal.clearScreen();
      stdout.write('Render error: $e\nPress Ctrl+C to quit.');
    } finally {
      _rendering = false;
    }
  }

  void _cleanup() {
    if (_cleaned) return;
    _cleaned = true;
    _refreshTimer?.cancel();
    _eventSub?.cancel();
    terminal.disableRawMode();
    terminal.exitAlternateScreen();
    terminal.showCursor();
    terminal.dispose();
  }
}
