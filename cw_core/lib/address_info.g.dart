// GENERATED CODE - DO NOT MODIFY BY HAND
// Minimal stub for headless compilation. Regenerate with build_runner.

part of 'address_info.dart';

class AddressInfoAdapter extends TypeAdapter<AddressInfo> {
  @override
  final int typeId = ADDRESS_INFO_TYPE_ID;

  @override
  AddressInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AddressInfo(
      accountIndex: fields[0] as int?,
      address: fields[1] as String? ?? '',
      label: fields[2] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, AddressInfo obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.accountIndex)
      ..writeByte(1)
      ..write(obj.address)
      ..writeByte(2)
      ..write(obj.label);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddressInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
