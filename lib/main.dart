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

  // 1. Hive 초기화 및 박스 열기 보장
  await DatabaseService.init();

  await initializeDateFormatting('ko_KR', null);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());

  // 데이터 로딩은 백그라운드에서 진행
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
    // 세션 박스를 미리 참조
    final sessionBox = Hive.box(DatabaseService.sessionBoxName);

    return ValueListenableBuilder(
      valueListenable: sessionBox.listenable(keys: ['dark_mode']),
      builder: (context, Box box, _) {
        final bool isDarkMode = box.get('dark_mode', defaultValue: false);
        
        return MaterialApp(
          title: 'JLPT 단어장',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF5B86E5),
              brightness: isDarkMode ? Brightness.dark : Brightness.light,
            ),
            // Theme.of(context) 대신 정적 텍스트 테마 사용
            textTheme: GoogleFonts.notoSansTextTheme(
              isDarkMode ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
            ).apply(
              bodyColor: isDarkMode ? Colors.white : Colors.black87,
              displayColor: isDarkMode ? Colors.white : Colors.black87,
            ),
            scaffoldBackgroundColor: Colors.transparent,
            canvasColor: Colors.transparent,
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.black87),
              titleTextStyle: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            cardTheme: CardThemeData(
              color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          builder: (context, child) {
            return SeasonalBackground(child: child!);
          },
          home: const HomePage(),
        );
      },
    );
  }
}
