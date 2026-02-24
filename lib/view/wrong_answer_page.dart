import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../model/word.dart';
import '../service/database_service.dart';

class WrongAnswerPage extends StatelessWidget {
  const WrongAnswerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('오답노트', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: () => _showResetDialog(context),
            tooltip: '오답 기록 초기화',
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Word>(DatabaseService.boxName).listenable(),
        builder: (context, Box<Word> box, _) {
          // 틀린 횟수가 1회 이상인 단어들만 필터링
          final wrongWords = box.values
              .where((w) => w.incorrectCount > 0)
              .toList()
            ..sort((a, b) => b.incorrectCount.compareTo(a.incorrectCount)); // 많이 틀린 순

          if (wrongWords.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_turned_in_rounded, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text(
                    '오답 기록이 없습니다.\n모든 단어를 마스터하셨네요!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: wrongWords.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final word = wrongWords[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${word.incorrectCount}',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                word.kanji,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                word.kana,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '[${word.koreanPronunciation}]',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: const Color(0xFF5B86E5).withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            word.meaning,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        word.isBookmarked ? Icons.star_rounded : Icons.star_border_rounded,
                        color: word.isBookmarked ? Colors.amber : Colors.grey[300],
                      ),
                      onPressed: () {
                        word.isBookmarked = !word.isBookmarked;
                        word.save();
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오답 기록 초기화'),
        content: const Text('모든 단어의 오답 기록을 삭제하시겠습니까? (단어 자체가 삭제되지는 않습니다)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
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
            child: const Text('초기화', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
