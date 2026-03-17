import 'package:dart_lipgloss/dart_lipgloss.dart';
import 'package:dart_lipgloss/table.dart' as lip_table;
import 'package:cake_headless/commands/command_bus.dart';
import 'package:cake_headless/dto/transaction_summary.dart';
import 'package:cake_console/tui/tui_theme.dart';
import 'package:cake_console/tui/terminal_driver.dart';
import 'package:cake_console/tui/screen.dart';

class HistoryScreen extends TuiScreen {
  final CommandBus _bus;
  List<TransactionSummary> _txs = [];
  int _selectedIndex = 0;
  bool _isLoading = true;

  HistoryScreen(this._bus);

  @override
  String get title => 'History';

  @override
  Future<void> init() async => refresh();

  @override
  Future<void> refresh() async {
    try {
      final result = await _bus.dispatch('history.list', {'limit': 50});
      if (result.success) _txs = (result.data as List<TransactionSummary>?) ?? [];
    } catch (_) {}
    _isLoading = false;
  }

  @override
  String render(int width, int height, CommandBus bus) {
    if (_isLoading) return mutedStyle().render('  Loading...');

    final header = panelStyle().width(width - 4).render('Transaction History');

    if (_txs.isEmpty) {
      return joinVertical(posLeft, [
        header,
        '',
        mutedStyle().render('  No transactions'),
      ]);
    }

    final table = lip_table.Table()
      ..headers(['Date', 'Dir', 'Amount', 'Confirmations', 'Status'])
      ..rows(_txs.map((tx) => [
            tx.dateFormatted,
            tx.isIncoming ? 'IN ' : 'OUT',
            tx.amount,
            '${tx.confirmations}',
            tx.isPending ? 'Pending' : 'Confirmed',
          ]).toList())
      ..borderDef(roundedBorder)
      ..borderColumn(true)
      ..borderStyleDef(Style().foreground(cakePrimary));

    return joinVertical(posLeft, [header, '', table.render()]);
  }

  @override
  void handleInput(TerminalEvent event) {
    if (_txs.isEmpty) return;
    final maxIndex = _txs.length - 1;
    if (event.key == TerminalKey.up) {
      _selectedIndex = (_selectedIndex - 1).clamp(0, maxIndex);
    } else if (event.key == TerminalKey.down) {
      _selectedIndex = (_selectedIndex + 1).clamp(0, maxIndex);
    }
  }
}
