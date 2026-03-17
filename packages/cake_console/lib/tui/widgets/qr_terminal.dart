/// Renders a simple text representation of data for terminal display.
/// For a full QR code, the `qr` package would be needed. This provides
/// a placeholder that displays the address in a box format.
String renderQrCode(String data) {
  // Without the `qr` package, we render a framed address display.
  // When the qr package is added, this will use half-block characters
  // for proper QR rendering.
  final width = data.length + 4;
  final topBorder = '+${'-' * (width - 2)}+';
  final emptyLine = '|${' ' * (width - 2)}|';
  final dataLine = '| $data |';

  final buffer = StringBuffer();
  buffer.writeln('  $topBorder');
  buffer.writeln('  $emptyLine');
  buffer.writeln('  $dataLine');
  buffer.writeln('  $emptyLine');
  buffer.writeln('  $topBorder');
  return buffer.toString();
}
