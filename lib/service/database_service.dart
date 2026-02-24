import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../model/word.dart';

class DatabaseService {
  static const String boxName = 'wordsBox';

  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(WordAdapter());
    }
    await Hive.openBox<Word>(boxName);
  }

  // 앱 최초 실행 시 JSON 데이터를 Hive DB로 옮기는 함수
  static Future<void> loadJsonToHive(int level) async {
    var box = Hive.box<Word>(boxName);

    // 해당 레벨 데이터가 이미 있으면 중복 로드 방지
    if (box.values.any((w) => w.level == level)) return;

    try {
      final String response = await rootBundle.loadString(
        'assets/data/n$level.json',
      );
      final Map<String, dynamic> data = json.decode(response);
      List<dynamic> vocabulary = data['vocabulary'];

      for (var item in vocabulary) {
        final word = Word.fromJson(item);
        await box.put('${level}_${word.id}', word); // 유니크한 키로 저장
      }
    } catch (e) {
      print("❌ 데이터 로드 에러 (N$level): $e");
    }
  }

  static List<Word> getWordsByLevel(int level) {
    var box = Hive.box<Word>(boxName);
    return box.values.where((w) => w.level == level).toList();
  }
}
