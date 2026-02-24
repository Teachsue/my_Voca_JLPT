import 'package:flutter/material.dart';
import '../model/word.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(day == 0 ? '오늘의 단어' : '$level DAY $day', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 120), // 하단 버튼 공간 확보 (120)
            itemCount: words.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final word = words[index];
              return StatefulBuilder(
                builder: (context, setStateItem) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                          child: Text('${index + 1}', style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(word.kanji, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Text(word.kana, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                                  const SizedBox(width: 6),
                                  Text('[${word.koreanPronunciation}]', style: TextStyle(fontSize: 12, color: const Color(0xFF5B86E5).withOpacity(0.7))),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(word.meaning, style: TextStyle(fontSize: 15, color: Colors.grey[700])),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(word.isBookmarked ? Icons.star_rounded : Icons.star_border_rounded, color: word.isBookmarked ? Colors.amber : Colors.grey[300]),
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
          // 하단 퀴즈 풀기 버튼 (고정 위치)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 35), // 네비게이션 바 대응 패딩
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white.withOpacity(0), Colors.white.withOpacity(0.9), Colors.white],
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuizPage(level: level, questionCount: words.length, day: day, initialWords: words),
                      ),
                    );
                  },
                  icon: const Icon(Icons.quiz_rounded),
                  label: Text(day == 0 ? '오늘의 단어 퀴즈 풀기' : 'DAY $day 퀴즈 풀기', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B86E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                    shadowColor: const Color(0xFF5B86E5).withOpacity(0.4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
