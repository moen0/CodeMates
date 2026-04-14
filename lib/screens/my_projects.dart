import 'package:flutter/material.dart';
import 'package:devconnect/widgets/brutalist_ui.dart';

class MyProjectsScreen extends StatelessWidget {
  const MyProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BrutalistScaffold(
      appBar: BrutalistHeader(title: 'Mine prosjekter'),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: BrutalistPanel(
            padding: EdgeInsets.all(16),
            child: Center(child: Text('Ingen egne prosjekter enda')),
          ),
        ),
      ),
    );
  }
}
