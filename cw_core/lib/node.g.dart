// GENERATED CODE - DO NOT MODIFY BY HAND
// Minimal stub for headless compilation. Regenerate with build_runner.

part of 'node.dart';

class NodeAdapter extends TypeAdapter<Node> {
  @override
  final int typeId = Node.typeId;

  @override
  Node read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Node(
      label: fields[5] as String?,
      uri: fields[0] as String?,
      login: fields[1] as String?,
      password: fields[2] as String?,
      useSSL: fields[4] as bool?,
      type: fields[3] as WalletType?,
    );
  }

  @override
  void write(BinaryWriter writer, Node obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.uriRaw)
      ..writeByte(1)
      ..write(obj.login)
      ..writeByte(2)
      ..write(obj.password)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.useSSL)
      ..writeByte(5)
      ..write(obj.label);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NodeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
