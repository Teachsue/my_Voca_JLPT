import 'package:hive/hive.dart';

part 'word.g.dart';

@HiveType(typeId: 1)
class Word extends HiveObject {
  @HiveField(0)
  final int id;
  @HiveField(1)
  final String kanji;
  @HiveField(2)
  final String kana;
  @HiveField(3)
  final String meaning;
  @HiveField(4)
  final int level;
  @HiveField(5)
  final String koreanPronunciation;

  @HiveField(6)
  int correctCount;
  @HiveField(7)
  int incorrectCount;
  @HiveField(8)
  bool isMemorized;

  @HiveField(9)
  bool isBookmarked;

  Word({
    required this.id,
    required this.kanji,
    required this.kana,
    required this.meaning,
    required this.level,
    required this.koreanPronunciation,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.isMemorized = false,
    this.isBookmarked = false,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    // level 필드가 "1", 1, "N1" 등 다양할 수 있으므로 숫지만 추출하여 파싱
    String levelStr = (json['level'] ?? '0').toString().replaceAll(RegExp(r'[^0-9]'), '');
    int levelInt = int.tryParse(levelStr) ?? 0;

    return Word(
      id: (json['id'] as int?) ?? 0,
      kanji: (json['kanji'] as String?) ?? '',
      kana: (json['kana'] as String?) ?? '',
      // JSON의 스네이크 케이스 키값을 모델의 카멜 케이스 필드에 매핑
      koreanPronunciation: (json['korean_pronunciation'] as String?) ?? '',
      meaning: (json['meaning'] as String?) ?? '',
      level: levelInt,
      isBookmarked: false,
    );
  }
}
