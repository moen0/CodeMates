import 'package:devconnect/screens/welcome.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://albicrewixbvnkzuslpb.supabase.co',
    anonKey: 'sb_publishable_pFKNfr9QFqbXotSjE96YvQ_AkBPjKeP',
  );
  runApp(const MyApp());
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
      home: const Welcome(),
    );
  }
}
