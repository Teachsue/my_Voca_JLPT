import 'package:flutter/material.dart';
import '../model/word.dart';
import '../service/database_service.dart';

class StudyViewModel extends ChangeNotifier {
  List<Word> _words = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _isAnswered = false;
  bool _isCorrect = false;
  String? _selectedAnswer;
  List<String> _currentOptions = [];

  // Getters
  Word? get currentWord => (_words.isNotEmpty && _currentIndex < _words.length)
      ? _words[_currentIndex]
      : null;
  List<String> get currentOptions => _currentOptions;
  bool get isAnswered => _isAnswered;
  bool get isCorrect => _isCorrect;
  String? get selectedAnswer => _selectedAnswer;
  int get score => _score;
  int get total => _words.length;
  int get currentIndex => _currentIndex;
  bool get isFinished => _words.isNotEmpty && _currentIndex >= _words.length;

  Future<void> loadWords(int level) async {
    final allWords = DatabaseService.getWordsByLevel(level);
    allWords.shuffle();
    
    // 세션당 10개만 학습하도록 제한 (참조 앱 스타일)
    _words = allWords.take(10).toList();
    
    _currentIndex = 0;
    _score = 0;
    _isAnswered = false;
    if (_words.isNotEmpty) _generateOptions();
    notifyListeners();
  }

  void _generateOptions() {
    if (currentWord == null) return;
    final correct = currentWord!.meaning;
    final allWords = DatabaseService.getWordsByLevel(currentWord!.level);

    final distractors = allWords
        .where((w) => w.meaning != correct)
        .map((w) => w.meaning)
        .toList();
    distractors.shuffle();

    _currentOptions = [correct, ...distractors.take(3)];
    _currentOptions.shuffle();
  }

  void submitAnswer(String answer) {
    if (_isAnswered || currentWord == null) return;
    _isAnswered = true;
    _selectedAnswer = answer;

    if (answer == currentWord!.meaning) {
      _isCorrect = true;
      _score++;
      currentWord!.correctCount++;
    } else {
      _isCorrect = false;
      currentWord!.incorrectCount++;
    }
    currentWord!.save();
    notifyListeners();
  }

  void nextQuestion() {
    _currentIndex++;
    _isAnswered = false;
    _selectedAnswer = null;
    if (!isFinished) _generateOptions();
    notifyListeners();
  }

  void restart() {
    _words.shuffle();
    _currentIndex = 0;
    _score = 0;
    _isAnswered = false;
    _generateOptions();
    notifyListeners();
  }
}
