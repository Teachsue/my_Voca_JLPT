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
  List<Word> _currentOptionWords = [];
  List<String?> _userAnswers = []; // 사용자가 선택한 답변 이력 저장
  String? _currentSessionKey;

  // Getters
  Word? get currentWord => (_words.isNotEmpty && _currentIndex < _words.length)
      ? _words[_currentIndex]
      : null;
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
    if (data != null && data['currentIndex'] > 0)
      return Map<String, dynamic>.from(data);
    return null;
  }

  Future<void> loadWords(
    int level, {
    int? questionCount,
    int? day,
    List<Word>? initialWords,
  }) async {
    _currentSessionKey = _generateSessionKey(level, day);

    if (initialWords != null) {
      _words = List<Word>.from(initialWords)..shuffle();
    } else {
      final allWords = DatabaseService.getWordsByLevel(level);
      allWords.shuffle();
      int count = questionCount ?? 10;
      _words = allWords.take(count).toList();
    }

    _currentIndex = 0;
    _score = 0;
    _isAnswered = false;
    _userAnswers = List.filled(_words.length, null); // 이력 초기화
    if (_words.isNotEmpty) _generateOptions();
    notifyListeners();
  }

  // 오늘의 단어 로드 (전체 레벨 랜덤 10개)
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

    _currentIndex = sessionData['currentIndex'];
    _score = sessionData['score'];
    _currentSessionKey = sessionData['sessionKey'];

    // 저장된 답변 이력이 있으면 복구, 없으면 새로 생성
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
    if (currentWord == null) return;
    final correctWord = currentWord!;

    // 레벨이 0(오늘의 단어)이면 전체에서, 아니면 해당 레벨에서 보기를 가져옴
    List<Word> allWords;
    if (correctWord.level == 0 || correctWord.level < 1) {
      allWords = Hive.box<Word>(DatabaseService.boxName).values.toList();
    } else {
      allWords = DatabaseService.getWordsByLevel(correctWord.level);
    }

    final distractors = allWords
        .where(
          (w) => w.id != correctWord.id && w.meaning != correctWord.meaning,
        )
        .toList();
    distractors.shuffle();

    _currentOptionWords = [correctWord, ...distractors.take(3)];
    _currentOptionWords.shuffle();
  }

  void submitAnswer(String answer) {
    if (_isAnswered || currentWord == null) return;
    _isAnswered = true;
    _selectedAnswer = answer;
    _userAnswers[_currentIndex] = answer; // 답변 저장

    if (answer == currentWord!.meaning) {
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
      'currentIndex': _currentIndex,
      'score': _score,
      'userAnswers': _userAnswers, // 선택 이력 추가 저장
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
    if (_currentSessionKey != null)
      Hive.box(DatabaseService.sessionBoxName).delete(_currentSessionKey);
  }

  // 오늘의 단어 학습 완료 기록
  void markTodaysWordsAsCompleted() {
    final box = Hive.box(DatabaseService.sessionBoxName);
    final today = DateTime.now().toString().split(' ')[0];
    box.put('todays_words_completed_$today', true);
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
