import 'package:devconnect/screens/welcome.dart';
import 'package:devconnect/screens/home_screen.dart';
import 'package:devconnect/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(const MyApp());
}

/// Sjekker om brukeren har en aktiv sesjon ved oppstart og ruter deretter.
/// Supabase lagrer sesjonen lokalt på enheten, så innloggede brukere
/// sendes direkte til HomeScreen uten å måtte logge inn på nytt.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return StreamBuilder<AuthState>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF000000),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (authService.isLoggedIn) {
          return const HomeScreen();
        }
        return const Welcome();
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      colorSchemeSeed: Colors.deepPurple,
      useMaterial3: true,
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'DevConnect',
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        scaffoldBackgroundColor: const Color(0xFF000000),
        textTheme: GoogleFonts.spaceMonoTextTheme(baseTheme.textTheme),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF000000)),
        cardTheme: const CardThemeData(
          color: Color(0xFF111111),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: Color(0xFF333333)),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.zero),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: Color(0xFF333333)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: Color(0xFF6366F1), width: 1.5),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}