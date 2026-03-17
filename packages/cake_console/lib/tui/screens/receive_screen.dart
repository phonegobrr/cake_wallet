import 'package:dart_lipgloss/dart_lipgloss.dart';
import 'package:cake_headless/commands/command_bus.dart';
import 'package:cake_headless/dto/address_entry.dart';
import 'package:cake_console/tui/tui_theme.dart';
import 'package:cake_console/tui/terminal_driver.dart';
import 'package:cake_console/tui/screen.dart';
import 'package:cake_console/tui/widgets/qr_terminal.dart';

class ReceiveScreen implements TuiScreen {
  final CommandBus _bus;
  AddressEntry? _address;

  ReceiveScreen(this._bus) {
    _refresh();
  }

  @override
  String get title => 'Receive';

  Future<void> _refresh() async {
    final result = await _bus.dispatch('receive.address', {});
    if (result.success) _address = result.data as AddressEntry?;
  }

  @override
  String render(int width, int height, CommandBus bus) {
    final header = panelStyle().width(width - 4).render('Receive');

    if (_address == null) {
      return joinVertical(Position.left, [
        header,
        '',
        mutedStyle().render('  No wallet open'),
      ]);
    }

    final addrText = Style().bold(true).foreground(cakeText).render(_address!.address);
    final qr = renderQrCode(_address!.address);

    return joinVertical(Position.left, [
      header,
      '',
      '  Address:',
      '  $addrText',
      '',
      qr,
    ]);
  }

  @override
  void handleInput(TerminalEvent event) {
    // No input handling needed for receive screen
  }
}
