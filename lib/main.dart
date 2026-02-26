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

// 느리고 부드러운 페이드 전환을 위한 커스텀 빌더
class SmoothFadeTransitionsBuilder extends PageTransitionsBuilder {
  const SmoothFadeTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // 0.5초 동안 부드럽게 나타나도록 커브와 함께 적용
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut, // 시작과 끝이 부드러운 효과
      ),
      child: child,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionBox = Hive.box(DatabaseService.sessionBoxName);

    return MaterialApp(
      title: 'JLPT 단어장',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF5B86E5)),
      builder: (context, child) {
        return ValueListenableBuilder<Box>(
          valueListenable: sessionBox.listenable(keys: ['dark_mode', 'app_theme']),
          builder: (context, box, _) {
            final bool isDarkMode = box.get('dark_mode', defaultValue: false);
            final String appTheme = box.get('app_theme', defaultValue: 'auto');

            return Theme(
              data: ThemeData(
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
                canvasColor: Colors.transparent,
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  centerTitle: true,
                  surfaceTintColor: Colors.transparent,
                ),
                // 전역 페이지 전환 속도 최적화 (안드로이드/iOS 모두 부드러운 페이드 적용)
                pageTransitionsTheme: const PageTransitionsTheme(builders: {
                  TargetPlatform.android: SmoothFadeTransitionsBuilder(),
                  TargetPlatform.iOS: SmoothFadeTransitionsBuilder(),
                }),
              ),
              child: SeasonalBackground(
                isDarkMode: isDarkMode,
                appTheme: appTheme,
                child: RepaintBoundary(
                  child: Material(
                    color: Colors.transparent,
                    child: child!,
                  ),
                ),
              ),
            );
          },
        );
      },
      home: const HomePage(),
    );
  }
}
