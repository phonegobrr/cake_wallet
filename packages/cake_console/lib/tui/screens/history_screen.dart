import 'package:dart_lipgloss/dart_lipgloss.dart';
import 'package:dart_lipgloss/table.dart' as lip_table;
import 'package:cake_headless/commands/command_bus.dart';
import 'package:cake_headless/dto/transaction_summary.dart';
import 'package:cake_console/tui/tui_theme.dart';
import 'package:cake_console/tui/terminal_driver.dart';
import 'package:cake_console/tui/screen.dart';

class HistoryScreen implements TuiScreen {
  final CommandBus _bus;
  List<TransactionSummary> _txs = [];
  int _selectedIndex = 0;

  HistoryScreen(this._bus) {
    _refresh();
  }

  @override
  String get title => 'History';

  Future<void> _refresh() async {
    final result = await _bus.dispatch('history.list', {'limit': 50});
    if (result.success) _txs = (result.data as List<TransactionSummary>?) ?? [];
  }

  @override
  String render(int width, int height, CommandBus bus) {
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
    if (event.key == TerminalKey.up) {
      _selectedIndex = (_selectedIndex - 1).clamp(0, _txs.length - 1);
    } else if (event.key == TerminalKey.down) {
      _selectedIndex = (_selectedIndex + 1).clamp(0, _txs.length - 1);
    }
  }
}
