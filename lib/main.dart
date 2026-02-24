import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'view/home_page.dart';
import 'service/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 날짜 형식 초기화 (한국어)
  await initializeDateFormatting('ko_KR', null);

  // 화면 방향 고정 (세로 모드)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 1. Hive 및 어댑터 초기화
  await DatabaseService.init();

  // 2. 초기 데이터가 필요하다면 여기서 로드 (예: N1~N5)
  for (int i = 1; i <= 5; i++) {
    await DatabaseService.loadJsonToHive(i);
  }

  runApp(const MyApp());
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
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansTextTheme(
          Theme.of(context).textTheme,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: const HomePage(),
    );
  }
}
