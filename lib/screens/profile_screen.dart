import 'package:flutter/material.dart';
import 'package:devconnect/widgets/brutalist_ui.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BrutalistScaffold(
      appBar: BrutalistHeader(title: 'Profil'),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: BrutalistPanel(
            padding: EdgeInsets.all(16),
            child: Center(child: Text('Min profil')),
          ),
        ),
      ),
    );
  }
}
