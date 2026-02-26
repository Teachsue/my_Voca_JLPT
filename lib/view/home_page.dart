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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 헤더 영역 (인사말 & 아이콘)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '안녕하세요!',
                          style: TextStyle(fontSize: 14, color: Colors.blueGrey, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'JLPT 단어 마스터',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _buildHeaderIcon(Icons.settings_rounded, () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (context) => const StatisticsPage()));
                          _refresh();
                        }),
                        const SizedBox(width: 12),
                        _buildHeaderIcon(Icons.calendar_month_rounded, () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (context) => const CalendarPage()));
                          _refresh();
                        }),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // 2. 메인 배너 (오늘의 학습)
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
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isCompleted
                                ? [Colors.grey.shade400, Colors.grey.shade500]
                                : [const Color(0xFF5B86E5), const Color(0xFF36D1DC)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: isCompleted ? Colors.grey.withOpacity(0.2) : const Color(0xFF5B86E5).withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isCompleted ? '학습 완료 ✅' : '오늘의 단어 🔥',
                                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    isCompleted ? "훌륭합니다! 내일 다시 만나요.\n복습은 언제나 환영이에요." : "매일 10개씩 꾸준히!\n지금 바로 시작하세요.",
                                    style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                              child: Icon(isCompleted ? Icons.check_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 28),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // 3. 실력 테스트 결과 또는 테스트 시작
                ValueListenableBuilder(
                  valueListenable: Hive.box(DatabaseService.sessionBoxName).listenable(keys: ['recommended_level']),
                  builder: (context, box, child) {
                    final String? recommendedLevel = box.get('recommended_level');
                    final bool hasResult = recommendedLevel != null;

                    return GestureDetector(
                      onTap: () async {
                        if (hasResult) {
                          // 결과가 있으면 해당 레벨 학습 페이지로 이동
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => LevelSummaryPage(level: recommendedLevel)),
                          );
                        } else {
                          // 결과가 없으면 테스트 안내창 표시
                          _showLevelTestGuide(context);
                        }
                        _refresh();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        decoration: BoxDecoration(
                          color: hasResult ? const Color(0xFFF0F7FF) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: hasResult ? Border.all(color: const Color(0xFF5B86E5).withOpacity(0.3), width: 1.5) : null,
                          boxShadow: [
                            BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (hasResult ? const Color(0xFF5B86E5) : Colors.orange).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                hasResult ? Icons.workspace_premium_rounded : Icons.psychology_alt_rounded,
                                color: hasResult ? const Color(0xFF5B86E5) : Colors.orange,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    hasResult ? "나의 맞춤 레벨: $recommendedLevel" : "내 실력 확인하기",
                                    style: TextStyle(
                                      fontSize: 16, 
                                      fontWeight: FontWeight.bold, 
                                      color: hasResult ? const Color(0xFF5B86E5) : Colors.black87
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    hasResult 
                                      ? "$recommendedLevel 과정 학습을 시작하세요!"
                                      : "30문제로 JLPT 등급 판정받기",
                                    style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              hasResult ? Icons.arrow_forward_ios_rounded : Icons.chevron_right_rounded, 
                              color: hasResult ? const Color(0xFF5B86E5) : Colors.grey, 
                              size: 18
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 25),

                // 기초 다지기 (히라가나/가타카나)
                const Text("기초 다지기", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildCategoryCard(
                        context, 
                        '히라가나', 
                        '기초 문자 1', 
                        Icons.font_download_rounded, 
                        Colors.teal, 
                        () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AlphabetPage(title: '히라가나', level: 11)))
                      )
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCategoryCard(
                        context, 
                        '가타카나', 
                        '기초 문자 2', 
                        Icons.translate_rounded, 
                        Colors.indigo, 
                        () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AlphabetPage(title: '가타카나', level: 12)))
                      )
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // 4. 레벨별 학습 (3열 배치)
                const Text("레벨별 학습", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildSmallCard(context, '초급', 'N4-N5', Icons.child_care_rounded, Colors.green, ['N5', 'N4'])),
                    const SizedBox(width: 12),
                    Expanded(child: _buildSmallCard(context, '중급', 'N2-N3', Icons.menu_book_rounded, Colors.blue, ['N3', 'N2'])),
                    const SizedBox(width: 12),
                    Expanded(child: _buildCategoryCard(context, '고급', 'N1', Icons.workspace_premium_rounded, Colors.purple, 
                      () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LevelSummaryPage(level: 'N1'))))),
                  ],
                ),

                const SizedBox(height: 25),

                // 5. 나의 관리 (2열 배치)
                const Text("나의 관리", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildCategoryCard(context, '북마크', '중요 단어', Icons.star_rounded, Colors.amber, 
                      () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BookmarkPage())))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildCategoryCard(context, '오답노트', '틀린 단어', Icons.error_outline_rounded, Colors.redAccent, 
                      () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WrongAnswerPage())))),
                  ],
                ),
                // 삼성 네비게이션 바를 고려한 하단 여백 추가
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: IconButton(icon: Icon(icon, color: const Color(0xFF5B86E5), size: 22), onPressed: onTap),
    );
  }

  Widget _buildSmallCard(BuildContext context, String title, String subtitle, IconData icon, Color color, List<String> levels) {
    return _buildCategoryCard(context, title, subtitle, icon, color, () => _showLevelDialog(context, '$title 학습', levels));
  }

  Widget _buildCategoryCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.08), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
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
        title: const Column(
          children: [
            Icon(Icons.psychology_alt_rounded, color: Colors.orange, size: 50),
            SizedBox(height: 15),
            Text(
              "실력 진단 테스트 안내",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "본인의 실력에 맞는 레벨을 찾기 위해\n총 30문항의 테스트를 진행합니다.",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.check_circle_outline, size: 18, color: Colors.grey),
                SizedBox(width: 10),
                Expanded(child: Text("N1~N4 각 5문항, N5 10문항")),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 18, color: Colors.grey),
                SizedBox(width: 10),
                Expanded(child: Text("예상 소요 시간: 약 10분")),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, size: 18, color: Colors.grey),
                SizedBox(width: 10),
                Expanded(child: Text("결과에 따른 맞춤형 레벨 추천")),
              ],
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("나중에 하기", style: TextStyle(color: Colors.grey)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => const LevelTestPage()));
                    _refresh();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("테스트 시작", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLevelDialog(BuildContext context, String title, List<String> levels) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Center(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(),
            ...levels.map((level) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              leading: const Icon(Icons.stars_rounded, color: Color(0xFF5B86E5)),
              title: Text(level, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => LevelSummaryPage(level: level)));
              },
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
