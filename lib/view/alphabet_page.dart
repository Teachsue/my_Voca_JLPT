import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../model/word.dart';
import '../service/database_service.dart';
import 'quiz_page.dart';

class AlphabetPage extends StatefulWidget {
  final String title;
  final int level;

  const AlphabetPage({super.key, required this.title, required this.level});

  @override
  State<AlphabetPage> createState() => _AlphabetPageState();
}

class _AlphabetPageState extends State<AlphabetPage> {
  List<Word> _allWords = [];
  final List<String> _rowNames = ['あ(아)행', 'か(카)행', 'さ(사)행', 'た(타)행', '나(나)행', '하(하)행', '마(마)행', '야(야)행', '라(라)행', '와(와)행', 'ん(응)'];

  @override
  void initState() {
    super.initState();
    _ensureDataAndLoad();
  }

  Future<void> _ensureDataAndLoad() async {
    _allWords = DatabaseService.getWordsByLevel(widget.level);
    if (_allWords.isEmpty) {
      await DatabaseService.loadJsonToHive(widget.level);
      _allWords = DatabaseService.getWordsByLevel(widget.level);
    }
    _allWords.sort((a, b) => a.id.compareTo(b.id));
    if (mounted) setState(() {});
  }

  List<List<Word>> _getGroupedWords() {
    List<List<Word>> groups = [];
    for (int i = 0; i < _allWords.length; i += 5) {
      int end = (i + 5 < _allWords.length) ? i + 5 : _allWords.length;
      groups.add(_allWords.sublist(i, end));
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final groupedWords = _getGroupedWords();
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('${widget.title} 학습', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.fact_check_rounded, color: isDarkMode ? Colors.white70 : const Color(0xFF5B86E5), size: 28),
            onPressed: () => _showQuizConfigDialog(),
            tooltip: '전체 퀴즈',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _allWords.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF5B86E5)))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                _buildStudyGuide(isDarkMode),
                const SizedBox(height: 25),
                ...List.generate(groupedWords.length, (index) {
                  return _buildRowSection(
                    _rowNames[index < _rowNames.length ? index : _rowNames.length - 1],
                    groupedWords[index],
                    isDarkMode
                  );
                }),
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _buildStudyGuide(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.05) : const Color(0xFF5B86E5).withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDarkMode ? Colors.white10 : const Color(0xFF5B86E5).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_rounded, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                '${widget.title} 공부법',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDarkMode ? Colors.orangeAccent : const Color(0xFF5B86E5)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '1. 한 행(5글자)씩 소리 내어 읽어보세요.\n2. 글자의 모양과 발음을 연결하며 눈에 익힙니다.\n3. 각 행 옆의 퀴즈 버튼으로 방금 배운 글자를 확인하세요.',
            style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white60 : Colors.blueGrey, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildRowSection(String title, List<Word> words, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDarkMode ? Colors.white : const Color(0xFF2D3142)),
              ),
              TextButton.icon(
                onPressed: () => _startQuiz(words, '$title 집중 퀴즈'),
                icon: const Icon(Icons.play_circle_filled_rounded, size: 18),
                label: const Text('집중 퀴즈', style: TextStyle(fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(foregroundColor: isDarkMode ? Colors.white70 : const Color(0xFF5B86E5)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 120, // 높이 최적화
          child: Row(
            children: words.map((word) => Expanded(child: _buildAlphabetCard(word, isDarkMode))).toList(),
          ),
        ),
        const SizedBox(height: 10),
        Divider(height: 30, color: isDarkMode ? Colors.white10 : Colors.grey[200]),
      ],
    );
  }

  Widget _buildAlphabetCard(Word word, bool isDarkMode) {
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF2D3142);
    final Color subColor = isDarkMode ? Colors.white70 : const Color(0xFF5B86E5);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.12) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDarkMode ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Center(
              child: FittedBox(
                child: Text(
                  word.kanji,
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: textColor),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  word.meaning,
                  style: TextStyle(fontSize: 13, color: subColor, fontWeight: FontWeight.bold),
                ),
                Text(
                  word.kana.toUpperCase(),
                  style: TextStyle(fontSize: 9, color: isDarkMode ? Colors.white38 : Colors.grey[400], fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startQuiz(List<Word> quizWords, String quizTitle, {int? count}) {
    if (quizWords.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizPage(
          level: quizTitle,
          questionCount: count ?? quizWords.length,
          day: null,
          initialWords: quizWords.toList()..shuffle(),
        ),
      ),
    );
  }

  void _showQuizConfigDialog() {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF2D3436) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('퀴즈 설정', style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87)),
        content: Text('풀고 싶은 문제 수를 선택해주세요.', style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                _buildConfigOption('10문제', 10, isDarkMode),
                _buildConfigOption('20문제', 20, isDarkMode),
                _buildConfigOption('30문제', 30, isDarkMode),
                _buildConfigOption('전체 풀기 (${_allWords.length}문제)', _allWords.length, isDarkMode),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('취소', style: TextStyle(color: isDarkMode ? Colors.white38 : Colors.grey, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigOption(String label, int count, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () {
            Navigator.pop(context);
            _startQuiz(_allWords, widget.title, count: count);
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: BorderSide(color: isDarkMode ? Colors.white24 : const Color(0xFF5B86E5), width: 1.5),
            foregroundColor: isDarkMode ? Colors.white : const Color(0xFF5B86E5),
          ),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }
}
