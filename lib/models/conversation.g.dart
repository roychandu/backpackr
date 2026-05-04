// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ConversationAdapter extends TypeAdapter<Conversation> {
  @override
  final int typeId = 4;

  @override
  Conversation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Conversation(
      id: fields[0] as String,
      participants: (fields[1] as Map).cast<String, bool>(),
      participantNames: (fields[2] as Map).cast<String, String>(),
      lastMessageId: fields[3] as String,
      lastMessageContent: fields[4] as String,
      lastMessageSenderId: fields[5] as String,
      lastMessageTimestamp: fields[6] as DateTime,
      isActive: fields[7] as bool,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
      readStatus: (fields[10] as Map).cast<String, bool>(),
      unreadCounts: (fields[11] as Map).cast<String, int>(),
      isGroup: fields[12] as bool,
      groupName: fields[13] as String?,
      groupAvatarUrl: fields[14] as String?,
      createdBy: fields[15] as String?,
      admins: (fields[16] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Conversation obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.participants)
      ..writeByte(2)
      ..write(obj.participantNames)
      ..writeByte(3)
      ..write(obj.lastMessageId)
      ..writeByte(4)
      ..write(obj.lastMessageContent)
      ..writeByte(5)
      ..write(obj.lastMessageSenderId)
      ..writeByte(6)
      ..write(obj.lastMessageTimestamp)
      ..writeByte(7)
      ..write(obj.isActive)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.readStatus)
      ..writeByte(11)
      ..write(obj.unreadCounts)
      ..writeByte(12)
      ..write(obj.isGroup)
      ..writeByte(13)
      ..write(obj.groupName)
      ..writeByte(14)
      ..write(obj.groupAvatarUrl)
      ..writeByte(15)
      ..write(obj.createdBy)
      ..writeByte(16)
      ..write(obj.admins);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
