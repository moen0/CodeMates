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
  int _profileRefreshToken = 0;

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
            _profileRefreshToken++;
          });
        },
      ),
      const MyProjectsScreen(),
      const ApplicationsScreen(),
      ProfileScreen(refreshToken: _profileRefreshToken),
    ];

    // PopScope hindrer tilbake-knappen fra å forlate hovedskjermen
    return PopScope(
      canPop: false,
      child: BrutalistScaffold(
      // Bunnnavigasjonen
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: BrutalistPalette.panel,
        selectedItemColor: Colors.white,
        unselectedItemColor: BrutalistPalette.muted,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
            if (index == 3) {
              _profileRefreshToken++;
            }
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore, size: 24), label: 'Utforsk'),
          BottomNavigationBarItem(icon: Icon(Icons.terminal, size: 24), label: 'Mine prosjekter'),
          BottomNavigationBarItem(icon: Icon(Icons.mail, size: 24), label: 'Søknader'),
          BottomNavigationBarItem(icon: Icon(Icons.person, size: 24), label: 'Profil'),
        ],
      ),
      child: IndexedStack(index: currentIndex, children: screens),
      ),
    );
  }
}
