import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../model/word.dart';

class DatabaseService {
  static const String boxName = 'wordsBox';
  static const String sessionBoxName = 'sessionBox';

  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(WordAdapter());
    }
    await Hive.openBox<Word>(boxName);
    await Hive.openBox(sessionBoxName);
  }

  // 앱 최초 실행 시 JSON 데이터를 Hive DB로 옮기는 함수
  static Future<void> loadJsonToHive(int level) async {
    var box = Hive.box<Word>(boxName);

    // 해당 레벨의 단어 개수를 확인 (문자열 변환 후 비교하여 타입 불일치 방지)
    int existingCount = box.values.where((w) => w.level.toString() == level.toString()).length;
    if (existingCount > 100) {
      print("✅ N$level 데이터가 이미 존재합니다. (개수: $existingCount)");
      return;
    }

    print("⏳ N$level 데이터를 로드 중...");
    try {
      final String response = await rootBundle.loadString(
        'assets/data/n$level.json',
      );
      final Map<String, dynamic> data = json.decode(response);
      List<dynamic> vocabulary = data['vocabulary'];

      Map<String, Word> wordMap = {};
      for (var item in vocabulary) {
        // JSON 데이터의 level 필드를 무시하고 호출 시 인자로 받은 level을 강제 적용
        final word = Word.fromJson(item);
        final fixedWord = Word(
          id: word.id,
          kanji: word.kanji,
          kana: word.kana,
          meaning: word.meaning,
          level: level, // 여기서 level 강제 지정
          koreanPronunciation: word.koreanPronunciation,
        );
        wordMap['${level}_${fixedWord.id}'] = fixedWord;
      }
      
      await box.putAll(wordMap);
      print("✅ N$level 로드 완료! (총 ${wordMap.length}단어)");
    } catch (e) {
      print("❌ 데이터 로드 에러 (N$level): $e");
    }
  }

  static bool needsInitialLoading() {
    var box = Hive.box<Word>(boxName);
    return box.isEmpty;
  }

  static List<Word> getWordsByLevel(int level) {
    var box = Hive.box<Word>(boxName);
    // 타입 불일치 방지를 위해 문자열로 변환하여 비교
    return box.values.where((w) => w.level.toString() == level.toString()).toList();
  }
}
