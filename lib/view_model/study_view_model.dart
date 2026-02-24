import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:math';
import '../model/word.dart';
import '../service/database_service.dart';

enum QuizType { kanjiToMeaning, meaningToKanji, meaningToKana }

class StudyViewModel extends ChangeNotifier {
  List<Word> _words = [];
  List<QuizType> _quizTypes = []; // 각 문제의 유형 저장
  int _currentIndex = 0;
  int _score = 0;
  bool _isAnswered = false;
  bool _isCorrect = false;
  String? _selectedAnswer;
  List<Word> _currentOptionWords = [];
  List<String?> _userAnswers = [];
  String? _currentSessionKey;

  // Getters
  Word? get currentWord => (_words.isNotEmpty && _currentIndex < _words.length) ? _words[_currentIndex] : null;
  QuizType? get currentQuizType => (_quizTypes.isNotEmpty && _currentIndex < _quizTypes.length) ? _quizTypes[_currentIndex] : null;
  List<Word> get currentOptionWords => _currentOptionWords;
  List<String?> get userAnswers => _userAnswers;
  List<Word> get sessionWords => _words;
  bool get isAnswered => _isAnswered;
  bool get isCorrect => _isCorrect;
  String? get selectedAnswer => _selectedAnswer;
  int get score => _score;
  int get total => _words.length;
  int get currentIndex => _currentIndex;
  bool get isFinished => _words.isNotEmpty && _currentIndex >= _words.length;

  String _generateSessionKey(int level, int? day) {
    return day == null ? 'quiz_level_$level' : 'quiz_level_${level}_day_$day';
  }

  Map<String, dynamic>? getSavedSession(int level, int? day) {
    final box = Hive.box(DatabaseService.sessionBoxName);
    final key = _generateSessionKey(level, day);
    final data = box.get(key);
    if (data != null && data['currentIndex'] > 0) return Map<String, dynamic>.from(data);
    return null;
  }

  Future<void> loadWords(int level, {int? questionCount, int? day, List<Word>? initialWords}) async {
    _currentSessionKey = _generateSessionKey(level, day);
    
    // 새로 시작하므로 기존에 저장된 해당 세션 기록을 삭제
    _clearSession();
    
    if (initialWords != null) {
      _words = List<Word>.from(initialWords)..shuffle();
    } else {
      final allWords = DatabaseService.getWordsByLevel(level);
      allWords.shuffle();
      int count = questionCount ?? 10;
      _words = allWords.take(count).toList();
    }
    
    // 문제 유형 랜덤 배정
    _quizTypes = List.generate(_words.length, (_) => QuizType.values[Random().nextInt(QuizType.values.length)]);
    
    _currentIndex = 0;
    _score = 0;
    _isAnswered = false;
    _userAnswers = List.filled(_words.length, null);
    if (_words.isNotEmpty) _generateOptions();
    notifyListeners();
  }

  // 오늘의 단어 로드
  Future<List<Word>> loadTodaysWords() async {
    final box = Hive.box(DatabaseService.sessionBoxName);
    final today = DateTime.now().toString().split(' ')[0];
    final sessionKey = 'todays_words_$today';
    
    final savedIds = box.get(sessionKey);
    final wordsBox = Hive.box<Word>(DatabaseService.boxName);
    List<Word> todaysWords = [];

    if (savedIds != null) {
      final List<int> ids = List<int>.from(savedIds);
      final allWords = wordsBox.values.toList();
      for (var id in ids) {
        try {
          todaysWords.add(allWords.firstWhere((w) => w.id == id));
        } catch (e) {}
      }
    }

    if (todaysWords.isEmpty) {
      final allWords = wordsBox.values.toList();
      allWords.shuffle();
      todaysWords = allWords.take(10).toList();
      box.put(sessionKey, todaysWords.map((w) => w.id).toList());
    }

    return todaysWords;
  }

