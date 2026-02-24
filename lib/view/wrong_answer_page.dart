import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../model/word.dart';
import '../service/database_service.dart';
import 'quiz_page.dart';

class WrongAnswerPage extends StatelessWidget {
  const WrongAnswerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('오답노트', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.delete_sweep_rounded, size: 22), onPressed: () => _showResetDialog(context), tooltip: '초기화'),
        ],
      ),
      body: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: Hive.box<Word>(DatabaseService.boxName).listenable(),
          builder: (context, Box<Word> box, _) {
            final wrongWords = box.values.where((w) => w.incorrectCount > 0).toList()
              ..sort((a, b) => b.incorrectCount.compareTo(a.incorrectCount));

            if (wrongWords.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_turned_in_rounded, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    const Text('오답 기록이 없습니다.\n모든 단어를 마스터하셨네요!', textAlign: TextAlign.center, style: TextStyle(fontSize: 17, color: Colors.grey)),
                  ],
                ),
              );
            }

            return Stack(
              children: [
                ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 120), // 하단 버튼 공간 확보
                  itemCount: wrongWords.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final word = wrongWords[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Row(
                        children: [
                          // 1. 순번 표시 (1, 2, 3...)
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                            child: Text('${index + 1}', style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          // 2. 단어 정보
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
                                    Text('[${word.koreanPronunciation}]', style: TextStyle(fontSize: 12, color: const Color(0xFF5B86E5).withOpacity(0.7))),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(word.meaning, style: TextStyle(fontSize: 15, color: Colors.grey[700])),
                              ],
                            ),
                          ),
                          // 3. 틀린 횟수 뱃지 및 삭제 버튼
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(10)),
                                child: Text('틀림 ${word.incorrectCount}', style: TextStyle(color: Colors.red[700], fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline_rounded, color: Colors.red[200], size: 22),
                                onPressed: () {
                                  word.incorrectCount = 0;
                                  word.save();
                                },
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.only(top: 4),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                // 하단 오답 퀴즈 풀기 버튼
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 35),
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
                              builder: (context) => QuizPage(
                                level: '오답노트',
                                questionCount: wrongWords.length,
                                day: -1, // 오답노트임을 구분하기 위한 값
                                initialWords: wrongWords,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.replay_rounded),
                        label: const Text('오답 퀴즈 풀기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 8,
                          shadowColor: Colors.redAccent.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('오답 기록 초기화', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('모든 단어의 오답 기록을 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () {
              final box = Hive.box<Word>(DatabaseService.boxName);
              for (var word in box.values) {
                if (word.incorrectCount > 0) {
                  word.incorrectCount = 0;
                  word.save();
                }
              }
              Navigator.pop(context);
            },
            child: const Text('초기화', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
