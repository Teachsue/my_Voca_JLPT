import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:math';
import '../model/word.dart';
import '../service/database_service.dart';

enum LevelTestType { kanjiToMeaning, meaningToKanji, meaningToKana }

class LevelTestViewModel extends ChangeNotifier {
  List<Word> _questions = [];
  List<LevelTestType> _testTypes = [];
  int _currentIndex = 0;
  bool _isFinished = false;

  final Map<int, int> _correctCountsPerLevel = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
  int _totalCorrect = 0;

  bool _isAnswered = false;
  String? _selectedAnswer;
  List<String> _currentOptions = [];

  // Getters
  Word? get currentWord => (_questions.isNotEmpty && _currentIndex < _questions.length) ? _questions[_currentIndex] : null;
  LevelTestType? get currentType => (_testTypes.isNotEmpty && _currentIndex < _testTypes.length) ? _testTypes[_currentIndex] : null;
  int get currentIndex => _currentIndex;
  int get totalQuestions => _questions.length;
  bool get isFinished => _isFinished;
  bool get isAnswered => _isAnswered;
  String? get selectedAnswer => _selectedAnswer;
  List<String> get currentOptions => _currentOptions;

  Future<void> initTest() async {
    _questions = [];
    _currentIndex = 0;
    _isFinished = false;
    _totalCorrect = 0;
    _correctCountsPerLevel.updateAll((key, value) => 0);

    // 단어 추출
    _questions.addAll(_getRandomWords(1, 5));
    _questions.addAll(_getRandomWords(2, 5));
    _questions.addAll(_getRandomWords(3, 5));
    _questions.addAll(_getRandomWords(4, 5));
    _questions.addAll(_getRandomWords(5, 10));

    _questions.shuffle();
    
    // 문제 유형 랜덤 생성
    _testTypes = List.generate(_questions.length, (_) => LevelTestType.values[Random().nextInt(LevelTestType.values.length)]);
    
    _generateOptions();
    notifyListeners();
  }

  List<Word> _getRandomWords(int level, int count) {
    final allWords = DatabaseService.getWordsByLevel(level);
    allWords.shuffle();
    return allWords.take(count).toList();
  }

  void _generateOptions() {
    if (currentWord == null || currentType == null) return;
    
    String correct;
    switch (currentType!) {
      case LevelTestType.kanjiToMeaning: correct = currentWord!.meaning; break;
      case LevelTestType.meaningToKanji: correct = currentWord!.kanji; break;
      case LevelTestType.meaningToKana: correct = currentWord!.kana; break;
    }

    final allWords = DatabaseService.getWordsByLevel(currentWord!.level);
    Set<String> distractors = {};
    
    var pool = List<Word>.from(allWords)..shuffle();
    for (var w in pool) {
      if (distractors.length >= 3) break;
      String val;
      switch (currentType!) {
        case LevelTestType.kanjiToMeaning: val = w.meaning; break;
        case LevelTestType.meaningToKanji: val = w.kanji; break;
        case LevelTestType.meaningToKana: val = w.kana; break;
      }
      if (val != correct) distractors.add(val);
    }

    _currentOptions = [correct, ...distractors];
    _currentOptions.shuffle();
  }

  void submitAnswer(String answer) {
    if (_isAnswered) return;
    _isAnswered = true;
    _selectedAnswer = answer;

    String correct;
    switch (currentType!) {
      case LevelTestType.kanjiToMeaning: correct = currentWord!.meaning; break;
      case LevelTestType.meaningToKanji: correct = currentWord!.kanji; break;
      case LevelTestType.meaningToKana: correct = currentWord!.kana; break;
    }

    if (answer == correct) {
      _totalCorrect++;
      _correctCountsPerLevel[currentWord!.level] = (_correctCountsPerLevel[currentWord!.level] ?? 0) + 1;
    }
    notifyListeners();
  }

  void nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
      _isAnswered = false;
      _selectedAnswer = null;
      _generateOptions();
    } else {
      _isFinished = true;
      _saveResult();
    }
    notifyListeners();
  }

  String _calculateResult() {
    if (_totalCorrect >= 25) return 'N1';
    if (_totalCorrect >= 20) return 'N2';
    if (_totalCorrect >= 15) return 'N3';
    if (_totalCorrect >= 10) return 'N4';
    return 'N5';
  }

  void _saveResult() {
    final result = _calculateResult();
    final box = Hive.box(DatabaseService.sessionBoxName);
    box.put('recommended_level', result);
  }

  String get recommendedLevel => _calculateResult();
  int get totalCorrect => _totalCorrect;
}
