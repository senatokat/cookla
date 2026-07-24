import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/constants.dart';

class BottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          HapticFeedback.lightImpact();
          onTap(index);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: kPrimary,
        unselectedItemColor: kHint,
        backgroundColor: kCard,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: [
          BottomNavigationBarItem(
            icon: Icon(currentIndex == 0 ? Icons.home : Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(currentIndex == 1 ? Icons.event : Icons.event_outlined),
            label: 'Workshop',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              currentIndex == 2
                  ? Icons.restaurant_menu
                  : Icons.restaurant_menu_outlined,
            ),
            label: 'Tarifler',
          ),
          BottomNavigationBarItem(
            icon: Icon(currentIndex == 3 ? Icons.people : Icons.people_outline),
            label: 'Şefler',
          ),
          BottomNavigationBarItem(
            icon: Icon(currentIndex == 4 ? Icons.person : Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
