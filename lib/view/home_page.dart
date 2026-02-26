import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../view_model/study_view_model.dart';
import '../service/database_service.dart';
import 'level_summary_page.dart';
import 'bookmark_page.dart';
import 'wrong_answer_page.dart';
import 'statistics_page.dart';
import 'word_list_page.dart';
import 'level_test_page.dart';
import 'calendar_page.dart';
import 'alphabet_page.dart';
import '../model/word.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isCompletedKey = 'todays_words_completed_$todayStr';

    return Scaffold(
      backgroundColor: Colors.transparent, // 배경 테마가 보이도록 투명 설정
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 헤더 (설정 아이콘 톱니바퀴)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'JLPT 단어 마스터',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    Row(
                      children: [
                        _buildHeaderIcon(Icons.settings_rounded, () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (context) => const StatisticsPage()));
                          _refresh();
                        }),
                        const SizedBox(width: 8),
                        _buildHeaderIcon(Icons.calendar_month_rounded, () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (context) => const CalendarPage()));
                          _refresh();
                        }),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 2. 오늘의 학습 배너
                ValueListenableBuilder(
                  valueListenable: Hive.box(DatabaseService.sessionBoxName).listenable(keys: [isCompletedKey]),
                  builder: (context, box, child) {
                    final bool isCompleted = box.get(isCompletedKey, defaultValue: false);

                    return GestureDetector(
                      onTap: () async {
                        final viewModel = StudyViewModel();
                        final List<Word> todaysWords = await viewModel.loadTodaysWords();
                        if (context.mounted) {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WordListPage(
                                level: isCompleted ? '오늘의 단어 복습' : '오늘의 단어',
                                initialDayIndex: 0,
                                allDayChunks: [todaysWords],
                              ),
                            ),
                          );
                          _refresh();
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isCompleted
                                ? [Colors.grey.shade400, Colors.grey.shade500]
                                : [const Color(0xFF5B86E5), const Color(0xFF36D1DC)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: isCompleted ? Colors.black.withOpacity(0.05) : const Color(0xFF5B86E5).withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isCompleted ? '오늘의 학습 완료! ✅' : '오늘의 학습 시작하기 🔥',
                                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isCompleted ? "복습으로 실력을 다지세요." : "매일 10개씩 꾸준히 시작하세요.",
                                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // 3. 실력 테스트
                ValueListenableBuilder(
                  valueListenable: Hive.box(DatabaseService.sessionBoxName).listenable(keys: ['recommended_level']),
                  builder: (context, box, child) {
                    final String? recommendedLevel = box.get('recommended_level');
                    final bool hasResult = recommendedLevel != null;

                    return GestureDetector(
                      onTap: () async {
                        if (hasResult) {
                          await Navigator.push(context, MaterialPageRoute(builder: (context) => LevelSummaryPage(level: recommendedLevel)));
                        } else {
                          _showLevelTestGuide(context);
                        }
                        _refresh();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: hasResult ? const Color(0xFFF0F7FF).withOpacity(0.7) : Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              hasResult ? Icons.workspace_premium_rounded : Icons.psychology_alt_rounded,
                              color: hasResult ? const Color(0xFF5B86E5) : Colors.orange,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                hasResult ? "추천 레벨: $recommendedLevel" : "내 실력 진단 테스트",
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 18),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // 4. 기초 다지기
                const Text("기초 다지기", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: _buildCategoryCard(context, '히라가나', '기초 1', Icons.font_download_rounded, Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AlphabetPage(title: '히라가나', level: 11))))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildCategoryCard(context, '가타카나', '기초 2', Icons.translate_rounded, Colors.indigo, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AlphabetPage(title: '가타카나', level: 12))))),
                  ],
                ),

                const SizedBox(height: 12),

                // 5. 레벨별 학습
                const Text("레벨별 학습", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.3,
                  children: [
                    _buildLevelCard(context, 'N5', '입문', Colors.green),
                    _buildLevelCard(context, 'N4', '초급', Colors.lightGreen),
                    _buildLevelCard(context, 'N3', '중급', Colors.blue),
                    _buildLevelCard(context, 'N2', '상급', Colors.indigo),
                    _buildLevelCard(context, 'N1', '전문', Colors.purple),
                  ],
                ),

                const SizedBox(height: 12),

                // 6. 나의 관리
                const Text("나의 관리", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: _buildCategoryCard(context, '북마크', '중요', Icons.star_rounded, Colors.amber, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BookmarkPage())))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildCategoryCard(context, '오답노트', '틀린단어', Icons.error_outline_rounded, Colors.redAccent, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WrongAnswerPage())))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, VoidCallback onTap) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)]),
      child: IconButton(icon: Icon(icon, color: const Color(0xFF5B86E5), size: 20), onPressed: onTap, padding: EdgeInsets.zero),
    );
  }

  Widget _buildLevelCard(BuildContext context, String level, String desc, Color color) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LevelSummaryPage(level: level))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(level, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
            Text(desc, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  void _showLevelTestGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("실력 진단 테스트", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: const Text("30문항으로 추천 레벨을 진단합니다.", textAlign: TextAlign.center),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("나중에")),
          ElevatedButton(
            onPressed: () async { Navigator.pop(context); await Navigator.push(context, MaterialPageRoute(builder: (context) => const LevelTestPage())); _refresh(); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            child: const Text("시작"),
          ),
        ],
      ),
    );
  }
}
