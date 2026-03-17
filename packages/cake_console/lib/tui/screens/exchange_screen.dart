import 'package:dart_lipgloss/dart_lipgloss.dart';
import 'package:cake_headless/commands/command_bus.dart';
import 'package:cake_console/tui/tui_theme.dart';
import 'package:cake_console/tui/terminal_driver.dart';
import 'package:cake_console/tui/screen.dart';

class ExchangeScreen implements TuiScreen {
  final CommandBus _bus;
  String _fromCurrency = '';
  String _toCurrency = '';
  String _amount = '';
  int _focusField = 0; // 0=from, 1=to, 2=amount
  String? _statusMessage;
  bool _statusIsError = false;

  ExchangeScreen(this._bus);

  @override
  String get title => 'Exchange';

  @override
  String render(int width, int height, CommandBus bus) {
    final header = panelStyle().width(width - 4).render('Exchange / Swap');

    String fieldLabel(int index, String label) {
      final isActive = _focusField == index;
      final style = isActive
          ? Style().bold(true).foreground(cakeText)
          : mutedStyle();
      final marker = isActive ? '> ' : '  ';
      return style.render('$marker$label: ');
    }

    final fromVal = _fromCurrency.isEmpty
        ? mutedStyle().render('(e.g. XMR)')
        : _fromCurrency;
    final toVal = _toCurrency.isEmpty
        ? mutedStyle().render('(e.g. BTC)')
        : _toCurrency;
    final amtVal = _amount.isEmpty
        ? mutedStyle().render('(enter amount)')
        : _amount;

    final hints = mutedStyle()
        .render('Up/Down: switch field  Enter: get quote  Esc: clear');

    final parts = <String>[
      header,
      '',
      '${fieldLabel(0, "From    ")}$fromVal',
      '${fieldLabel(1, "To      ")}$toVal',
      '${fieldLabel(2, "Amount  ")}$amtVal',
      '',
      hints,
    ];

    if (_statusMessage != null) {
      final style = _statusIsError ? errorStyle() : successStyle();
      parts.add('');
      parts.add(style.render('  $_statusMessage'));
    }

    return joinVertical(posLeft, parts);
  }

  @override
  void handleInput(TerminalEvent event) {
    if (event.key == TerminalKey.escape) {
      _fromCurrency = '';
      _toCurrency = '';
      _amount = '';
      _focusField = 0;
      _statusMessage = null;
    } else if (event.key == TerminalKey.enter) {
      _getQuote();
    } else if (event.key == TerminalKey.up) {
      _focusField = (_focusField - 1 + 3) % 3;
    } else if (event.key == TerminalKey.down || event.key == TerminalKey.tab) {
      _focusField = (_focusField + 1) % 3;
    } else if (event.key == TerminalKey.backspace) {
      _deleteChar();
    } else if (event.key == TerminalKey.char && event.char != null) {
      _addChar(event.char!);
    }
  }

  void _addChar(String c) {
    switch (_focusField) {
      case 0:
        _fromCurrency += c.toUpperCase();
        break;
      case 1:
        _toCurrency += c.toUpperCase();
        break;
      case 2:
        _amount += c;
        break;
    }
  }

  void _deleteChar() {
    switch (_focusField) {
      case 0:
        if (_fromCurrency.isNotEmpty) {
          _fromCurrency =
              _fromCurrency.substring(0, _fromCurrency.length - 1);
        }
        break;
      case 1:
        if (_toCurrency.isNotEmpty) {
          _toCurrency = _toCurrency.substring(0, _toCurrency.length - 1);
        }
        break;
      case 2:
        if (_amount.isNotEmpty) {
          _amount = _amount.substring(0, _amount.length - 1);
        }
        break;
    }
  }

  void _getQuote() {
    if (_fromCurrency.isEmpty || _toCurrency.isEmpty || _amount.isEmpty) {
      _statusMessage = 'All fields are required';
      _statusIsError = true;
      return;
    }
    _bus.dispatch('swap.quote', {
      'from': _fromCurrency,
      'to': _toCurrency,
      'amount': _amount,
    }).then((result) {
      if (result.success) {
        _statusMessage = 'Quote received';
        _statusIsError = false;
      } else {
        _statusMessage = result.message ?? result.errorCode ?? 'Quote failed';
        _statusIsError = true;
      }
    });
  }
}
