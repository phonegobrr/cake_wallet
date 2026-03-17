import 'package:dart_lipgloss/dart_lipgloss.dart';
import 'package:cake_headless/commands/command_bus.dart';
import 'package:cake_headless/dto/wallet_summary.dart';
import 'package:cake_console/tui/tui_theme.dart';
import 'package:cake_console/tui/terminal_driver.dart';
import 'package:cake_console/tui/screen.dart';

class WalletListScreen implements TuiScreen {
  final CommandBus _bus;
  List<WalletSummary> _wallets = [];
  int _selectedIndex = 0;

  WalletListScreen(this._bus) {
    _refresh();
  }

  @override
  String get title => 'Wallets';

  Future<void> _refresh() async {
    final result = await _bus.dispatch('wallet.list', {});
    if (result.success) _wallets = (result.data as List<WalletSummary>?) ?? [];
  }

  @override
  String render(int width, int height, CommandBus bus) {
    final header = panelStyle().width(width - 4).render('Wallets');

    if (_wallets.isEmpty) {
      return joinVertical(Position.left, [
        header,
        '',
        mutedStyle().render('  No wallets found. Create one with [C]reate.'),
      ]);
    }

    final rows = _wallets.asMap().entries.map((e) {
      final isSelected = e.key == _selectedIndex;
      final w = e.value;
      final marker = isSelected ? '> ' : '  ';
      final active = w.isActive ? ' [active]' : '';
      final style = isSelected ? Style().bold(true).foreground(cakeText) : mutedStyle();
      return style.render('$marker${w.name} (${w.typeName})$active');
    }).toList();

    return joinVertical(Position.left, [header, '', ...rows]);
  }

  @override
  void handleInput(TerminalEvent event) {
    if (event.key == TerminalKey.up) {
      _selectedIndex = (_selectedIndex - 1).clamp(0, _wallets.length - 1);
    } else if (event.key == TerminalKey.down) {
      _selectedIndex = (_selectedIndex + 1).clamp(0, _wallets.length - 1);
    }
  }
}
