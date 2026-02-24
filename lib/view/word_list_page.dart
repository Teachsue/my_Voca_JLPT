import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../model/word.dart';
import '../service/database_service.dart';
import 'quiz_page.dart';

class WordListPage extends StatefulWidget {
  final String level;
  final int initialDayIndex;
  final List<List<Word>> allDayChunks;

  const WordListPage({
    super.key,
    required this.level,
    required this.initialDayIndex,
    required this.allDayChunks,
  });

  @override
  State<WordListPage> createState() => _WordListPageState();
}

class _WordListPageState extends State<WordListPage> {
  late PageController _pageController;
  late int _currentDayIndex;
  late bool _isTodaysWords;

  @override
  void initState() {
    super.initState();
    _currentDayIndex = widget.initialDayIndex;
    _pageController = PageController(initialPage: widget.initialDayIndex);
    _isTodaysWords = widget.level == '오늘의 단어' || widget.level == '오늘의 단어 복습';
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final bool isCompleted = _isTodaysWords && 
        Hive.box(DatabaseService.sessionBoxName).get('todays_words_completed_$todayStr', defaultValue: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _isTodaysWords 
              ? (isCompleted ? '오늘의 단어 복습' : '오늘의 단어') 
              : '${widget.level} DAY ${_currentDayIndex + 1}', 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentDayIndex = index;
          });
        },
        itemCount: widget.allDayChunks.length,
        itemBuilder: (context, chunkIndex) {
          final List<Word> currentWords = widget.allDayChunks[chunkIndex];
          
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            itemCount: currentWords.length + (isCompleted ? 1 : 0),
            itemBuilder: (context, index) {
              if (isCompleted && index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _buildReviewBanner(),
                );
              }

              final wordIndex = isCompleted ? index - 1 : index;
              final word = currentWords[wordIndex];
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildWordCard(word, wordIndex, isCompleted),
              );
            },
          );
        },
      ),
      bottomNavigationBar: _buildBottomButton(isCompleted),
    );
  }

  Widget _buildReviewBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.lightGreen.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.lightGreen.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline_rounded, color: Colors.lightGreen.shade700),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '오늘의 학습을 완료했습니다!\n가볍게 훑어보며 복습해보세요.',
              style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordCard(Word word, int index, bool isCompleted) {
    return StatefulBuilder(
      builder: (context, setStateItem) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.lightGreen.shade50 : Colors.grey[100], 
                  shape: BoxShape.circle
                ),
                child: Text(
                  '${index + 1}', 
                  style: TextStyle(
                    color: isCompleted ? Colors.lightGreen.shade700 : Colors.grey[600], 
                    fontSize: 12, 
                    fontWeight: FontWeight.bold
                  )
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.end,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(word.kanji, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(word.kana, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                                                  Text(
                                                    '[${word.koreanPronunciation}]', 
                                                    style: TextStyle(
                                                      fontSize: 12, 
                                                      color: (isCompleted ? Colors.lightGreen.shade700 : const Color(0xFF5B86E5)).withOpacity(0.7)
                                                    )
                                                  ),
                        
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(word.meaning, style: TextStyle(fontSize: 15, color: Colors.grey[700]), softWrap: true),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  word.isBookmarked ? Icons.star_rounded : Icons.star_border_rounded, 
                  color: word.isBookmarked ? Colors.amber : Colors.grey[300],
                  size: 26,
                ),
                onPressed: () {
                  setStateItem(() {
                    word.isBookmarked = !word.isBookmarked;
                    word.save();
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomButton(bool isCompleted) {
    final currentWords = widget.allDayChunks[_currentDayIndex];

    return Container(
      padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).padding.bottom + 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: () {
            if (isCompleted) {
              Navigator.popUntil(context, (route) => route.isFirst);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizPage(
                    level: widget.level, 
                    questionCount: currentWords.length, 
                    day: _isTodaysWords ? 0 : _currentDayIndex + 1, 
                    initialWords: currentWords
                  ),
                ),
              );
            }
          },
          icon: Icon(isCompleted ? Icons.check_circle_rounded : Icons.quiz_rounded),
          label: Text(
            _isTodaysWords
                ? (isCompleted ? '복습 완료! ✅' : '오늘의 단어 퀴즈 풀기') 
                : 'DAY ${_currentDayIndex + 1} 퀴즈 풀기', 
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isCompleted ? Colors.lightGreen : const Color(0xFF5B86E5),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
