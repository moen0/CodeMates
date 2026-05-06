import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';
import 'package:devconnect/widgets/brutalist_ui.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<Login> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> signIn() async {
    setState(() {
      isLoading = true;
    });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      if (mounted) {
        // Tøm hele navigasjonsstakken så tilbake-knappen ikke tar brukeren til innloggingsskjermen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BrutalistScaffold(
      appBar: const BrutalistHeader(title: 'Logg inn'),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BrutalistPanel(
                child: TextField(
                  controller: emailController,
                  decoration: brutalistInputDecoration(
                    labelText: 'E-post',
                    hintText: 'epost@eksempel.no',
                  ).copyWith(prefixIcon: const Icon(Icons.email)),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              const SizedBox(height: 16),
              BrutalistPanel(
                child: TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: brutalistInputDecoration(
                    labelText: 'Passord',
                  ).copyWith(prefixIcon: const Icon(Icons.lock)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: brutalistPrimaryButtonStyle(),
                  onPressed: isLoading ? null : signIn,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Logg inn'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
