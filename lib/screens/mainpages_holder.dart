import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonly/screens/overview_screen.dart';
import 'package:moonly/screens/profile_screen.dart';

class MainPagesHolder extends StatefulWidget {
  const MainPagesHolder({super.key});

  @override
  State<MainPagesHolder> createState() => _MainPagesHolderState();
}

class _MainPagesHolderState extends State<MainPagesHolder> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getCurrentPage(),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.houseHeart),
              label: 'Főoldal',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.calendar),
              label: 'Naptár',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.bookMarked),
              label: 'Tudástár',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.user),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }

  Widget _getCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return const OverviewScreen();
      case 1:
        return const Center(child: Text('Naptár'));
      case 2:
        return const Center(child: Text('Tudástár'));
      case 3:
        return const ProfileScreen();
      default:
        return const Center(child: Text('Főoldal'));
    }
  }
}
