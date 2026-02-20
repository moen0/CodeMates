import 'package:flutter/material.dart';
import 'package:devconnect/screens/login.dart';


class Welcome extends StatelessWidget {
  const Welcome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(),

              Icon(Icons.code, size: 80, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),

              Text('CodeMates',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              Text('Finn medstudenter til prosjektene dine',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: naviger til registrering
                  },
                  child: const Text('Opprett bruker'),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
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