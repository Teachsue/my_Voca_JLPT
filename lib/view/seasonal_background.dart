import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../service/database_service.dart';

class SeasonalBackground extends StatelessWidget {
  final Widget child;

  const SeasonalBackground({super.key, required this.child});

  Map<String, dynamic> _getSeasonalTheme(String? preferredTheme) {
    int month = DateTime.now().month;
    String target = preferredTheme ?? 'auto';
    
    if (target == 'auto') {
      if (month >= 3 && month <= 5) target = 'spring';
      else if (month >= 6 && month <= 8) target = 'summer';
      else if (month >= 9 && month <= 11) target = 'autumn';
      else target = 'winter';
    }

    switch (target) {
      case 'spring':
        return {
          'colors': [const Color(0xFFFFF0F5), const Color(0xFFFFFFFF)],
          'icon': Icons.local_florist_rounded,
          'iconColor': Colors.pink.withOpacity(0.08),
        };
      case 'summer':
        return {
          'colors': [const Color(0xFFE0F7FA), const Color(0xFFFFFFFF)],
          'icon': Icons.wb_sunny_rounded,
          'iconColor': Colors.blue.withOpacity(0.08),
        };
      case 'autumn':
        return {
          'colors': [const Color(0xFFFFF3E0), const Color(0xFFFFFFFF)],
          'icon': Icons.eco_rounded,
          'iconColor': Colors.orange.withOpacity(0.08),
        };
      case 'winter':
      default:
        return {
          'colors': [const Color(0xFFF1F4F8), const Color(0xFFFFFFFF)],
          'icon': Icons.ac_unit_rounded,
          'iconColor': Colors.blueGrey.withOpacity(0.08),
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box(DatabaseService.sessionBoxName).listenable(keys: ['app_theme']),
      builder: (context, box, _) {
        final theme = _getSeasonalTheme(box.get('app_theme'));
        
        return Material( // Scaffold 대신 가벼운 Material 사용
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: theme['colors'],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -30,
                  right: -30,
                  child: Icon(theme['icon'], size: 250, color: theme['iconColor']),
                ),
                child, // 이 child가 앱의 전체 Navigator(모든 페이지)입니다.
              ],
            ),
          ),
        );
      },
    );
  }
}
