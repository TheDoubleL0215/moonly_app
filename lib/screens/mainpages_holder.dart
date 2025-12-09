import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonly/l10n/app_localizations.dart';
import 'package:moonly/screens/calendar_screen.dart';
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
    final loc = AppLocalizations.of(context);
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
          items: [
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.houseHeart),
              label: loc!.appbar_mainpageText,
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.calendar),
              label: loc.appbar_calendarText,
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.bookMarked),
              label: loc.appbar_knowledgeText,
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.user),
              label: loc.appbar_profile,
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
        return const CalendarScreen();
      case 2:
        return const Center(child: Text('Tudástár'));
      case 3:
        return const ProfileScreen();
      default:
        return const Center(child: Text('Főoldal'));
    }
  }
}
