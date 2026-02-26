import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'view/home_page.dart';
import 'service/database_service.dart';
import 'view/seasonal_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ko_KR', null);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await DatabaseService.init();

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
    return MaterialApp(
      title: 'JLPT 단어장',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B86E5),
          primary: const Color(0xFF5B86E5),
          surface: Colors.transparent, // 기본 표면 색상 투명화
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansTextTheme(
          Theme.of(context).textTheme,
        ),
        // 전역 투명도 설정 최적화
        scaffoldBackgroundColor: Colors.transparent,
        canvasColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      builder: (context, child) {
        // 배경을 최하단 레이어에 한 번만 렌더링하고, Navigator를 그 위에 올림
        return SeasonalBackground(child: child!);
      },
      home: const HomePage(),
    );
  }
}
