// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'car_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CarProfileAdapter extends TypeAdapter<CarProfile> {
  @override
  final int typeId = 1;

  @override
  CarProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CarProfile(
      name: fields[0] as String,
      year: fields[1] as int,
      recommendedOctane: fields[2] as double,
      warningOctane: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, CarProfile obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.year)
      ..writeByte(2)
      ..write(obj.recommendedOctane)
      ..writeByte(3)
      ..write(obj.warningOctane);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CarProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
