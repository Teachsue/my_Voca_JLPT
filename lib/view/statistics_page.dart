import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../model/word.dart';
import '../service/database_service.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionBox = Hive.box(DatabaseService.sessionBoxName);
    final wordsBox = Hive.box<Word>(DatabaseService.boxName);
    
    final today = DateTime.now().toString().split(' ')[0];
    final isGoalAchieved = sessionBox.get('todays_words_completed_$today', defaultValue: false);
    
    final totalWords = wordsBox.length;
    final learnedWords = wordsBox.values.where((w) => w.correctCount > 0).length;
    final progress = totalWords > 0 ? (learnedWords / totalWords) * 100 : 0.0;
    
    final reviewWords = wordsBox.values.where((w) => w.incorrectCount > 0).length;
    final recommendedLevel = sessionBox.get('recommended_level', defaultValue: '기록 없음');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('학습 통계 및 설정', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('나의 학습 현황'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    _buildStatRow('추천 레벨', recommendedLevel, Icons.stars_rounded, Colors.purple),
                    const Divider(height: 30),
                    _buildStatRow('오늘의 목표', isGoalAchieved ? '달성 완료 🔥' : '미달성 (오늘의 단어)', 
                      Icons.check_circle_rounded, isGoalAchieved ? Colors.green : Colors.orange),
                    const Divider(height: 30),
                    _buildStatRow('전체 진도율', '${progress.toStringAsFixed(1)}%', Icons.pie_chart_rounded, Colors.blue),
                    const Divider(height: 30),
                    _buildStatRow('복습 필요 단어', '$reviewWords개', Icons.replay_rounded, Colors.redAccent),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('데이터 관리'),
              const SizedBox(height: 12),
              _buildManagementCard(
                context,
                title: '레벨 테스트 초기화',
                subtitle: '추천 레벨 및 테스트 기록 삭제',
                icon: Icons.refresh_rounded,
                onTap: () => _showResetDialog(context, '레벨 테스트 초기화', '추천 레벨 기록을 삭제하시겠습니까?', () {
                  sessionBox.delete('recommended_level');
                }),
              ),
              const SizedBox(height: 12),
              _buildManagementCard(
                context,
                title: '모든 학습 기록 초기화',
                subtitle: '모든 진도율 및 학습 데이터 삭제',
                icon: Icons.delete_forever_rounded,
                color: Colors.redAccent,
                onTap: () => _showResetDialog(context, '모든 학습 기록 초기화', '모든 학습 데이터가 영구적으로 삭제됩니다. 계속하시겠습니까?', () {
                  for (var word in wordsBox.values) {
                    word.correctCount = 0;
                    word.incorrectCount = 0;
                    word.isMemorized = false;
                    word.save();
                  }
                  sessionBox.clear();
                }),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold));
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 15, color: Colors.black87)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }

  Widget _buildManagementCard(BuildContext context, {required String title, required String subtitle, required IconData icon, Color color = Colors.black87, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context, String title, String content, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title 완료되었습니다.')));
            },
            child: const Text('확인', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
