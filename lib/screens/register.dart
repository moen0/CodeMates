import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:devconnect/widgets/brutalist_ui.dart';
import 'package:devconnect/screens/edit_profile_screen.dart';
import 'package:devconnect/screens/login.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<Register> {
  final _formKey = GlobalKey<FormState>();
  final displayNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    displayNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    final displayNameLength = displayNameController.text.trim().length;
    return displayNameLength >= 2 &&
        displayNameLength <= 50 &&
        _isValidEmail(emailController.text.trim()) &&
        passwordController.text.length >= 8 &&
        confirmPasswordController.text == passwordController.text;
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  Future<void> signUp() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    final email = emailController.text.trim();
    final displayName = displayNameController.text.trim();

    try {
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: email,
        password: passwordController.text,
      );

      final session =
          authResponse.session ?? Supabase.instance.client.auth.currentSession;
      if (session == null) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sjekk eposten din for å bekrefte kontoen'),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Login()),
        );
        return;
      }

      final userId = authResponse.user?.id ?? Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw const AuthException(
          'Konto opprettet, men fant ikke bruker-id. Prøv å logge inn igjen.',
        );
      }

      await Supabase.instance.client.from('profiles').upsert({
        'id': userId,
        'display_name': displayName,
        'email': email,
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Konto opprettet!')));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const EditProfileScreen()),
      );
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kunne ikke oppdatere profil: ${e.message}')),
        );
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
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                BrutalistPanel(
                  child: TextFormField(
                    controller: displayNameController,
                    maxLength: 50,
                    onChanged: (_) => setState(() {}),
                    decoration: brutalistInputDecoration(
                      labelText: 'Visningsnavn',
                      hintText: 'Hvordan skal navnet ditt vises?',
                    ).copyWith(
                      prefixIcon: const Icon(Icons.person),
                      counterText: '',
                    ),
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.isEmpty) {
                        return 'Visningsnavn er påkrevd';
                      }
                      if (trimmed.length < 2) {
                        return 'Minst 2 tegn';
                      }
                      if (trimmed.length > 50) {
                        return 'Maks 50 tegn';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                BrutalistPanel(
                  child: TextFormField(
                    controller: emailController,
                    onChanged: (_) => setState(() {}),
                    decoration: brutalistInputDecoration(
                      labelText: 'E-post',
                      hintText: 'epost@eksempel.no',
                    ).copyWith(prefixIcon: const Icon(Icons.email)),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      final email = (value ?? '').trim();
                      if (email.isEmpty) {
                        return 'Epost er påkrevd';
                      }
                      if (!_isValidEmail(email)) {
                        return 'Ugyldig epostadresse';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                BrutalistPanel(
                  child: TextFormField(
                    controller: passwordController,
                    onChanged: (_) => setState(() {}),
                    obscureText: true,
                    decoration: brutalistInputDecoration(
                      labelText: 'Passord',
                    ).copyWith(prefixIcon: const Icon(Icons.lock)),
                    validator: (value) {
                      final password = value ?? '';
                      if (password.isEmpty) {
                        return 'Passord er påkrevd';
                      }
                      if (password.length < 8) {
                        return 'Minst 8 tegn';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                BrutalistPanel(
                  child: TextFormField(
                    controller: confirmPasswordController,
                    onChanged: (_) => setState(() {}),
                    obscureText: true,
                    decoration: brutalistInputDecoration(
                      labelText: 'Bekreft passord',
                    ).copyWith(prefixIcon: const Icon(Icons.lock_outline)),
                    validator: (value) {
                      final confirmed = value ?? '';
                      if (confirmed.isEmpty) {
                        return 'Bekreft passordet ditt';
                      }
                      if (confirmed != passwordController.text) {
                        return 'Passordene er ikke like';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: brutalistPrimaryButtonStyle(),
                    onPressed: isLoading || !_isFormValid ? null : signUp,
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
      ),
    );
  }
}
