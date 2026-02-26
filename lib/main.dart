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
        
        // 배경 테마 색상 결정 (canvasColor 용)
        Color themeBgColor;
        if (isDarkMode) {
          themeBgColor = const Color(0xFF1A1C2C);
        } else {
          int month = DateTime.now().month;
          String target = appTheme;
          if (target == 'auto') {
            if (month >= 3 && month <= 5) target = 'spring';
            else if (month >= 6 && month <= 8) target = 'summer';
            else if (month >= 9 && month <= 11) target = 'autumn';
            else target = 'winter';
          }
          if (target == 'spring') themeBgColor = const Color(0xFFFFF0F5);
          else if (target == 'summer') themeBgColor = const Color(0xFFE0F7FA);
          else if (target == 'autumn') themeBgColor = const Color(0xFFFFF3E0);
          else themeBgColor = const Color(0xFFF1F4F8);
        }

        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
        ));

        return MaterialApp(
          title: 'JLPT 단어장',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF5B86E5),
              brightness: isDarkMode ? Brightness.dark : Brightness.light,
              surface: Colors.transparent,
            ),
            textTheme: GoogleFonts.notoSansTextTheme(
              isDarkMode ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
            ).apply(
              bodyColor: isDarkMode ? Colors.white : Colors.black87,
              displayColor: isDarkMode ? Colors.white : Colors.black87,
            ),
            scaffoldBackgroundColor: Colors.transparent,
            canvasColor: themeBgColor, // 제스처 중 배경이 튀지 않도록 테마색과 일치
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              surfaceTintColor: Colors.transparent,
              iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.black87),
              titleTextStyle: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            cardTheme: CardThemeData(
              color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.9),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            pageTransitionsTheme: const PageTransitionsTheme(builders: {
              TargetPlatform.android: CupertinoPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            }),
          ),
          builder: (context, child) {
            return SeasonalBackground(
              isDarkMode: isDarkMode,
              appTheme: appTheme,
              child: Material(
                color: Colors.transparent,
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
