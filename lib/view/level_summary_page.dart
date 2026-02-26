import 'package:flutter/material.dart';
import 'day_selection_page.dart';
import 'quiz_page.dart';

class LevelSummaryPage extends StatelessWidget {
  final String level;

  const LevelSummaryPage({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color subTextColor = isDarkMode ? Colors.white60 : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('$level 학습 정보', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildActionCard(
                context,
                title: '단어 학습하기',
                subtitle: 'DAY별 20개씩 기초부터 탄탄하게',
                icon: Icons.menu_book_rounded,
                color: const Color(0xFF5B86E5),
                isDarkMode: isDarkMode,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DaySelectionPage(level: level)),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildActionCard(
                context,
                title: '랜덤 퀴즈 풀기',
                subtitle: '다양한 문제 수로 실력 테스트',
                icon: Icons.quiz_rounded,
                color: Colors.orangeAccent,
                isDarkMode: isDarkMode,
                onTap: () => _showQuizCountDialog(context, isDarkMode),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required bool isDarkMode, required VoidCallback onTap}) {
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color subTextColor = isDarkMode ? Colors.white60 : Colors.grey[600]!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDarkMode ? [] : [BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: subTextColor)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: isDarkMode ? Colors.white24 : Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showQuizCountDialog(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF2D3436) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Center(child: Text('문제 수 선택', style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [10, 20, 30].map((count) => ListTile(
            title: Center(child: Text('$count문제', style: TextStyle(fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white70 : Colors.black87))),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => QuizPage(level: level, questionCount: count)));
            },
          )).toList(),
        ),
      ),
    );
  }
}
