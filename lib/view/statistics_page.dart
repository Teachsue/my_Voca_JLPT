import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../model/word.dart';
import '../service/database_service.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  @override
  Widget build(BuildContext context) {
    final sessionBox = Hive.box(DatabaseService.sessionBoxName);
    final wordsBox = Hive.box<Word>(DatabaseService.boxName);

    // 두 개의 박스 리스너를 중첩하여 모든 변화에 대응
    return ValueListenableBuilder(
      valueListenable: sessionBox.listenable(keys: ['dark_mode', 'app_theme', 'recommended_level']),
      builder: (context, sBox, _) {
        return ValueListenableBuilder(
          valueListenable: wordsBox.listenable(),
          builder: (context, wBox, _) {
            final bool isDarkMode = sBox.get('dark_mode', defaultValue: false);
            final String currentTheme = sBox.get('app_theme', defaultValue: 'auto');
            final Color textColor = isDarkMode ? Colors.white : Colors.black87;
            final Color subTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
            final Color cardColor = isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white;

            // 실시간 통계 계산 (ValueListenableBuilder 내부에서 수행하여 즉시 반영)
            final today = DateTime.now().toString().split(' ')[0];
            final isGoalAchieved = sBox.get('todays_words_completed_$today', defaultValue: false);

            final totalWords = wBox.length;
            final learnedWords = wBox.values.where((w) => w.correctCount > 0).length;
            final progress = totalWords > 0 ? (learnedWords / totalWords) * 100 : 0.0;

            final reviewWords = wBox.values.where((w) => w.incorrectCount > 0).length;
            final recommendedLevel = sBox.get('recommended_level', defaultValue: '기록 없음');

            return Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: Text('설정 및 학습 통계', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
                backgroundColor: Colors.transparent,
                foregroundColor: textColor,
                elevation: 0,
                centerTitle: true,
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('나의 학습 현황', textColor),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isDarkMode ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Column(
                          children: [
                            _buildStatRow('추천 레벨', recommendedLevel, Icons.stars_rounded, Colors.purple, textColor),
                            Divider(height: 30, color: isDarkMode ? Colors.white10 : Colors.grey[200]),
                            _buildStatRow('오늘의 목표', isGoalAchieved ? '달성 완료 🔥' : '미달성 (오늘의 단어)', 
                              Icons.check_circle_rounded, isGoalAchieved ? Colors.green : Colors.orange, textColor),
                            Divider(height: 30, color: isDarkMode ? Colors.white10 : Colors.grey[200]),
                            _buildStatRow('전체 진도율', '${progress.toStringAsFixed(1)}%', Icons.pie_chart_rounded, Colors.blue, textColor),
                            Divider(height: 30, color: isDarkMode ? Colors.white10 : Colors.grey[200]),
                            _buildStatRow('복습 필요 단어', '$reviewWords개', Icons.replay_rounded, Colors.redAccent, textColor),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      _buildSectionTitle('배경 테마 및 모드 설정', textColor),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isDarkMode ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text('다크 모드', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
                              subtitle: Text('눈이 편안한 밤 테마 적용', style: TextStyle(fontSize: 12, color: subTextColor)),
                              value: isDarkMode,
                              onChanged: (val) => sBox.put('dark_mode', val),
                              activeColor: const Color(0xFF5B86E5),
                            ),
                            Divider(color: isDarkMode ? Colors.white10 : Colors.grey[200]),
                            const SizedBox(height: 12),
                            
                            GestureDetector(
                              onTap: () => sBox.put('app_theme', 'auto'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: currentTheme == 'auto' 
                                    ? const Color(0xFF5B86E5).withOpacity(0.15) 
                                    : (isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey[50]),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: currentTheme == 'auto' ? const Color(0xFF5B86E5) : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.auto_awesome_rounded, 
                                      size: 20, 
                                      color: currentTheme == 'auto' ? const Color(0xFF5B86E5) : subTextColor
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '자동 (현재 계절에 맞춤)', 
                                            style: TextStyle(
                                              fontSize: 15, 
                                              fontWeight: currentTheme == 'auto' ? FontWeight.bold : FontWeight.w500,
                                              color: currentTheme == 'auto' ? const Color(0xFF5B86E5) : textColor
                                            ),
                                          ),
                                          Text(
                                            '일본의 사계절을 자동으로 반영합니다.',
                                            style: TextStyle(fontSize: 11, color: currentTheme == 'auto' ? const Color(0xFF5B86E5).withOpacity(0.7) : subTextColor),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (currentTheme == 'auto')
                                      const Icon(Icons.check_circle_rounded, color: Color(0xFF5B86E5), size: 22),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 10),
                              child: Text('수동 계절 선택', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: subTextColor)),
                            ),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildSeasonalChip(context, '봄', 'spring', currentTheme, Colors.pinkAccent, isDarkMode),
                                  const SizedBox(width: 8),
                                  _buildSeasonalChip(context, '여름', 'summer', currentTheme, Colors.blueAccent, isDarkMode),
                                  const SizedBox(width: 8),
                                  _buildSeasonalChip(context, '가을', 'autumn', currentTheme, Colors.orangeAccent, isDarkMode),
                                  const SizedBox(width: 8),
                                  _buildSeasonalChip(context, '겨울', 'winter', currentTheme, Colors.blueGrey, isDarkMode),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                      _buildSectionTitle('데이터 관리', textColor),
                      const SizedBox(height: 12),
                      _buildManagementCard(
                        context,
                        title: '레벨 테스트 초기화',
                        subtitle: '추천 레벨 및 테스트 기록 삭제',
                        icon: Icons.refresh_rounded,
                        isDarkMode: isDarkMode,
                        onTap: () => _showResetDialog(context, '레벨 테스트 초기화', '추천 레벨 기록을 삭제하시겠습니까?', () {
                          sBox.delete('recommended_level');
                        }),
                      ),
                      const SizedBox(height: 12),
                      _buildManagementCard(
                        context,
                        title: '모든 학습 기록 초기화',
                        subtitle: '모든 진도율, 실력 진단 및 학습 데이터 삭제',
                        icon: Icons.delete_forever_rounded,
                        color: Colors.redAccent,
                        isDarkMode: isDarkMode,
                        onTap: () => _showResetDialog(context, '모든 학습 기록 초기화', '추천 레벨을 포함한 모든 학습 데이터가 영구적으로 삭제됩니다. 계속하시겠습니까?', () async {
                          // 1. 단어장 데이터 초기화 (대량 변경 시 putAll 사용 권장)
                          Map<dynamic, Word> updatedWords = {};
                          for (var entry in wBox.toMap().entries) {
                            final word = entry.value;
                            word.correctCount = 0;
                            word.incorrectCount = 0;
                            word.isMemorized = false;
                            word.isBookmarked = false;
                            word.srsStage = 0;
                            word.nextReviewDate = null;
                            updatedWords[entry.key] = word;
                          }
                          await wBox.putAll(updatedWords);
                          
                          // 2. 세션 데이터 초기화 (추천 레벨 등 포함)
                          String currentThemeSetting = sBox.get('app_theme', defaultValue: 'auto');
                          bool currentDarkMode = sBox.get('dark_mode', defaultValue: false);
                          await sBox.clear(); 
                          await sBox.put('app_theme', currentThemeSetting);
                          await sBox.put('dark_mode', currentDarkMode);
                        }),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color));
  }

  Widget _buildSeasonalChip(BuildContext context, String label, String value, String current, Color color, bool isDarkMode) {
    bool isSelected = current == value;
    final sessionBox = Hive.box(DatabaseService.sessionBoxName);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) sessionBox.put('app_theme', value);
      },
      selectedColor: color.withOpacity(0.3),
      labelStyle: TextStyle(color: isSelected ? (isDarkMode ? Colors.white : color) : (isDarkMode ? Colors.grey[400] : Colors.black87), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
      backgroundColor: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: isSelected ? color : Colors.transparent)),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color, Color textColor) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(fontSize: 15, color: textColor)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
      ],
    );
  }

  Widget _buildManagementCard(BuildContext context, {required String title, required String subtitle, required IconData icon, Color? color, required bool isDarkMode, required VoidCallback onTap}) {
    Color textColor = color ?? (isDarkMode ? Colors.white : Colors.black87);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDarkMode ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? (isDarkMode ? Colors.white70 : Colors.black54), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white38 : Colors.grey[500])),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: isDarkMode ? Colors.white24 : Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context, String title, String content, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2D3436) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)),
        content: Text(content, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87)),
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
