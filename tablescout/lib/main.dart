import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
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
  static const double _navExpandedWidth = 270;
  static const double _navCollapsedWidth = 55;
  static const double _mobileBreakpoint = 600;

  int _selectedIndex = 0;

  bool _navOpen = true;
  bool _navInitialised = false;

  final GlobalKey _logoSectionKey = GlobalKey();

  double _logoSectionHeight = 0;

  final List<Widget> _pages = [
    const Center(child: Text('Dashboard')),
    const Center(child: Text('Floor Allocator')),
    const Center(child: Text('Floor Designer')),
    const Center(child: Text('Events')),
    const Center(child: Text('Contact Us')),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_navInitialised) {
      final bool isMobile =
          MediaQuery.sizeOf(context).width < _mobileBreakpoint;

      // starts open on desktop
      //starts closed on mobile
      _navOpen = !isMobile;

      _navInitialised = true;
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureLogoSection();
    });
  }

  void _measureLogoSection() {
    final context = _logoSectionKey.currentContext;

    if (context == null) {
      return;
    }

    final RenderBox? box =
        context.findRenderObject() as RenderBox?;

    if (box == null) {
      return;
    }

    final double newHeight = box.size.height;

    if (newHeight != _logoSectionHeight) {
      setState(() {
        _logoSectionHeight = newHeight;
      });
    }
  }

  void _toggleNav() {
    setState(() {
      _navOpen = !_navOpen;
    });

    if (_navOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _measureLogoSection();
      });
    }
  }

  void _closeNav() {
    if (_navOpen) {
      setState(() {
        _navOpen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile =
        MediaQuery.sizeOf(context).width < _mobileBreakpoint;

    return Scaffold(
      body: isMobile
          ? _buildMobileLayout()
          : _buildDesktopLayout(),
    );
  }

//desktop specific

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        _buildNavBar(),

        Expanded(
          child: _buildPageContent(),
        ),
      ],
    );
  }

//mobile specific

  Widget _buildMobileLayout() {
    return Stack(
      children: [
        // page content uses full screen
        Positioned.fill(
          child: _buildPageContent(),
        ),

        //hidden logos so that maths can be done fo rthe hamburger
        Positioned(
          left: -_navExpandedWidth,
          top: 0,
          width: _navExpandedWidth,
          child: _buildLogoSection(
            key: _logoSectionKey,
          ),
        ),

        // tap outside nav to close when nav open
        if (_navOpen)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeNav,
              child: Container(
                color: Colors.black.withValues(
                  alpha: 0.25,
                ),
              ),
            ),
          ),

        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          child: _buildNavBar(),
        ),
      ],
    );
  }

// nav bar

  Widget _buildNavBar() {
    return Container(
      width: _navOpen
          ? _navExpandedWidth
          : _navCollapsedWidth,
      color: const Color.fromARGB(255, 167, 167, 179),
      child: Column(
        children: [
          // logo section
          if (_navOpen)
            _buildLogoSection(
              key: _logoSectionKey,
            )
          else
            SizedBox(
              height: _logoSectionHeight,
            ),

          // hamburbur
          SizedBox(
            height: 40,
            child: Align(
              alignment: _navOpen
                  ? Alignment.centerRight
                  : Alignment.center,
              child: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: _toggleNav,
              ),
            ),
          ),

          // nav items
          if (_navOpen) ...[
            _buildNavItem(
              index: 0,
              icon: Icons.home,
              label: 'Dashboard',
            ),
            _buildNavItem(
              index: 1,
              icon: Icons.home,
              label: 'Floor Allocator',
            ),
            _buildNavItem(
              index: 2,
              icon: Icons.home,
              label: 'Floor Designer',
            ),
            _buildNavItem(
              index: 3,
              icon: Icons.home,
              label: 'Events',
            ),
            _buildNavItem(
              index: 4,
              icon: Icons.home,
              label: 'Contact Us',
            ),
          ],

          const Spacer(),

          // bottom bar
          if (_navOpen)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 124, 127, 137),
                border: Border(
                  top: BorderSide(
                    color: Colors.black26,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        // CHANGE THIS TO USERNAME
                        'Account',
                        style: TextStyle(
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.settings,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

//logos

  Widget _buildLogoSection({
    Key? key,
  }) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        // TableScout logo
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: 30,
            horizontal: 16,
          ),
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.black54,
              ),
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

        // store logo
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: 30,
            horizontal: 16,
          ),
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.black54,
              ),
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
      ],
    );
  }

  // nav items

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

//page content

  Widget _buildPageContent() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: _pages[_selectedIndex],
    );
  }
}