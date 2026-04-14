import 'package:flutter/material.dart';
import 'package:devconnect/screens/login.dart';
import 'package:devconnect/screens/register.dart';
import 'package:devconnect/widgets/brutalist_ui.dart';
import 'package:google_fonts/google_fonts.dart';

class Welcome extends StatelessWidget {
  const Welcome({super.key});

  @override
  Widget build(BuildContext context) {
    return BrutalistScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(),

              Icon(Icons.code, size: 84, color: BrutalistPalette.accent),
              const SizedBox(height: 16),

              Text(
                'CodeMates',
                style: GoogleFonts.spaceMono(
                  fontSize: 34,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'Finn medstudenter til prosjektene dine',
                style: GoogleFonts.spaceMono(
                  fontSize: 14,
                  color: BrutalistPalette.muted,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: brutalistPrimaryButtonStyle(),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const Register()),
                    );
                  },
                  child: const Text('Opprett bruker'),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: brutalistOutlineButtonStyle(),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const Login()),
                    );
                  },
                  child: const Text('Logg inn'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
