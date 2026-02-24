// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WordAdapter extends TypeAdapter<Word> {
  @override
  final int typeId = 1;

  @override
  Word read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Word(
      id: fields[0] as int,
      kanji: fields[1] as String,
      kana: fields[2] as String,
      meaning: fields[3] as String,
      level: fields[4] as int,
      koreanPronunciation: fields[5] as String,
      correctCount: fields[6] as int,
      incorrectCount: fields[7] as int,
      isMemorized: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Word obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.kanji)
      ..writeByte(2)
      ..write(obj.kana)
      ..writeByte(3)
      ..write(obj.meaning)
      ..writeByte(4)
      ..write(obj.level)
      ..writeByte(5)
      ..write(obj.koreanPronunciation)
      ..writeByte(6)
      ..write(obj.correctCount)
      ..writeByte(7)
      ..write(obj.incorrectCount)
      ..writeByte(8)
      ..write(obj.isMemorized);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
