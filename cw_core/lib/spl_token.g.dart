// GENERATED CODE - DO NOT MODIFY BY HAND
// Minimal stub for headless compilation. Regenerate with build_runner.

part of 'spl_token.dart';

class SPLTokenAdapter extends TypeAdapter<SPLToken> {
  @override
  final int typeId = SPLToken.typeId;

  @override
  SPLToken read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SPLToken(
      name: fields[0] as String? ?? '',
      symbol: fields[1] as String? ?? '',
      mintAddress: fields[2] as String? ?? '',
      decimal: fields[3] as int? ?? 0,
      enabled: fields[4] as bool? ?? true,
      mint: fields[5] as String? ?? '',
      iconPath: fields[6] as String?,
      tag: fields[7] as String? ?? 'SOL',
      isPotentialScam: fields[8] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, SPLToken obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.symbol)
      ..writeByte(2)
      ..write(obj.mintAddress)
      ..writeByte(3)
      ..write(obj.decimal)
      ..writeByte(4)
      ..write(obj.enabled)
      ..writeByte(5)
      ..write(obj.mint)
      ..writeByte(6)
      ..write(obj.iconPath)
      ..writeByte(7)
      ..write(obj.tag)
      ..writeByte(8)
      ..write(obj.isPotentialScam);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SPLTokenAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