  void resumeSession(Map<String, dynamic> sessionData) {
    final wordIds = List<int>.from(sessionData['wordIds']);
    final box = Hive.box<Word>(DatabaseService.boxName);
    
    _words = [];
    final allWords = box.values.toList();
    for (var id in wordIds) {
      try {
        _words.add(allWords.firstWhere((w) => w.id == id));
      } catch (e) {}
    }

    // 유형 복구 (없으면 랜덤 생성)
    if (sessionData['quizTypes'] != null) {
      _quizTypes = (sessionData['quizTypes'] as List).map((e) => QuizType.values[e]).toList();
    } else {
      _quizTypes = List.generate(_words.length, (_) => QuizType.values[Random().nextInt(QuizType.values.length)]);
    }

    _currentIndex = sessionData['currentIndex'];
    _score = sessionData['score'];
    _currentSessionKey = sessionData['sessionKey'];
    
    if (sessionData['userAnswers'] != null) {
      _userAnswers = List<String?>.from(sessionData['userAnswers']);
    } else {
      _userAnswers = List.filled(_words.length, null);
    }

    _isAnswered = false;
    _selectedAnswer = null;
    
    if (_words.isNotEmpty && !isFinished) _generateOptions();
    notifyListeners();
  }

  void _generateOptions() {
    if (currentWord == null || currentQuizType == null) return;
    final correctWord = currentWord!;
    final type = currentQuizType!;
    
    List<Word> allWords;
    if (correctWord.level == 0 || correctWord.level < 1) {
      allWords = Hive.box<Word>(DatabaseService.boxName).values.toList();
    } else {
      allWords = DatabaseService.getWordsByLevel(correctWord.level);
    }

    // 유형별로 중복되지 않는 보기 추출 로직
    final distractors = allWords.where((w) {
      if (w.id == correctWord.id) return false;
      switch (type) {
        case QuizType.kanjiToMeaning: return w.meaning != correctWord.meaning;
        case QuizType.meaningToKanji: return w.kanji != correctWord.kanji;
        case QuizType.meaningToKana: return w.kana != correctWord.kana;
      }
    }).toList();
    
    distractors.shuffle();
    _currentOptionWords = [correctWord, ...distractors.take(3)];
    _currentOptionWords.shuffle();
  }

  void submitAnswer(String answer) {
    if (_isAnswered || currentWord == null) return;
    _isAnswered = true;
    _selectedAnswer = answer;
    _userAnswers[_currentIndex] = answer;

    // 유형에 따른 정답 체크
    bool correct = false;
    switch (currentQuizType!) {
      case QuizType.kanjiToMeaning: correct = answer == currentWord!.meaning; break;
      case QuizType.meaningToKanji: correct = answer == currentWord!.kanji; break;
      case QuizType.meaningToKana: correct = answer == currentWord!.kana; break;
    }

    if (correct) {
      _isCorrect = true;
      _score++;
      currentWord!.correctCount++;
    } else {
      _isCorrect = false;
      currentWord!.incorrectCount++;
    }
    currentWord!.save();
    _updateDailyStudyCount();
    _saveCurrentSession();
    notifyListeners();
  }

  void _updateDailyStudyCount() {
    final box = Hive.box(DatabaseService.sessionBoxName);
    final today = DateTime.now().toString().split(' ')[0];
    final currentCount = box.get('study_count_$today', defaultValue: 0);
    box.put('study_count_$today', currentCount + 1);
  }

  void _saveCurrentSession() {
    if (_currentSessionKey == null || _words.isEmpty) return;
    final box = Hive.box(DatabaseService.sessionBoxName);
    box.put(_currentSessionKey, {
      'sessionKey': _currentSessionKey,
      'wordIds': _words.map((w) => w.id).toList(),
      'quizTypes': _quizTypes.map((e) => e.index).toList(), // 유형 인덱스 저장
      'currentIndex': _currentIndex,
      'score': _score,
      'userAnswers': _userAnswers,
    });
  }

  void nextQuestion() {
    _currentIndex++;
    _isAnswered = false;
    _selectedAnswer = null;
    if (!isFinished) {
      _generateOptions();
      _saveCurrentSession();
    } else {
      _clearSession();
    }
    notifyListeners();
  }

  void _clearSession() {
    if (_currentSessionKey != null) Hive.box(DatabaseService.sessionBoxName).delete(_currentSessionKey);
  }

  void markTodaysWordsAsCompleted() {
    final box = Hive.box(DatabaseService.sessionBoxName);
    final today = DateTime.now().toString().split(' ')[0];
    box.put('todays_words_completed_$today', true);
  }

  void restart() {
    _clearSession();
    _words.shuffle();
    // 다시 시작할 때 유형도 랜덤 재배정
    _quizTypes = List.generate(_words.length, (_) => QuizType.values[Random().nextInt(QuizType.values.length)]);
    _currentIndex = 0;
    _score = 0;
    _isAnswered = false;
    _generateOptions();
    notifyListeners();
  }
}
