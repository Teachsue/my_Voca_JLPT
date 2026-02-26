import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'view/home_page.dart';
import 'service/database_service.dart';
import 'view/seasonal_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.init();
  await initializeDateFormatting('ko_KR', null);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());

  Future.microtask(() async {
    for (int i = 1; i <= 5; i++) {
      await DatabaseService.loadJsonToHive(i);
    }
    await DatabaseService.loadJsonToHive(11);
    await DatabaseService.loadJsonToHive(12);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionBox = Hive.box(DatabaseService.sessionBoxName);

    return ValueListenableBuilder<Box>(
      valueListenable: sessionBox.listenable(keys: ['dark_mode', 'app_theme']),
      builder: (context, box, _) {
        final bool isDarkMode = box.get('dark_mode', defaultValue: false);
        final String appTheme = box.get('app_theme', defaultValue: 'auto');
        
        return MaterialApp(
          title: 'JLPT 단어장',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            // 모든 표면 색상을 투명하게 하여 배경 딜레이 원천 차단
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF5B86E5),
              brightness: isDarkMode ? Brightness.dark : Brightness.light,
              surface: Colors.transparent, // 표면 투명화
            ),
            textTheme: GoogleFonts.notoSansTextTheme(
              isDarkMode ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
            ).apply(
              bodyColor: isDarkMode ? Colors.white : Colors.black87,
              displayColor: isDarkMode ? Colors.white : Colors.black87,
            ),
            scaffoldBackgroundColor: Colors.transparent,
            canvasColor: Colors.transparent,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              surfaceTintColor: Colors.transparent,
            ),
            cardTheme: CardThemeData(
              color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.9),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          builder: (context, child) {
            // 배경이 항상 Navigator보다 먼저 존재하도록 Stack 구조 보장
            return SeasonalBackground(
              isDarkMode: isDarkMode,
              appTheme: appTheme,
              child: Material(
                color: Colors.transparent, // 기본 배경 제거
                child: child!,
              ),
            );
          },
          home: const HomePage(),
        );
      },
    );
  }
}
