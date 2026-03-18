import 'package:dart_lipgloss/dart_lipgloss.dart';
import 'package:cake_headless/commands/command_bus.dart';
import 'package:cake_headless/dto/wallet_summary.dart';
import 'package:cake_console/tui/tui_theme.dart';
import 'package:cake_console/tui/terminal_driver.dart';
import 'package:cake_console/tui/screen.dart';

class WalletListScreen extends TuiScreen {
  final CommandBus _bus;
  List<WalletSummary> _wallets = [];
  int _selectedIndex = 0;
  bool _isLoading = true;
  String? _statusMessage;
  bool _statusIsError = false;
  int _scrollOffset = 0;

  WalletListScreen(this._bus);

  @override
  String get title => 'Wallets';

  @override
  List<String> get supportedCommands => const ['wallet.list', 'wallet.open', 'wallet.delete'];

  @override
  Future<void> init() async => refresh();

  @override
  Future<void> refresh() async {
    try {
      final result = await _bus.dispatch('wallet.list', {});
      _wallets = result.success
          ? (result.data as List<WalletSummary>?) ?? []
          : [];
    } catch (_) {
      _wallets = [];
    }
    // Clamp selected index after list may have shrunk
    if (_wallets.isNotEmpty) {
      _selectedIndex = _selectedIndex.clamp(0, _wallets.length - 1);
    } else {
      _selectedIndex = 0;
    }
    _isLoading = false;
  }

  @override
  String render(int width, int height, CommandBus bus) {
    if (_isLoading) return mutedStyle().render('  Loading...');

    final header = panelStyle().width(width - 4).render('Wallets');

    if (_wallets.isEmpty) {
      return joinVertical(posLeft, [
        header,
        '',
        mutedStyle().render('  No wallets found.'),
      ]);
    }

    // Viewport: show only what fits in available height
    final availableHeight = (height - 6).clamp(1, _wallets.length);
    if (_selectedIndex < _scrollOffset) {
      _scrollOffset = _selectedIndex;
    }
    if (_selectedIndex >= _scrollOffset + availableHeight) {
      _scrollOffset = _selectedIndex - availableHeight + 1;
    }

    final visibleWallets = _wallets
        .asMap()
        .entries
        .skip(_scrollOffset)
        .take(availableHeight);

    final rows = visibleWallets.map((e) {
      final isSelected = e.key == _selectedIndex;
      final w = e.value;
      final marker = isSelected ? '> ' : '  ';
      final active = w.isActive ? ' [active]' : '';
      final style =
          isSelected ? Style().bold(true).foreground(cakeText) : mutedStyle();
      return style.render('$marker${w.name} (${w.typeName})$active');
    }).toList();

    final hints =
        mutedStyle().render('  Enter: open  d: delete  Up/Down: navigate');

    final parts = <String>[header, '', ...rows, '', hints];

    if (_statusMessage != null) {
      final style = _statusIsError ? errorStyle() : successStyle();
      parts.add(style.render('  $_statusMessage'));
    }

    return joinVertical(posLeft, parts);
  }

  @override
  void handleInput(TerminalEvent event) {
    if (_wallets.isEmpty) return;
    final maxIndex = _wallets.length - 1;
    if (event.key == TerminalKey.up) {
      _selectedIndex = (_selectedIndex - 1).clamp(0, maxIndex);
    } else if (event.key == TerminalKey.down) {
      _selectedIndex = (_selectedIndex + 1).clamp(0, maxIndex);
    } else if (event.key == TerminalKey.enter) {
      _openSelected();
    } else if (event.key == TerminalKey.char && event.char == 'd') {
      _deleteSelected();
    }
  }

  void _openSelected() {
    if (_wallets.isEmpty) return;
    final w = _wallets[_selectedIndex];
    _statusMessage = 'Opening ${w.name}...';
    _statusIsError = false;
    _bus.dispatch('wallet.open', {
      'name': w.name,
      'type': w.typeRaw,
    }).then((result) {
      if (result.success) {
        _statusMessage = 'Opened ${w.name}';
        _statusIsError = false;
      } else {
        _statusMessage = result.message ?? 'Failed to open wallet';
        _statusIsError = true;
      }
      onStateChanged?.call();
    });
  }

  void _deleteSelected() {
    if (_wallets.isEmpty) return;
    final w = _wallets[_selectedIndex];
    _statusMessage = 'Deleting ${w.name}...';
    _statusIsError = false;
    onStateChanged?.call();
    _bus.dispatch('wallet.delete', {
      'name': w.name,
      'type': w.typeRaw,
    }).then((result) {
      if (result.success) {
        _statusMessage = 'Deleted ${w.name}';
        _statusIsError = false;
        refresh().then((_) => onStateChanged?.call());
      } else {
        _statusMessage = result.message ?? 'Failed to delete wallet';
        _statusIsError = true;
      }
      onStateChanged?.call();
    });
  }
}
