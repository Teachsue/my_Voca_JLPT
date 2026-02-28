import 'dart:convert';
import 'package:flutter/foundation.dart';
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
    final sessionBox = await Hive.openBox(sessionBoxName);

    // 구버전 데이터 보정: 'N5 미만' 기록이 있다면 'N5'로 변경
    if (sessionBox.get('recommended_level') == 'N5 미만') {
      await sessionBox.put('recommended_level', 'N5');
    }
  }

  // 앱 최초 실행 시 JSON 데이터를 Hive DB로 옮기는 함수
  static Future<void> loadJsonToHive(int level) async {
    var box = Hive.box<Word>(boxName);

    // 해당 레벨의 단어 개수를 확인
    int existingCount = box.values.where((w) => w.level.toString() == level.toString()).length;
    
    // 히라가나/가타카나는 개수가 적으므로 체크 기준 완화 (기본 46자 이상이면 로드된 것으로 간주)
    int threshold = (level >= 11) ? 40 : 100;
    
    if (existingCount >= threshold) {
      debugPrint("✅ Level $level 데이터가 이미 존재합니다. (개수: $existingCount)");
      return;
    }

    debugPrint("⏳ Level $level 데이터를 로드 중...");
    try {
      String fileName;
      if (level == 11) {
        fileName = 'hiragana.json';
      } else if (level == 12) {
        fileName = 'katakana.json';
      } else {
        fileName = 'n$level.json';
      }

      final String response = await rootBundle.loadString('assets/data/$fileName');
      
      // 무거운 연산을 별도 Isolate에서 수행 (메인 스레드 프리징 방지)
      final Map<String, Word> wordMap = await compute(_parseWords, {'jsonString': response, 'level': level});
      
      await box.putAll(wordMap);
      debugPrint("✅ Level $level 로드 완료! (총 ${wordMap.length}단어)");
    } catch (e) {
      debugPrint("❌ 데이터 로드 에러 (Level $level): $e");
    }
  }

  // Isolate에서 실행될 파싱 함수
  static Map<String, Word> _parseWords(Map<String, dynamic> params) {
    final String jsonString = params['jsonString'];
    final int level = params['level'];
    
    final Map<String, dynamic> data = json.decode(jsonString);
    final List<dynamic> vocabulary = data['vocabulary'];

    Map<String, Word> wordMap = {};
    for (var item in vocabulary) {
      // JSON 데이터를 Word 객체로 변환
      final word = Word.fromJson(item);
      final fixedWord = Word(
        id: word.id,
        kanji: word.kanji,
        kana: word.kana,
        meaning: word.meaning,
        level: level,
        koreanPronunciation: word.koreanPronunciation,
      );
      wordMap['${level}_${fixedWord.id}'] = fixedWord;
    }
    return wordMap;
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
