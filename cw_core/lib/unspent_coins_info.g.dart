// GENERATED CODE - DO NOT MODIFY BY HAND
// Minimal stub for headless compilation. Regenerate with build_runner.

part of 'unspent_coins_info.dart';

class UnspentCoinsInfoAdapter extends TypeAdapter<UnspentCoinsInfo> {
  @override
  final int typeId = UnspentCoinsInfo.typeId;

  @override
  UnspentCoinsInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UnspentCoinsInfo(
      walletId: fields[0] as String? ?? '',
      hash: fields[1] as String? ?? '',
      isFrozen: fields[2] as bool? ?? false,
      isSending: fields[3] as bool? ?? false,
      noteRaw: fields[4] as String?,
      address: fields[5] as String? ?? '',
      value: fields[6] as int? ?? 0,
      vout: fields[7] as int? ?? 0,
      keyImage: fields[8] as String?,
      isChange: fields[9] as bool? ?? false,
      accountIndex: fields[10] as int? ?? 0,
      isSilentPayment: fields[11] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, UnspentCoinsInfo obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.walletId)
      ..writeByte(1)
      ..write(obj.hash)
      ..writeByte(2)
      ..write(obj.isFrozen)
      ..writeByte(3)
      ..write(obj.isSending)
      ..writeByte(4)
      ..write(obj.noteRaw)
      ..writeByte(5)
      ..write(obj.address)
      ..writeByte(6)
      ..write(obj.value)
      ..writeByte(7)
      ..write(obj.vout)
      ..writeByte(8)
      ..write(obj.keyImage)
      ..writeByte(9)
      ..write(obj.isChange)
      ..writeByte(10)
      ..write(obj.accountIndex)
      ..writeByte(11)
      ..write(obj.isSilentPayment);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnspentCoinsInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
