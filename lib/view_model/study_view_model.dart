import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
  String? _currentSessionKey;

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

  // 세션 키 생성 (레벨 + DAY 혹은 레벨 전용)
  String _generateSessionKey(int level, int? day) {
    return day == null ? 'quiz_level_$level' : 'quiz_level_${level}_day_$day';
  }

  // 저장된 세션이 있는지 확인 (1문제 초과로 풀었을 때만)
  Map<String, dynamic>? getSavedSession(int level, int? day) {
    final box = Hive.box(DatabaseService.sessionBoxName);
    final key = _generateSessionKey(level, day);
    final data = box.get(key);
    if (data != null && data['currentIndex'] > 0) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  Future<void> loadWords(int level, {int? questionCount, int? day, List<Word>? initialWords}) async {
    _currentSessionKey = _generateSessionKey(level, day);
    
    if (initialWords != null) {
      // 특정 DAY 단어들로 퀴즈 (랜덤 섞기)
      _words = List<Word>.from(initialWords)..shuffle();
    } else {
      // 레벨 전체 단어들 중 랜덤 추출
      final allWords = DatabaseService.getWordsByLevel(level);
      allWords.shuffle();
      int count = questionCount ?? 10;
      _words = allWords.take(count).toList();
    }
    
    _currentIndex = 0;
    _score = 0;
    _isAnswered = false;
    if (_words.isNotEmpty) _generateOptions();
    notifyListeners();
  }

  // 세션 복구
  void resumeSession(Map<String, dynamic> sessionData) {
    final wordIds = List<int>.from(sessionData['wordIds']);
    final box = Hive.box<Word>(DatabaseService.boxName);
    
    // ID로 단어 복구
    _words = [];
    final allWords = box.values.toList();
    for (var id in wordIds) {
      try {
        _words.add(allWords.firstWhere((w) => w.id == id));
      } catch (e) {}
    }

    _currentIndex = sessionData['currentIndex'];
    _score = sessionData['score'];
    _currentSessionKey = sessionData['sessionKey'];
    _isAnswered = false;
    _selectedAnswer = null;
    
    if (_words.isNotEmpty && !isFinished) {
      _generateOptions();
    }
    notifyListeners();
  }

  void _generateOptions() {
    if (currentWord == null) return;
    final correct = currentWord!.meaning;
    // 오답 보기는 해당 레벨 전체에서 가져옴
    final allWords = DatabaseService.getWordsByLevel(currentWord!.level);

    final distractors = allWords
        .where((w) => w.meaning != correct)
        .map((w) => w.meaning)
        .toSet() // 중복 제거
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
    
    // 퀴즈 진행 상황 저장 (1문제 이상 풀었을 때)
    _saveCurrentSession();
    
    notifyListeners();
  }

  void _saveCurrentSession() {
    if (_currentSessionKey == null || _words.isEmpty) return;
    final box = Hive.box(DatabaseService.sessionBoxName);
    box.put(_currentSessionKey, {
      'sessionKey': _currentSessionKey,
      'wordIds': _words.map((w) => w.id).toList(),
      'currentIndex': _currentIndex,
      'score': _score,
    });
  }

  void nextQuestion() {
    _currentIndex++;
    _isAnswered = false;
    _selectedAnswer = null;
    
    if (!isFinished) {
      _generateOptions();
      _saveCurrentSession(); // 다음 문제로 넘어갈 때 인덱스 업데이트
    } else {
      // 퀴즈 종료 시 세션 삭제
      _clearSession();
    }
    notifyListeners();
  }

  void _clearSession() {
    if (_currentSessionKey != null) {
      Hive.box(DatabaseService.sessionBoxName).delete(_currentSessionKey);
    }
  }

  void restart() {
    _clearSession();
    _words.shuffle();
    _currentIndex = 0;
    _score = 0;
    _isAnswered = false;
    _generateOptions();
    notifyListeners();
  }
}
