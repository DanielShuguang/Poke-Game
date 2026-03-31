import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poke_game/core/router/app_router.dart';
import 'package:poke_game/presentation/pages/settings/settings_provider.dart';
import 'package:poke_game/presentation/shared/game_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    // 根据设置选择主题模式
    ThemeMode themeMode;
    switch (settings.themeMode) {
      case ThemeModeSetting.system:
        themeMode = ThemeMode.system;
      case ThemeModeSetting.light:
        themeMode = ThemeMode.light;
      case ThemeModeSetting.dark:
        themeMode = ThemeMode.dark;
    }

    return MaterialApp.router(
      title: '扑克游戏合集',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4ADE80),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansScTextTheme(ThemeData.light().textTheme),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        extensions: const [GameColors.light],
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4ADE80),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansScTextTheme(ThemeData.dark().textTheme),
        extensions: const [GameColors.dark],
      ),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
