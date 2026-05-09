// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blog.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BlogAdapter extends TypeAdapter<Blog> {
  @override
  final int typeId = 5;

  @override
  Blog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Blog(
      id: fields[0] as String,
      title: fields[1] as String,
      content: fields[2] as String,
      author: fields[3] as String,
      authorId: fields[4] as String,
      startPlace: fields[5] as String,
      destination: fields[6] as String,
      distance: fields[7] as String,
      duration: fields[8] as String,
      startDate: fields[9] as DateTime,
      endDate: fields[10] as DateTime?,
      tags: (fields[11] as List).cast<String>(),
      imageUrls: (fields[12] as List).cast<String>(),
      dateCreated: fields[13] as DateTime,
      likes: fields[14] as int,
      comments: fields[15] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Blog obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.author)
      ..writeByte(4)
      ..write(obj.authorId)
      ..writeByte(5)
      ..write(obj.startPlace)
      ..writeByte(6)
      ..write(obj.destination)
      ..writeByte(7)
      ..write(obj.distance)
      ..writeByte(8)
      ..write(obj.duration)
      ..writeByte(9)
      ..write(obj.startDate)
      ..writeByte(10)
      ..write(obj.endDate)
      ..writeByte(11)
      ..write(obj.tags)
      ..writeByte(12)
      ..write(obj.imageUrls)
      ..writeByte(13)
      ..write(obj.dateCreated)
      ..writeByte(14)
      ..write(obj.likes)
      ..writeByte(15)
      ..write(obj.comments);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
