import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../model/word.dart';
import '../service/database_service.dart';
import 'quiz_page.dart';

class WordListPage extends StatelessWidget {
  final String level;
  final int day;
  final List<Word> words;

  const WordListPage({
    super.key,
    required this.level,
    required this.day,
    required this.words,
  });

  @override
  Widget build(BuildContext context) {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final bool isCompleted = day == 0 && Hive.box(DatabaseService.sessionBoxName).get('todays_words_completed_$todayStr', defaultValue: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          day == 0 ? (isCompleted ? '오늘의 단어 복습' : '오늘의 단어') : '$level DAY $day', 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      // Scaffold의 body는 자동으로 bottomNavigationBar 위의 공간만 차지함
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        itemCount: words.length + (isCompleted ? 1 : 0),
        separatorBuilder: (context, index) => SizedBox(height: isCompleted && index == 0 ? 20 : 12),
        itemBuilder: (context, index) {
          // 1. 복습 안내 문구
          if (isCompleted && index == 0) {
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

          final wordIndex = isCompleted ? index - 1 : index;
          final word = words[wordIndex];
          
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 순번
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isCompleted ? Colors.lightGreen.shade50 : Colors.grey[100], 
                        shape: BoxShape.circle
                      ),
                      child: Text(
                        '${wordIndex + 1}', 
                        style: TextStyle(
                          color: isCompleted ? Colors.lightGreen.shade700 : Colors.grey[600], 
                          fontSize: 12, 
                          fontWeight: FontWeight.bold
                        )
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 단어 상세 정보
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
                          Text(
                            word.meaning, 
                            style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                            softWrap: true,
                          ),
                        ],
                      ),
                    ),
                    // 북마크 버튼
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
        },
      ),
      // 하단 고정 버튼 영역 (Scaffold 기능을 사용하여 잘림 방지)
      bottomNavigationBar: Container(
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
                    builder: (context) => QuizPage(level: level, questionCount: words.length, day: day, initialWords: words),
                  ),
                );
              }
            },
            icon: Icon(isCompleted ? Icons.check_circle_rounded : Icons.quiz_rounded),
            label: Text(
              day == 0 
                  ? (isCompleted ? '복습 완료! ✅' : '오늘의 단어 퀴즈 풀기') 
                  : 'DAY $day 퀴즈 풀기', 
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
      ),
    );
  }
}
