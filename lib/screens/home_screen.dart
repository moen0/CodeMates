import 'package:flutter/material.dart';
import 'feed_screen.dart';
import 'my_projects.dart';
import 'application_screen.dart';
import 'profile_screen.dart';
import 'package:devconnect/widgets/brutalist_ui.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      FeedScreen(
        onOpenProfileTab: () {
          setState(() {
            currentIndex = 3;
          });
        },
      ),
      const MyProjectsScreen(),
      const ApplicationsScreen(),
      const ProfileScreen(),
    ];

    // PopScope hindrer tilbake-knappen fra å forlate hovedskjermen
    return PopScope(
      canPop: false,
      child: BrutalistScaffold(
      // Bunnnavigasjonen
      bottomNavigationBar: NavigationBar(
        backgroundColor: BrutalistPalette.panel,
        indicatorColor: BrutalistPalette.accent.withValues(alpha: 0.25),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? Colors.white : BrutalistPalette.muted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          // setState trigger rebuild med ny fane
          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.explore), label: 'Utforsk'),
          NavigationDestination(
            icon: Icon(Icons.folder),
            label: 'Mine prosjekter',
          ),
          NavigationDestination(icon: Icon(Icons.mail), label: 'Søknader'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
      child: IndexedStack(index: currentIndex, children: screens),
      ),
    );
  }
}
