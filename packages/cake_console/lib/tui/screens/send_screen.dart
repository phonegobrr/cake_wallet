import 'package:dart_lipgloss/dart_lipgloss.dart';
import 'package:cake_headless/commands/command_bus.dart';
import 'package:cake_console/tui/tui_theme.dart';
import 'package:cake_console/tui/terminal_driver.dart';
import 'package:cake_console/tui/screen.dart';

enum _SendState { input, previewing, sending }

class SendScreen extends TuiScreen {
  final CommandBus _bus;
  String _address = '';
  String _amount = '';
  int _focusField = 0; // 0=address, 1=amount
  String? _statusMessage;
  bool _statusIsError = false;
  _SendState _state = _SendState.input;
  Map<String, String>? _previewData;
  bool _inFlight = false;

  SendScreen(this._bus);

  @override
  String get title => 'Send';

  @override
  bool get capturesInput => true;

  @override
  String render(int width, int height, CommandBus bus) {
    final header = panelStyle().width(width - 4).render('Send Transaction');

    final addrLabel = _focusField == 0
        ? Style().bold(true).foreground(cakeText).render('> Address: ')
        : mutedStyle().render('  Address: ');
    final addrValue =
        _address.isEmpty ? mutedStyle().render('(enter address)') : _address;

    final amtLabel = _focusField == 1
        ? Style().bold(true).foreground(cakeText).render('> Amount:  ')
        : mutedStyle().render('  Amount:  ');
    final amtValue =
        _amount.isEmpty ? mutedStyle().render('(enter amount)') : _amount;

    String hints;
    if (_state == _SendState.previewing) {
      hints = mutedStyle()
          .render('Enter: confirm and send  Esc: cancel  Up/Down: switch field');
    } else {
      hints = mutedStyle()
          .render('Up/Down: switch field  Enter: preview  Esc: clear');
    }

    final parts = <String>[
      header,
      '',
      '$addrLabel$addrValue',
      '$amtLabel$amtValue',
    ];

    if (_previewData != null) {
      parts.add('');
      parts.add(successStyle()
          .render('  Preview: ${_previewData!['amount'] ?? _amount} '
              '${_previewData!['currency'] ?? ''} -> '
              '${_previewData!['address'] ?? _address}'));
      parts.add(mutedStyle()
          .render('  Priority: ${_previewData!['priority'] ?? 'default'}'));
    }

    parts.addAll(['', hints]);

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
      _state = _SendState.input;
      _previewData = null;
    } else if (event.key == TerminalKey.enter) {
      if (_state == _SendState.previewing) {
        _commitSend();
      } else {
        _previewSend();
      }
    } else if (event.key == TerminalKey.up) {
      _focusField = (_focusField - 1).clamp(0, 1);
    } else if (event.key == TerminalKey.down) {
      _focusField = (_focusField + 1).clamp(0, 1);
    } else if (event.key == TerminalKey.backspace) {
      if (_state == _SendState.previewing) return;
      if (_focusField == 0 && _address.isNotEmpty) {
        _address = _address.substring(0, _address.length - 1);
      } else if (_focusField == 1 && _amount.isNotEmpty) {
        _amount = _amount.substring(0, _amount.length - 1);
      }
    } else if (event.key == TerminalKey.char && event.char != null) {
      if (_state == _SendState.previewing) return;
      if (_focusField == 0) {
        _address += event.char!;
      } else {
        _amount += event.char!;
      }
    }
  }

  void _previewSend() {
    if (_inFlight) return;
    if (_address.isEmpty || _amount.isEmpty) {
      _statusMessage = 'Address and amount are required';
      _statusIsError = true;
      return;
    }
    _inFlight = true;
    _statusMessage = 'Previewing...';
    _statusIsError = false;
    _bus.dispatch('send.preview', {
      'address': _address,
      'amount': _amount,
    }).then((result) {
      _inFlight = false;
      if (result.success && result.data is Map) {
        _previewData = (result.data as Map).map(
            (k, v) => MapEntry(k.toString(), v.toString()));
        _state = _SendState.previewing;
        _statusMessage = 'Review the preview above, then press Enter to send';
        _statusIsError = false;
      } else {
        _statusMessage = result.message ?? result.errorCode ?? 'Preview failed';
        _statusIsError = true;
      }
      onStateChanged?.call();
    });
  }

  void _commitSend() {
    if (_inFlight) return;
    _inFlight = true;
    _statusMessage = 'Sending...';
    _statusIsError = false;
    _state = _SendState.sending;
    onStateChanged?.call();

    _bus.dispatch('send', {
      'address': _address,
      'amount': _amount,
    }).then((result) {
      _inFlight = false;
      if (result.success) {
        _statusMessage = 'Transaction sent';
        _statusIsError = false;
        _address = '';
        _amount = '';
        _previewData = null;
        _state = _SendState.input;
      } else {
        _statusMessage = result.message ?? result.errorCode ?? 'Send failed';
        _statusIsError = true;
        _state = _SendState.previewing;
      }
      onStateChanged?.call();
    });
  }
}
