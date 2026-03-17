import 'package:qr/qr.dart';

/// Renders a QR code as a string using Unicode half-block characters.
/// Two QR rows map to one terminal row using:
///   - (space) = both rows white
///   - full block = both rows black
///   - upper half block = top black, bottom white
///   - lower half block = top white, bottom black
String renderQrCode(String data) {
  final qrCode = QrCode.fromData(
    data: data,
    errorCorrectLevel: QrErrorCorrectLevel.M,
  );
  final image = QrImage(qrCode);
  final size = qrCode.moduleCount;

  // Add a quiet zone of 1 module around the QR code
  const quiet = 1;
  final totalSize = size + quiet * 2;

  bool isDark(int row, int col) {
    final r = row - quiet;
    final c = col - quiet;
    if (r < 0 || r >= size || c < 0 || c >= size) return false;
    return image.isDark(r, c);
  }

  final buffer = StringBuffer();
  for (int y = 0; y < totalSize; y += 2) {
    buffer.write('  '); // indent
    for (int x = 0; x < totalSize; x++) {
      final top = isDark(y, x);
      final bottom = (y + 1 < totalSize) ? isDark(y + 1, x) : false;
      if (top && bottom) {
        buffer.write('\u2588'); // full block
      } else if (top) {
        buffer.write('\u2580'); // upper half block
      } else if (bottom) {
        buffer.write('\u2584'); // lower half block
      } else {
        buffer.write(' ');
      }
    }
    buffer.writeln();
  }
  return buffer.toString();
}
