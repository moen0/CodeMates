import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:devconnect/widgets/brutalist_ui.dart';
import 'edit_profile_screen.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<Register> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool isLoading = false;

  bool get _isFormValid {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;
    final emailLooksValid = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);

    return emailLooksValid &&
        password.isNotEmpty &&
        confirmPassword.isNotEmpty &&
        password == confirmPassword;
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> signUp() async {
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passordene matcher ikke')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Konto opprettet!')));
        final currentUser = Supabase.instance.client.auth.currentUser ?? response.user;
        if (currentUser != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
          );
        } else {
          Navigator.pop(context);
        }
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
      appBar: const BrutalistHeader(title: 'Opprett bruker'),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BrutalistPanel(
                child: TextField(
                  controller: emailController,
                  onChanged: (_) => setState(() {}),
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
                  onChanged: (_) => setState(() {}),
                  obscureText: true,
                  decoration: brutalistInputDecoration(
                    labelText: 'Passord',
                  ).copyWith(prefixIcon: const Icon(Icons.lock)),
                ),
              ),
              const SizedBox(height: 16),
              BrutalistPanel(
                child: TextField(
                  controller: confirmPasswordController,
                  onChanged: (_) => setState(() {}),
                  obscureText: true,
                  decoration: brutalistInputDecoration(
                    labelText: 'Bekreft passord',
                  ).copyWith(prefixIcon: const Icon(Icons.lock_outline)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: brutalistPrimaryButtonStyle(),
                  onPressed: (isLoading || !_isFormValid) ? null : signUp,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Opprett bruker'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
