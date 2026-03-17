import 'package:dart_lipgloss/dart_lipgloss.dart';
import 'package:cake_headless/commands/command_bus.dart';
import 'package:cake_console/tui/tui_theme.dart';
import 'package:cake_console/tui/terminal_driver.dart';
import 'package:cake_console/tui/screen.dart';

class SendScreen implements TuiScreen {
  final CommandBus _bus;
  String _address = '';
  String _amount = '';
  int _focusField = 0; // 0=address, 1=amount
  String? _statusMessage;
  bool _statusIsError = false;

  SendScreen(this._bus);

  @override
  String get title => 'Send';

  @override
  String render(int width, int height, CommandBus bus) {
    final header = panelStyle().width(width - 4).render('Send Transaction');

    final addrLabel = _focusField == 0
        ? Style().bold(true).foreground(cakeText).render('> Address: ')
        : mutedStyle().render('  Address: ');
    final addrValue = _address.isEmpty ? mutedStyle().render('(enter address)') : _address;

    final amtLabel = _focusField == 1
        ? Style().bold(true).foreground(cakeText).render('> Amount:  ')
        : mutedStyle().render('  Amount:  ');
    final amtValue = _amount.isEmpty ? mutedStyle().render('(enter amount)') : _amount;

    final hints = mutedStyle().render('Tab: next field  Enter: send  Esc: clear');

    final parts = <String>[
      header,
      '',
      '$addrLabel$addrValue',
      '$amtLabel$amtValue',
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
      _address = '';
      _amount = '';
      _focusField = 0;
      _statusMessage = null;
    } else if (event.key == TerminalKey.enter) {
      _submitSend();
    } else if (event.key == TerminalKey.tab) {
      _focusField = (_focusField + 1) % 2;
    } else if (event.key == TerminalKey.backspace) {
      if (_focusField == 0 && _address.isNotEmpty) {
        _address = _address.substring(0, _address.length - 1);
      } else if (_focusField == 1 && _amount.isNotEmpty) {
        _amount = _amount.substring(0, _amount.length - 1);
      }
    } else if (event.key == TerminalKey.char && event.char != null) {
      if (_focusField == 0) {
        _address += event.char!;
      } else {
        _amount += event.char!;
      }
    }
  }

  void _submitSend() {
    if (_address.isEmpty || _amount.isEmpty) {
      _statusMessage = 'Address and amount are required';
      _statusIsError = true;
      return;
    }
    _bus.dispatch('send', {
      'address': _address,
      'amount': _amount,
    }).then((result) {
      if (result.success) {
        _statusMessage = 'Transaction sent';
        _statusIsError = false;
        _address = '';
        _amount = '';
      } else {
        _statusMessage = result.message ?? result.errorCode ?? 'Send failed';
        _statusIsError = true;
      }
    });
  }
}
