import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: NavBar(),
    );
  }
}

class NavBar extends StatefulWidget {
  const NavBar({super.key});

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const Center(child: Text('Home Page')),
    const Center(child: Text('Settings Page')),
  ];

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TableScout'),
        automaticallyImplyLeading: !isDesktop,
      ),

      drawer: isDesktop
          ? null
          : Drawer(
              child: _buildDrawerItems(context, isDesktop),
            ),

      body: Row(
        children: [
          if (isDesktop)
            Container(
              width: 200,
              color: Colors.grey[200],
              child: _buildDrawerItems(context, isDesktop),
            ),

          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: _pages[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItems(BuildContext context, bool isDesktop) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const DrawerHeader(
          decoration: BoxDecoration(color: Colors.blue),
          child: Text(
            'TableScout',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
            ),
          ),
        ),

        ListTile(
          selected: _selectedIndex == 0,
          leading: const Icon(Icons.home),
          title: const Text('Home'),
          onTap: () {
            setState(() => _selectedIndex = 0);

            if (!isDesktop) {
              Navigator.pop(context);
            }
          },
        ),

        ListTile(
          selected: _selectedIndex == 1,
          leading: const Icon(Icons.settings),
          title: const Text('Settings'),
          onTap: () {
            setState(() => _selectedIndex = 1);

            if (!isDesktop) {
              Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }
}