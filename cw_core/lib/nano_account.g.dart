// GENERATED CODE - DO NOT MODIFY BY HAND
// Minimal stub for headless compilation. Regenerate with build_runner.

part of 'nano_account.dart';

class NanoAccountAdapter extends TypeAdapter<NanoAccount> {
  @override
  final int typeId = NanoAccount.typeId;

  @override
  NanoAccount read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NanoAccount(
      label: fields[0] as String? ?? '',
      id: fields[1] as int? ?? 0,
      isSelected: fields[2] as bool? ?? false,
      balance: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, NanoAccount obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.label)
      ..writeByte(1)
      ..write(obj.id)
      ..writeByte(2)
      ..write(obj.isSelected)
      ..writeByte(3)
      ..write(obj.balance);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NanoAccountAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
