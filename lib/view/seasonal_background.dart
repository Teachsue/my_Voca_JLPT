import 'package:flutter/material.dart';

class SeasonalBackground extends StatelessWidget {
  final Widget child;
  final bool isDarkMode;
  final String appTheme;

  const SeasonalBackground({
    super.key, 
    required this.child, 
    required this.isDarkMode, 
    required this.appTheme
  });

  Map<String, dynamic> _getSeasonalTheme() {
    if (isDarkMode) {
      return {
        'colors': [const Color(0xFF1A1C2C), const Color(0xFF2D3436)],
        'icon': Icons.nights_stay_rounded,
        'iconColor': Colors.white.withOpacity(0.05),
      };
    }

    int month = DateTime.now().month;
    String target = appTheme;
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
    final theme = _getSeasonalTheme();
    
    // 배경을 포함한 컨테이너를 반환하여 각 페이지가 자신만의 배경을 갖게 함
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: theme['colors'],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Icon(theme['icon'], size: 250, color: theme['iconColor']),
          ),
          // 페이지 내용
          child,
        ],
      ),
    );
  }
}
