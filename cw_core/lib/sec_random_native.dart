import 'dart:math';
import 'dart:typed_data';

Future<Uint8List> secRandom(int count) async {
  const byteSize = 256;
  final rng = Random.secure();
  return Uint8List.fromList(List<int>.generate(count, (_) => rng.nextInt(byteSize)));
}
