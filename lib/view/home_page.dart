import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'level_summary_page.dart';
import 'bookmark_page.dart';
import 'wrong_answer_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final String todayStr = DateFormat('M월 d일').format(DateTime.now());

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 커스텀 헤더
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '안녕하세요!',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Text(
                          'JLPT 단어 마스터',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.15),
                            blurRadius: 10,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF5B86E5)),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // 2. 메인 배너 (오늘의 학습)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LevelSummaryPage(level: 'N5')),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5B86E5), Color(0xFF36D1DC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5B86E5).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
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
                                '$todayStr 학습',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                "오늘의 단어를 마스터하세요!",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 40),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // 3. 레벨별 학습 (초급, 중급, 고급 - 한 줄 배치)
                const Text("레벨별 학습", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildCategoryCard(
                        context,
                        '초급',
                        'N4~N5',
                        Icons.child_care_rounded,
                        Colors.green,
                        () => _showLevelDialog(context, '초급 학습', ['N5', 'N4']),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildCategoryCard(
                        context,
                        '중급',
                        'N2~N3',
                        Icons.menu_book_rounded,
                        Colors.blue,
                        () => _showLevelDialog(context, '중급 학습', ['N3', 'N2']),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildCategoryCard(
                        context,
                        '고급',
                        'N1',
                        Icons.workspace_premium_rounded,
                        Colors.purple,
                        () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LevelSummaryPage(level: 'N1'))),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 4. 나의 관리 (북마크, 오답노트 - 한 줄 배치)
                const Text("나의 관리", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildCategoryCard(
                        context,
                        '북마크',
                        '중요 단어',
                        Icons.star_rounded,
                        Colors.amber,
                        () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BookmarkPage())),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCategoryCard(
                        context,
                        '오답노트',
                        '틀린 단어',
                        Icons.error_outline_rounded,
                        Colors.redAccent,
                        () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WrongAnswerPage())),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  void _showLevelDialog(BuildContext context, String title, List<String> levels) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Center(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(),
            ...levels.map((level) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  leading: const Icon(Icons.stars_rounded, color: Color(0xFF5B86E5)),
                  title: Text(
                    level,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LevelSummaryPage(level: level),
                      ),
                    );
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
