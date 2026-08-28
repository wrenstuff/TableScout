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
  bool _navOpen = true;

  final List<Widget> _pages = [
    const Center(child: Text('Home')),
    const Center(child: Text('Home')),
    const Center(child: Text('Home')),
    const Center(child: Text('Home')),
    const Center(child: Text('Home')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: _navOpen ? 270 : 55,
            color: Colors.grey[300],
            child: Column(
              children: [
                // TableScout logo area
                if (_navOpen)
                  Container(
                    height: 95,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.black54),
                      ),
                    ),
                    child: const Text(
                      'TableScout Logo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                // Store logo area
                if (_navOpen)
                  Container(
                    height: 95,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.black54),
                      ),
                    ),
                    child: const Text(
                      'Store Logo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                // Hamburger row
                SizedBox(
                  height: 40,
                  child: Align(
                    alignment:
                        _navOpen ? Alignment.centerRight : Alignment.center,
                    child: IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () {
                        setState(() {
                          _navOpen = !_navOpen;
                        });
                      },
                    ),
                  ),
                ),

                if (_navOpen) ...[
                  _buildNavItem(
                    index: 0,
                    icon: Icons.home,
                    label: 'Home',
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.home,
                    label: 'Home',
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.home,
                    label: 'Home',
                  ),
                  _buildNavItem(
                    index: 3,
                    icon: Icons.home,
                    label: 'Home',
                  ),
                  _buildNavItem(
                    index: 4,
                    icon: Icons.home,
                    label: 'Home',
                  ),
                ],

                // Push bottom controls down
                const Spacer(),

                if (_navOpen)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.black26),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {},
                            child: const Text('Account',
                              style: TextStyle(
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        IconButton(
                          tooltip: 'Settings',
                          onPressed: () {},
                          icon: const Icon(Icons.settings),
                        ),

                        IconButton(
                          tooltip: 'Logout',
                          onPressed: () {},
                          icon: const Icon(Icons.logout),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: _pages[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    return ListTile(
      selected: _selectedIndex == index,
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }
}