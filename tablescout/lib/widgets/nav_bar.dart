import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tablescout/session/session_manager.dart';
import 'package:tablescout/pages/settings_page.dart';
import 'package:tablescout/pages/dashboard_page.dart';
import 'package:tablescout/pages/floor_planner_page.dart';
import 'package:tablescout/pages/events_page.dart';

import 'package:tablescout/pages/account_page.dart';
import 'package:tablescout/pages/staff_manage.dart';
import 'package:tablescout/pages/privacy_page.dart';
import 'package:tablescout/pages/password_manage_page.dart';
import 'package:tablescout/pages/cloud_page.dart';
import 'package:tablescout/pages/customise_page.dart';
import 'package:tablescout/pages/notifications_page.dart';
import 'package:tablescout/screen_dimensions.dart';
import 'package:tablescout/pages/contact_us_page.dart';

final GlobalKey _visibleLogoSectionKey = GlobalKey();

class NavBar extends StatefulWidget {
  const NavBar({super.key});

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  static const double _navExpandedWidth = 270;
  static const double _navCollapsedWidth = 55;

  int _selectedIndex = 0;

  bool _navOpen = true;
  bool _navInitialised = false;

  final GlobalKey _logoSectionKey = GlobalKey();

  final GlobalKey<FloorPlannerState> _floorPlannerKey =
    GlobalKey<FloorPlannerState>();

  double _logoSectionHeight = 0;

  late final List<Widget> _pages = [
    DashboardPage(
      onNavigateToFloorAllocator: () => _navigateTo(1),
    ),
    const Center(child: Text('Floor Allocator')),
    FloorPlanner(key: _floorPlannerKey),
    EventsOverviewPage(),
    ContactUsPage(),
    //AccountPage(),
    SettingsPage(onNavigate: (index) {
      _navigateTo(index);
    },
  ),
    
    AccountPage(
      onNavigateToPassword: () {
        _navigateTo(9);
      },
    ),
    const StaffManagementPage(),
    const PrivacyPage(),
    const PasswordManagementPage(),
    const CloudPage(),
    const CustomisePage(),
    const NotificationsPage(),


  
  ];

  Future<void> _navigateTo(int index) async {
    // If we're already on the selected page, do nothing.
    if (index == _selectedIndex) return;

    // Check whether we're leaving the Floor Planner.
    if (_selectedIndex == 2) {
      final floorPlanner = _floorPlannerKey.currentState;

      if (floorPlanner != null && floorPlanner.hasUnsavedChanges) {
        final choice = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: const Text('Unsaved Changes'),
              content: const Text(
                'You have made changes to your floor plan. '
                'Would you like to save before leaving?',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, 'cancel');
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, 'discard');
                  },
                  child: const Text('Discard'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, 'save');
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );

        // Cancel: stay on the Floor Planner.
        if (choice == 'cancel' || choice == null) return;

        // Save: save the floor plan before leaving.
        if (choice == 'save') {
          await floorPlanner.saveLayout();

          if (floorPlanner.hasUnsavedChanges) {
            return;
          }
        }
        
        // Discard: continue navigating without saving.
      }
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_navInitialised) {

      // starts open on desktop
      //starts closed on mobile
      _navOpen = !ScreenDimensions.isMobile(context);

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
    if (!mounted) return;

    final BuildContext? logoContext = _navOpen
        ? _visibleLogoSectionKey.currentContext
        : _logoSectionKey.currentContext;

    final renderObject = logoContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;

    final newHeight = renderObject.size.height;

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

  void _signOut() {
    context.read<SessionManager>().logout();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: ScreenDimensions.isMobile(context)
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
    final sessionManager = context.watch<SessionManager>();

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
              key: _visibleLogoSectionKey,
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
                      onPressed: () {
                        final accountIndex = _pages.indexWhere(
                          (page) => page is AccountPage,
                        );

                        if (accountIndex == -1) {
                          debugPrint('AccountPage not found in _pages');
                        }
                        setState(() {
                          _selectedIndex = accountIndex;
                        });
                      },
                      child: Text(
                        sessionManager.username?.isNotEmpty == true
                          ? sessionManager.username!
                          : 'Account',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 4),

                  IconButton(
                    tooltip: 'Settings',
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 5;
                      });
                    },
                    icon: const Icon(
                      Icons.settings,
                      color: Colors.black87,
                    ),
                  ),

                  IconButton(
                    tooltip: 'Sign out',
                    onPressed: _signOut,
                    icon: const Icon(
                      Icons.logout,
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
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        selected: _selectedIndex == index,
        leading: Icon(icon),
        title: Text(label),
        onTap: () {
          _navigateTo(index);
        },
      )
    );
  }

//page content

  Widget _buildPageContent() {
    return Container(
      color: Colors.white,
      child: _pages[_selectedIndex],
    );
  }
}