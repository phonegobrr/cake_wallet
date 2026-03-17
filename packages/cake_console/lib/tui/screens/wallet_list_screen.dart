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

  WalletListScreen(this._bus);

  @override
  String get title => 'Wallets';

  @override
  Future<void> init() async => refresh();

  @override
  Future<void> refresh() async {
    try {
      final result = await _bus.dispatch('wallet.list', {});
      if (result.success) _wallets = (result.data as List<WalletSummary>?) ?? [];
    } catch (_) {}
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

    final rows = _wallets.asMap().entries.map((e) {
      final isSelected = e.key == _selectedIndex;
      final w = e.value;
      final marker = isSelected ? '> ' : '  ';
      final active = w.isActive ? ' [active]' : '';
      final style =
          isSelected ? Style().bold(true).foreground(cakeText) : mutedStyle();
      return style.render('$marker${w.name} (${w.typeName})$active');
    }).toList();

    return joinVertical(posLeft, [header, '', ...rows]);
  }

  @override
  void handleInput(TerminalEvent event) {
    if (_wallets.isEmpty) return;
    final maxIndex = _wallets.length - 1;
    if (event.key == TerminalKey.up) {
      _selectedIndex = (_selectedIndex - 1).clamp(0, maxIndex);
    } else if (event.key == TerminalKey.down) {
      _selectedIndex = (_selectedIndex + 1).clamp(0, maxIndex);
    }
  }
}
