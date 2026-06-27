import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app.dart';
import '../home/home_screen.dart';
import '../converter/converter_screen.dart';
import '../settings/settings_screen.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const _screens = [
    HomeScreen(),
    ConverterScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = ref.watch(appTabIndexProvider);

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(tabIndex),
          child: _screens[tabIndex],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabIndex,
        onDestinationSelected: (i) =>
            ref.read(appTabIndexProvider.notifier).state = i,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline_rounded),
            selectedIcon: Icon(Icons.add_circle_rounded),
            label: 'Convert',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
