import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/movie.dart';
import 'screens/home_screen.dart';
import 'screens/detail_screen.dart';
import 'constants/app_colors.dart';

// =========================================================
// Entrypoint utama dan konfigurasi navigasi aplikasi
// =========================================================
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NfilmApp());
}

class NfilmApp extends StatelessWidget {
  const NfilmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nfilm PRO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          primary: AppColors.primary,
          surface: AppColors.surface,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background, 
          elevation: 0,
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/detail') {
          return MaterialPageRoute(
            builder: (_) => DetailScreen(movie: settings.arguments as Movie),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );
      },
    );
  }
}