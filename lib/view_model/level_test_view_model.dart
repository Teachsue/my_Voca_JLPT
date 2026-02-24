import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../model/word.dart';
import '../service/database_service.dart';

class LevelTestViewModel extends ChangeNotifier {
  List<Word> _questions = [];
  int _currentIndex = 0;
  bool _isFinished = false;

  // 레벨별 맞은 개수 추적
  final Map<int, int> _correctCountsPerLevel = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
  int _totalCorrect = 0;

  bool _isAnswered = false;
  String? _selectedAnswer;
  List<String> _currentOptions = [];

  // Getters
  Word? get currentWord =>
      (_questions.isNotEmpty && _currentIndex < _questions.length)
      ? _questions[_currentIndex]
      : null;
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

    // 단어 추출: N1(5), N2(5), N3(5), N4(5), N5(10)
    _questions.addAll(_getRandomWords(1, 5));
    _questions.addAll(_getRandomWords(2, 5));
    _questions.addAll(_getRandomWords(3, 5));
    _questions.addAll(_getRandomWords(4, 5));
    _questions.addAll(_getRandomWords(5, 10));

    _questions.shuffle(); // 전체 문제 섞기
    _generateOptions();
    notifyListeners();
  }

  List<Word> _getRandomWords(int level, int count) {
    final allWords = DatabaseService.getWordsByLevel(level);
    allWords.shuffle();
    return allWords.take(count).toList();
  }

  void _generateOptions() {
    if (currentWord == null) return;
    final correct = currentWord!.meaning;
    final allWords = DatabaseService.getWordsByLevel(currentWord!.level);
    final distractors = allWords
        .where((w) => w.meaning != correct)
        .map((w) => w.meaning)
        .toSet()
        .toList();
    distractors.shuffle();
    _currentOptions = [correct, ...distractors.take(3)];
    _currentOptions.shuffle();
  }

  void submitAnswer(String answer) {
    if (_isAnswered) return;
    _isAnswered = true;
    _selectedAnswer = answer;

    if (answer == currentWord!.meaning) {
      _totalCorrect++;
      _correctCountsPerLevel[currentWord!.level] =
          (_correctCountsPerLevel[currentWord!.level] ?? 0) + 1;
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
    final n1 = _correctCountsPerLevel[1] ?? 0;
    final n2 = _correctCountsPerLevel[2] ?? 0;
    final n3 = _correctCountsPerLevel[3] ?? 0;
    final n4 = _correctCountsPerLevel[4] ?? 0;
    final n5 = _correctCountsPerLevel[5] ?? 0;

    if (n1 >= 3 &&
        n2 >= 4 &&
        n3 >= 4 &&
        n4 >= 4 &&
        n5 >= 8 &&
        _totalCorrect >= 23)
      return 'N1';
    if (n2 >= 3 && n3 >= 3 && n4 >= 4 && n5 >= 7 && _totalCorrect >= 20)
      return 'N2';
    if (n3 >= 3 && n4 >= 3 && n5 >= 6 || _totalCorrect >= 15) return 'N3';
    if (n4 >= 3 && n5 >= 6 || _totalCorrect >= 10) return 'N4';

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
