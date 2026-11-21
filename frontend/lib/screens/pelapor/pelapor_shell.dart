import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'akun_tab.dart';
import 'beranda_tab.dart';
import 'lacak_tab.dart';
import 'lapor_tab.dart';
import 'panduan_tab.dart';

class PelaporShell extends StatefulWidget {
  final bool guest;
  const PelaporShell({super.key, this.guest = false});
  @override
  State<PelaporShell> createState() => _PelaporShellState();
}

class _PelaporShellState extends State<PelaporShell> {
  int _i = 0;

  void go(int i) => setState(() => _i = i);

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      BerandaTab(guest: widget.guest, onGo: go),
      LaporTab(guest: widget.guest, onGo: go),
      LacakTab(guest: widget.guest),
      const PanduanTab(),
      AkunTab(guest: widget.guest),
    ];
    return PopScope(
      canPop: _i == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) go(0);
      },
      child: Scaffold(
        body: IndexedStack(index: _i, children: tabs),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _i,
          onDestinationSelected: go,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded, color: C.purple), label: 'Beranda'),
            NavigationDestination(icon: Icon(Icons.add_circle_outline_rounded), selectedIcon: Icon(Icons.add_circle_rounded, color: C.purple), label: 'Lapor'),
            NavigationDestination(icon: Icon(Icons.manage_search_rounded), selectedIcon: Icon(Icons.manage_search_rounded, color: C.purple), label: 'Lacak'),
            NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book_rounded, color: C.purple), label: 'Panduan'),
            NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded, color: C.purple), label: 'Akun'),
          ],
        ),
      ),
    );
  }
}
