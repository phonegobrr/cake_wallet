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
import 'package:cake_console/tui/screens/nodes_screen.dart';
import 'package:cake_console/tui/screens/backup_screen.dart';
import 'package:cake_console/tui/screens/coin_control_screen.dart';
import 'package:cake_console/tui/screens/token_screen.dart';
import 'package:cake_console/tui/screens/tor_screen.dart';
import 'package:cake_console/tui/screens/command_palette_screen.dart';

class TuiApp {
  final CommandBus commandBus;
  final WalletEventBus eventBus;
  final TerminalDriver terminal;

  late final List<TuiScreen> screens;
  int _activeTab = 0;
  StreamSubscription? _eventSub;
  Timer? _refreshTimer;
  Timer? _resizeTimer;
  bool _rendering = false;
  bool _pendingRender = false;
  bool _cleaned = false;
  bool _isRefreshing = false;
  final Set<int> _initializedTabs = {};

  // Hotkey-to-tab mapping
  static const _hotkeyMap = {
    's': 2,  // Send
    'r': 3,  // Receive
    'w': 1,  // Wallets
    'e': 5,  // Exchange
    'h': 4,  // History
    'c': 7,  // Contacts
    'n': 8,  // Nodes
    'b': 9,  // Backup
    't': 12, // Tor
  };

  TuiApp({
    required this.commandBus,
    required this.eventBus,
    TerminalDriver? driver,
  }) : terminal = driver ?? TerminalDriver() {
    screens = [
      DashboardScreen(commandBus),    // 0
      WalletListScreen(commandBus),   // 1
      SendScreen(commandBus),         // 2
      ReceiveScreen(commandBus),      // 3
      HistoryScreen(commandBus),      // 4
      ExchangeScreen(commandBus),     // 5
      SettingsScreen(commandBus),     // 6
      ContactsScreen(commandBus),     // 7
      NodesScreen(commandBus),        // 8
      BackupScreen(commandBus),       // 9
      CoinControlScreen(commandBus),  // 10
      TokenScreen(commandBus),        // 11
      TorScreen(commandBus),          // 12
      CommandPaletteScreen(commandBus), // 13 — always last (: hotkey uses screens.length - 1)
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
    } else {
      // Windows: poll for terminal resize since SIGWINCH doesn't exist
      int lastWidth = terminal.width;
      int lastHeight = terminal.height;
      _resizeTimer = Timer.periodic(Duration(milliseconds: 500), (_) {
        if (terminal.width != lastWidth || terminal.height != lastHeight) {
          lastWidth = terminal.width;
          lastHeight = terminal.height;
          _render();
        }
      });
    }

    terminal.enableRawMode();
    terminal.enterAlternateScreen();
    terminal.hideCursor();

    try {
      // Subscribe to event bus with debounced refresh
      _eventSub = eventBus.events.listen((_) => _scheduleRefresh());

      // Initialize and render first screen
      await screens[_activeTab].init();
      _initializedTabs.add(_activeTab);
      await screens[_activeTab].refresh();
      screens[_activeTab].onEnter();
      _render();

      // Start periodic refresh AFTER init completes
      _refreshTimer = Timer.periodic(Duration(seconds: 5), (_) async {
        await _safeRefresh();
      });

      await for (final event in terminal.events) {
        // Ctrl+C always quits
        if (event.key == TerminalKey.ctrlC) {
          break;
        }

        // Tab/Shift-Tab ALWAYS work, even when screen captures input (6.2)
        if (event.key == TerminalKey.tab) {
          await _switchTab((_activeTab + 1) % screens.length);
          _render();
          continue;
        }
        if (event.key == TerminalKey.shiftTab) {
          await _switchTab((_activeTab - 1 + screens.length) % screens.length);
          _render();
          continue;
        }

        // ':' always opens command palette regardless of capture mode
        if (event.key == TerminalKey.char && event.char == ':' &&
            _activeTab != screens.length - 1) {
          await _switchTab(screens.length - 1); // Command palette is last
          _render();
          continue;
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
    if (!_initializedTabs.contains(newTab)) {
      await screens[newTab].init();
      _initializedTabs.add(newTab);
    }
    screens[_activeTab].onEnter();
    await screens[_activeTab].refresh();
  }

  /// Debounced refresh for burst events (sync/balance updates)
  Timer? _refreshDebounce;
  void _scheduleRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(Duration(milliseconds: 100), () async {
      await _safeRefresh();
    });
  }

  /// Safe refresh with serialization guard and error handling
  Future<void> _safeRefresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      await screens[_activeTab].refresh();
      _render();
    } catch (e) {
      stderr.writeln('[TUI] Refresh error: $e');
    } finally {
      _isRefreshing = false;
    }
  }

  void _render() {
    if (_rendering) {
      _pendingRender = true;
      return;
    }
    _rendering = true;
    try {
      final w = terminal.width;
      final h = terminal.height;

      // Guard against absurdly small terminals
      if (w < 20 || h < 5) return;

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
      if (_pendingRender) {
        _pendingRender = false;
        _render();
      }
    }
  }

  void _cleanup() {
    if (_cleaned) return;
    _cleaned = true;
    _refreshTimer?.cancel();
    _refreshDebounce?.cancel();
    _resizeTimer?.cancel();
    _eventSub?.cancel();
    terminal.disableRawMode();
    terminal.exitAlternateScreen();
    terminal.showCursor();
    terminal.dispose();
  }
}
