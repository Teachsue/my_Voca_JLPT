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
  final List<String> _rowNames = ['あ(아)행', 'か(카)행', 'さ(사)행', 'た(타)행', 'な(나)행', 'は(하)행', 'ま(마)행', 'や(야)행', 'ら(라)행', 'わ(와)행', 'ん(응)'];

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

  // 글자들을 '행' 단위로 나누는 함수
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('${widget.title} 학습', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.fact_check_rounded, color: Color(0xFF5B86E5), size: 28), // 아이콘 변경 및 크기 확대
            onPressed: () => _showQuizConfigDialog(),
            tooltip: '전체 퀴즈',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _allWords.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              children: [
                // 1. 학습 가이드
                _buildStudyGuide(),
                const SizedBox(height: 30),
                
                // 2. 행별 카드 리스트
                ...List.generate(groupedWords.length, (index) {
                  return _buildRowSection(
                    _rowNames[index < _rowNames.length ? index : _rowNames.length - 1],
                    groupedWords[index]
                  );
                }),
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _buildStudyGuide() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF5B86E5).withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF5B86E5).withOpacity(0.1)),
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF5B86E5)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '1. 한 행(5글자)씩 소리 내어 읽어보세요.\n2. 글자의 모양과 발음을 연결하며 눈에 익힙니다.\n3. 각 행 옆의 퀴즈 버튼으로 방금 배운 글자를 확인하세요.',
            style: TextStyle(fontSize: 13, color: Colors.blueGrey, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildRowSection(String title, List<Word> words) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF2D3142)),
              ),
              TextButton.icon(
                onPressed: () => _startQuiz(words, '$title 집중 퀴즈'),
                icon: const Icon(Icons.play_circle_filled_rounded, size: 18),
                label: const Text('이 행만 퀴즈', style: TextStyle(fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF5B86E5)),
              ),
            ],
          ),
        ),
        Container(
          height: 130, // 높이를 늘려 글자가 커질 공간 확보
          child: Row(
            children: words.map((word) => Expanded(child: _buildAlphabetCard(word))).toList(),
          ),
        ),
        const SizedBox(height: 10),
        const Divider(height: 30),
      ],
    );
  }

  Widget _buildAlphabetCard(Word word) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B86E5).withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 메인 문자 (크고 선명하게)
          Expanded(
            flex: 3,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  word.kanji,
                  style: const TextStyle(
                    fontSize: 38, // 크기를 대폭 확대
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2D3142),
                  ),
                ),
              ),
            ),
          ),
          // 정보 영역
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  word.meaning,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF5B86E5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  word.kana.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
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
          day: null, // 0이 아닌 null을 전달하여 '오늘의 단어'와 구분
          initialWords: quizWords.toList()..shuffle(),
        ),
      ),
    );
  }

  void _showQuizConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('퀴즈 설정', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('풀고 싶은 문제 수를 선택해주세요.'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                _buildConfigOption('10문제', 10),
                _buildConfigOption('20문제', 20),
                _buildConfigOption('30문제', 30),
                _buildConfigOption('전체 풀기 (${_allWords.length}문제)', _allWords.length),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigOption(String label, int count) {
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
            side: const BorderSide(color: Color(0xFF5B86E5), width: 1.5),
            foregroundColor: const Color(0xFF5B86E5),
          ),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }
}
