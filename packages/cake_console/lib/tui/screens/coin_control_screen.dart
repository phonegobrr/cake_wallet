import 'package:dart_lipgloss/dart_lipgloss.dart';
import 'package:cake_headless/commands/command_bus.dart';
import 'package:cake_console/tui/tui_theme.dart';
import 'package:cake_console/tui/terminal_driver.dart';
import 'package:cake_console/tui/screen.dart';

class CoinControlScreen extends TuiScreen {
  final CommandBus _bus;
  List<Map<String, dynamic>> _coins = [];
  int _selectedIndex = 0;
  int _scrollOffset = 0;
  bool _isLoading = true;
  String? _statusMessage;
  bool _statusIsError = false;

  CoinControlScreen(this._bus);

  @override
  String get title => 'Coins';

  @override
  Future<void> init() async => refresh();

  @override
  Future<void> refresh() async {
    try {
      final result = await _bus.dispatch('coins.list', {});
      if (result.success && result.data is List) {
        _coins = (result.data as List).map((e) {
          if (e is Map<String, dynamic>) return e;
          try { return (e as dynamic).toJson() as Map<String, dynamic>; }
          catch (_) { return <String, dynamic>{'value': e.toString()}; }
        }).toList();
      } else {
        _coins = [];
      }
    } catch (_) {
      _coins = [];
    }
    if (_coins.isNotEmpty) {
      _selectedIndex = _selectedIndex.clamp(0, _coins.length - 1);
    } else {
      _selectedIndex = 0;
    }
    _isLoading = false;
  }

  @override
  String render(int width, int height, CommandBus bus) {
    if (_isLoading) return mutedStyle().render('  Loading...');

    final header = panelStyle().width(width - 4).render('Coin Control (UTXO)');

    if (_coins.isEmpty) {
      return joinVertical(posLeft, [
        header,
        '',
        mutedStyle().render('  No coins available (UTXO wallets only).'),
      ]);
    }

    final availableHeight = (height - 6).clamp(1, _coins.length);
    if (_selectedIndex < _scrollOffset) _scrollOffset = _selectedIndex;
    if (_selectedIndex >= _scrollOffset + availableHeight) {
      _scrollOffset = _selectedIndex - availableHeight + 1;
    }

    final visible = _coins.asMap().entries.skip(_scrollOffset).take(availableHeight);

    final rows = visible.map((e) {
      final isSelected = e.key == _selectedIndex;
      final c = e.value;
      final style = isSelected
          ? Style().bold(true).foreground(cakeText) : mutedStyle();
      final marker = isSelected ? '> ' : '  ';
      return style.render('$marker${c['id'] ?? c['value'] ?? 'Unknown'}');
    }).toList();

    final parts = <String>[header, '', ...rows];
    parts.add('');
    parts.add(mutedStyle().render('  f: freeze  u: unfreeze  Up/Down: navigate'));

    if (_statusMessage != null) {
      final style = _statusIsError ? errorStyle() : successStyle();
      parts.add(style.render('  $_statusMessage'));
    }

    return joinVertical(posLeft, parts);
  }

  @override
  void handleInput(TerminalEvent event) {
    if (_coins.isEmpty) return;
    final maxIndex = _coins.length - 1;
    if (event.key == TerminalKey.up) {
      _selectedIndex = (_selectedIndex - 1).clamp(0, maxIndex);
    } else if (event.key == TerminalKey.down) {
      _selectedIndex = (_selectedIndex + 1).clamp(0, maxIndex);
    } else if (event.key == TerminalKey.char && event.char == 'f') {
      _freezeCoin();
    } else if (event.key == TerminalKey.char && event.char == 'u') {
      _unfreezeCoin();
    }
  }

  void _freezeCoin() {
    final id = _coins[_selectedIndex]['id']?.toString() ?? '';
    if (id.isEmpty) return;
    _bus.dispatch('coins.freeze', {'id': id}).then((result) {
      _statusMessage = result.success ? 'Frozen' : (result.message ?? 'Failed');
      _statusIsError = !result.success;
      refresh().then((_) => onStateChanged?.call());
    });
  }

  void _unfreezeCoin() {
    final id = _coins[_selectedIndex]['id']?.toString() ?? '';
    if (id.isEmpty) return;
    _bus.dispatch('coins.unfreeze', {'id': id}).then((result) {
      _statusMessage = result.success ? 'Unfrozen' : (result.message ?? 'Failed');
      _statusIsError = !result.success;
      refresh().then((_) => onStateChanged?.call());
    });
  }
}
